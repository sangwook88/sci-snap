import os
import json
from openai import OpenAI
from supabase import create_client

client = OpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
)

_supabase = None


def _get_supabase():
    global _supabase
    if _supabase is None and os.environ.get("SUPABASE_URL"):
        _supabase = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_KEY"])
    return _supabase


def upsert_conversation(conversation_id: str | None, user_id: str | None = None) -> str:
    """대화 id 없으면 생성, 있으면 updated_at 갱신."""
    sb = _get_supabase()
    if sb is None:
        raise RuntimeError("Supabase client not initialized")
    payload = {"updated_at": "now()"}
    if conversation_id:
        payload["id"] = conversation_id
    if user_id:
        payload["user_id"] = user_id
    res = sb.table("conversations").upsert(payload, on_conflict="id").execute()
    return res.data[0]["id"]


def fetch_history(conversation_id: str) -> list:
    """해당 conversation의 이전 turn 최대 10개 가져오기."""
    sb = _get_supabase()
    if sb is None or not conversation_id:
        return []
    res = (
        sb.table("analysis_requests")
        .select("question, image_urls, answer")
        .eq("conversation_id", conversation_id)
        .not_.is_("answer", "null")
        .order("created_at", desc=False)
        .limit(10)
        .execute()
    )
    return res.data or []


def insert_message(conversation_id: str, user_id: str | None, question: str, image_urls: list, answer: str):
    """질문 DB에 저장"""
    sb = _get_supabase()
    if sb is None:
        return
    payload = {
        "conversation_id": conversation_id,
        "question": question,
        "image_urls": image_urls or None,
        "answer": answer,
    }
    if user_id:
        payload["user_id"] = user_id
    sb.table("analysis_requests").insert(payload).execute()


def build_content(question: str, image_urls: list):
    """Gemini content 형식으로 변환."""
    if image_urls:
        content = [{"type": "image_url", "image_url": {"url": url}} for url in image_urls]
        if question:
            content.append({"type": "text", "text": question})
        return content
    return question


def lambda_handler(event, context):
    body = event.get("body", event)
    if isinstance(body, str):
        body = json.loads(body)

    question        = body.get("question", "")
    image_urls      = body.get("image_urls") or []
    conversation_id = body.get("conversation_id")
    user_id         = body.get("user_id")

    # 이미지나 질문 둘 다 없으면 에러
    if not question and not image_urls:
        return _response(400, {"error": "Question and image_urls are both empty"})

    conversation_id = upsert_conversation(conversation_id, user_id)

    # 과거 대화 내역과 이번 질문을 Gemini 형식에 맞게 변환
    history = fetch_history(conversation_id)
    messages = []
    for turn in history:
        messages.append({"role": "user",      "content": build_content(turn["question"], turn.get("image_urls") or [])})
        messages.append({"role": "assistant", "content": turn["answer"]})
    messages.append({"role": "user", "content": build_content(question, image_urls)})

    # 제미나이에게 질문
    try:
        completion = client.chat.completions.create(
            model="gemini-3-flash-preview",
            messages=messages
        )
        answer = completion.choices[0].message.content
        insert_message(conversation_id, user_id, question, image_urls, answer)
        return _response(200, {"answer": answer, "conversation_id": conversation_id})
    except Exception as e:
        return _response(500, {"error": str(e)})


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, ensure_ascii=False),
    }