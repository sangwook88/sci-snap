import base64
import io
import json
import os
import sys
from pathlib import Path

from openai import OpenAI

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from RAG.query import hybrid_search

_openai_client = None


def _get_openai() -> OpenAI:
    global _openai_client
    if _openai_client is None:
        _openai_client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    return _openai_client


def _to_image_url(image_url: str) -> str:
    """로컬 파일이면 base64 data URL로 변환."""
    if image_url.startswith("data:") or image_url.startswith(("http://", "https://")):
        return image_url
    with open(image_url, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()
    suffix = Path(image_url).suffix.lstrip(".") or "jpeg"
    return f"data:image/{suffix};base64,{b64}"


def _get_image_size(image_url: str) -> tuple[int, int]:
    from PIL import Image
    if image_url.startswith("data:"):
        _, b64data = image_url.split(",", 1)
        img = Image.open(io.BytesIO(base64.b64decode(b64data)))
    elif image_url.startswith(("http://", "https://")):
        import urllib.request
        with urllib.request.urlopen(image_url) as resp:
            img = Image.open(io.BytesIO(resp.read()))
    else:
        img = Image.open(image_url)
    return img.size


def _rag_context(labels: list[str]) -> str:
    """탐지된 사물 레이블로 교과서 검색."""
    if not labels:
        return ""
    analysis = {
        "search_keywords_ko": labels,
        "search_keywords_en": labels,
        "science_concepts": [],
    }
    results = hybrid_search(analysis, match_count=4)
    return "\n---\n".join(r["content"] for r in results) if results else ""


CHILD_DETECT_SYSTEM = """당신은 초등학교 과학 교육 전문가입니다.
사진에서 초등학생(3~6학년)이 배울 수 있는 과학 현상을 찾아 쉬운 말로 설명합니다.
- 어려운 용어는 쉬운 비유로 풀어 설명
- 교과서에 나오는 개념 위주로 선택"""

DEFAULT_DETECT_SYSTEM = "당신은 과학 교육 전문가입니다. 이미지에서 과학 현상을 분석합니다."

_PHENOMENA_PROMPT = """이 이미지에서 관찰할 수 있는 과학 현상을 분석해주세요.

탐지된 사물: {objects}
{rag_section}
규칙:
- 이미지 크기: 가로 {width}px × 세로 {height}px (좌측 상단 원점(0,0), 우측 하단({width},{height}))
- 같은 현상이 여러 곳에 있으면 가장 대표적인 위치 하나만 선택하세요.
- 현상의 대표 위치를 픽셀 단위 정수 x, y로 반환하세요.
- 현상 이름은 초등학생이 이해할 수 있는 한국어로 작성하세요.

반드시 아래 JSON 형식으로만 반환하세요:
{{
  "phenomena": [
    {{"name": "현상 이름", "x": 300, "y": 200}}
  ]
}}"""


def analyze(
    image_url: str,
    objects: list[list],
    mode: str = "child_detect",
) -> dict:
    """
    GPT-4o Vision으로 과학 현상 분석.

    Args:
        image_url: 이미지 URL 또는 로컬 경로
        objects: detect()가 반환한 [["name", x, y], ...] 목록
        mode: "detect" | "child_detect"

    Returns:
        {"detect": [["이름", [x, y]], ...]}
    """
    labels = [obj[0] for obj in objects]
    rag_context = _rag_context(labels) if mode == "child_detect" else ""
    system_prompt = CHILD_DETECT_SYSTEM if mode == "child_detect" else DEFAULT_DETECT_SYSTEM

    try:
        img_w, img_h = _get_image_size(image_url)
    except Exception:
        img_w, img_h = 1000, 1000

    rag_section = f"\n관련 교과서 내용:\n{rag_context}\n" if rag_context else ""
    prompt = _PHENOMENA_PROMPT.format(
        objects=", ".join(labels) if labels else "없음",
        rag_section=rag_section,
        width=img_w,
        height=img_h,
    )

    url = _to_image_url(image_url)
    resp = _get_openai().chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": [
                {"type": "image_url", "image_url": {"url": url}},
                {"type": "text", "text": prompt},
            ]},
        ],
        response_format={"type": "json_object"},
        max_tokens=800,
    )

    try:
        result = json.loads(resp.choices[0].message.content)
    except json.JSONDecodeError:
        result = {"phenomena": []}

    detect_out = [[obj[0], [obj[1], obj[2]]] for obj in objects]

    for p in result.get("phenomena", []):
        x = p.get("x")
        y = p.get("y")
        if isinstance(x, (int, float)) and isinstance(y, (int, float)):
            detect_out.append([p["name"], [int(x), int(y)]])

    return {"detect": detect_out}
