import os
from supabase import create_client

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
    """해당 conversation의 이전 질문 최대 10개 가져오기."""
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
