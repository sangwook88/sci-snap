"""
RAG 쿼리 파이프라인
사진 → Vision 분석 → 하이브리드 검색 → 어린이 눈높이 응답 생성
"""

import base64
import json
import os
import sys
from pathlib import Path

from openai import OpenAI

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from db.db import _get_supabase

# ── 클라이언트 ──────────────────────────────────────────────

_openai_client = None
_gemini_client = None


def _get_openai():
    global _openai_client
    if _openai_client is None:
        _openai_client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    return _openai_client


def _get_gemini():
    global _gemini_client
    if _gemini_client is None:
        _gemini_client = OpenAI(
            api_key=os.environ["GEMINI_API_KEY"],
            base_url=os.environ["GEMINI_BASE_URL"],
        )
    return _gemini_client


# ── Step 1: 사진 분석 ──────────────────────────────────────

PHOTO_ANALYSIS_PROMPT = """이 사진을 분석하여 다음을 JSON으로 반환해주세요:
{
  "objects": ["사진에 보이는 사물/현상 목록"],
  "science_concepts": ["관련 과학 개념"],
  "search_keywords_ko": ["한국어 검색 키워드 5개"],
  "search_keywords_en": ["영어 검색 키워드 5개"],
  "curiosity_hooks": ["어린이가 궁금해할 만한 질문 3개"]
}
반드시 유효한 JSON만 반환해주세요."""


def analyze_photo(image_urls: list[str], question: str = "") -> dict:
    """사진을 Vision으로 분석하여 키워드와 과학 개념 추출"""
    content = []
    prompt = PHOTO_ANALYSIS_PROMPT
    if question:
        prompt = f"사용자 질문: {question}\n\n{prompt}"
    content.append({"type": "text", "text": prompt})

    for url in image_urls:
        content.append({"type": "image_url", "image_url": {"url": url}})

    resp = _get_openai().chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": content}],
        response_format={"type": "json_object"},
        max_tokens=500,
    )

    try:
        return json.loads(resp.choices[0].message.content)
    except json.JSONDecodeError:
        # JSON 파싱 실패 시 텍스트에서 추출 시도
        text = resp.choices[0].message.content
        return {
            "objects": [],
            "science_concepts": [],
            "search_keywords_ko": [question] if question else [],
            "search_keywords_en": [],
            "curiosity_hooks": [],
            "raw_analysis": text,
        }


def analyze_text_only(question: str) -> dict:
    """텍스트만으로 과학 개념 분석"""
    resp = _get_openai().chat.completions.create(
        model="gpt-4o",
        messages=[{
            "role": "user",
            "content": f"""다음 질문을 분석하여 JSON으로 반환해주세요:
질문: {question}

{{
  "objects": ["질문에 언급된 사물/현상"],
  "science_concepts": ["관련 과학 개념"],
  "search_keywords_ko": ["한국어 검색 키워드 5개"],
  "search_keywords_en": ["영어 검색 키워드 5개"],
  "curiosity_hooks": ["어린이가 궁금해할 만한 질문 3개"]
}}
반드시 유효한 JSON만 반환해주세요.""",
        }],
        response_format={"type": "json_object"},
        max_tokens=500,
    )

    try:
        return json.loads(resp.choices[0].message.content)
    except json.JSONDecodeError:
        return {
            "objects": [],
            "science_concepts": [],
            "search_keywords_ko": [question],
            "search_keywords_en": [],
            "curiosity_hooks": [],
        }


# ── Step 2: 하이브리드 검색 ────────────────────────────────

def hybrid_search(analysis: dict, match_count: int = 5) -> list[dict]:
    """벡터 + 풀텍스트 하이브리드 검색"""
    keywords_ko = analysis.get("search_keywords_ko", [])
    keywords_en = analysis.get("search_keywords_en", [])
    concepts = analysis.get("science_concepts", [])

    query_text = " ".join(keywords_ko + keywords_en + concepts)
    if not query_text.strip():
        return []

    # 쿼리 임베딩 생성
    query_embedding = _get_openai().embeddings.create(
        model="text-embedding-3-large",
        input=query_text[:8000],
        dimensions=512,
    ).data[0].embedding

    sb = _get_supabase()
    if sb is None:
        return []

    try:
        results = sb.rpc("hybrid_search", {
            "query_embedding": query_embedding,
            "query_text": query_text,
            "match_count": match_count,
            "filter_metadata": {},
        }).execute()
        return results.data or []
    except Exception as e:
        print(f"검색 오류: {e}")
        return []


