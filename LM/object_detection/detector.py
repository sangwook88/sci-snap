import base64
import io
import json
import os
import sys
from pathlib import Path

from openai import OpenAI

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

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
    """이미지 (width, height) 반환."""
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


_DETECT_PROMPT = """이 이미지에서 보이는 사물들을 탐지해주세요.

규칙:
- 이미지 크기: 가로 {width}px × 세로 {height}px (좌측 상단 원점(0,0), 우측 하단({width},{height}))
- 같은 종류의 사물은 가장 대표적인 것 하나만 선택하세요.
- 각 사물의 중심 좌표(x, y)를 픽셀 단위 정수로 반환하세요.
- 사물 이름은 한국어로 작성하세요.

반드시 아래 JSON 형식으로만 반환하세요:
{{
  "objects": [
    {{"name": "사물 이름", "x": 300, "y": 200}}
  ]
}}"""


def detect(image_url: str) -> list[list]:
    """
    GPT-4o Vision으로 사물 탐지.

    Returns:
        [["사물 이름", x, y], ...]
    """
    try:
        img_w, img_h = _get_image_size(image_url)
    except Exception:
        img_w, img_h = 1000, 1000

    url = _to_image_url(image_url)
    resp = _get_openai().chat.completions.create(
        model="gpt-4o",
        messages=[{
            "role": "user",
            "content": [
                {"type": "image_url", "image_url": {"url": url}},
                {"type": "text", "text": _DETECT_PROMPT.format(width=img_w, height=img_h)},
            ],
        }],
        response_format={"type": "json_object"},
        max_tokens=500,
    )
    try:
        result = json.loads(resp.choices[0].message.content)
        return [
            [obj["name"], obj["x"], obj["y"]]
            for obj in result.get("objects", [])
        ]
    except (json.JSONDecodeError, KeyError):
        return []