# ── Step 3: 어린이 눈높이 응답 생성 ────────────────────────

CHILD_SYSTEM_PROMPT = """당신은 어린이 과학 교육 전문가입니다.
사진에서 발견한 과학적 요소를 초등학생이 이해할 수 있게 설명합니다.

규칙:
1. "와! ~한 거 알아?" 같은 호기심 유발 어투 사용
2. 어려운 용어는 쉬운 비유로 설명
3. "직접 해볼 수 있는 실험" 하나를 반드시 포함
4. 한국/미국/유럽 교과서의 관점 차이가 있으면 재미있게 비교
5. 답변은 Markdown 형식으로 작성
6. 응답은 간결하되 핵심 내용은 빠짐없이 전달"""


def generate_child_response(
    question: str,
    image_urls: list[str],
    analysis: dict,
    search_results: list[dict],
    history: list[dict] = None,
) -> str:
    """교과서 기반 어린이 눈높이 과학 응답 생성"""

    # 검색 결과를 컨텍스트로 구성
    context_parts = []
    for r in search_results:
        part = f"[교과서 내용]: {r['content']}"
        if r.get("image_caption"):
            part += f"\n[이미지 설명]: {r['image_caption']}"
        meta = r.get("metadata", {})
        if meta.get("grade_level"):
            part += f"\n[학년]: {meta['grade_level']}학년"
        context_parts.append(part)

    context = "\n---\n".join(context_parts) if context_parts else "관련 교과서 내용을 찾지 못했습니다."

    # 대화 히스토리 구성
    messages = [{"role": "system", "content": CHILD_SYSTEM_PROMPT}]

    if history:
        for turn in history:
            user_content = turn["question"]
            if turn.get("image_urls"):
                user_content = [{"type": "text", "text": turn["question"]}]
                for url in turn["image_urls"]:
                    user_content.append({"type": "image_url", "image_url": {"url": url}})
            messages.append({"role": "user", "content": user_content})
            messages.append({"role": "assistant", "content": turn["answer"]})

    # 현재 질문 구성
    user_prompt = f"""사진 분석 결과:
- 인식된 사물: {', '.join(analysis.get('objects', []))}
- 과학 개념: {', '.join(analysis.get('science_concepts', []))}
- 호기심 질문: {', '.join(analysis.get('curiosity_hooks', []))}

관련 교과서 내용:
{context}

사용자 질문: {question if question else '이 사진에서 어떤 과학을 배울 수 있나요?'}

이 사진에서 어린이가 흥미를 가질 만한 과학 이야기를 해주세요. 내용을 다 설명하고, 요약 설명 단락을 뒤에 추가해주세요."""

    if image_urls:
        user_content = [{"type": "text", "text": user_prompt}]
        for url in image_urls:
            user_content.append({"type": "image_url", "image_url": {"url": url}})
        messages.append({"role": "user", "content": user_content})
    else:
        messages.append({"role": "user", "content": user_prompt})

    resp = _get_openai().chat.completions.create(
        model="gpt-4o",
        messages=messages,
    )
    return resp.choices[0].message.content


# ── 통합 파이프라인 ─────────────────────────────────────────

def query(
    question: str = "",
    image_urls: list[str] = None,
    history: list[dict] = None,
) -> dict:
    """
    RAG 쿼리 메인 함수

    Returns:
        {
            "answer": str,
            "curiosity_hooks": list[str],
            "curriculum_refs": list[dict],
        }
    """
    image_urls = image_urls or []

    # Step 1: 분석
    if image_urls:
        analysis = analyze_photo(image_urls, question)
    elif question:
        analysis = analyze_text_only(question)
    else:
        return {"answer": "사진이나 질문을 보내주세요!", "curiosity_hooks": [], "curriculum_refs": []}

    # Step 2: 하이브리드 검색
    search_results = hybrid_search(analysis)

    # Step 3: 응답 생성
    answer = generate_child_response(
        question=question,
        image_urls=image_urls,
        analysis=analysis,
        search_results=search_results,
        history=history,
    )

    # 교과서 참조 정보 구성
    curriculum_refs = []
    for r in search_results:
        meta = r.get("metadata", {})
        curriculum_refs.append({
            "source": f"{meta.get('curriculum', 'KR')}_초등{meta.get('grade_level', '?')}",
            "page": meta.get("source_page"),
            "similarity": r.get("similarity"),
        })

    return {
        "answer": answer,
        "curiosity_hooks": analysis.get("curiosity_hooks", []),
        "curriculum_refs": curriculum_refs,
    }
