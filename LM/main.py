import json
from db.db import upsert_conversation, fetch_history, insert_message
from llm.gemini import build_content
from RAG.query import query as rag_query, _get_openai
from object_detection.detector import detect
from object_detection.analyzer import analyze as detect_analyze


def lambda_handler(event, context):
    body = event.get("body", event)
    if isinstance(body, str):
        body = json.loads(body)

    question        = body.get("question") or ""
    image_urls      = body.get("image_urls") or []
    if isinstance(image_urls, str):
        image_urls = [image_urls] if image_urls else []
    conversation_id = body.get("conversation_id") or None
    user_id         = body.get("user_id") or None
    mode            = body.get("mode") or "default"

    # detect / child_detect: 사물 탐지 + 과학 현상 분석
    if mode in ("detect", "child_detect"):
        if not image_urls:
            return _response(400, {"error": "image_urls is required for detect mode"})
        try:
            image_url = image_urls[0]
            objects = detect(image_url)
            result = detect_analyze(image_url, objects, mode=mode)
            return _response(200, result)
        except Exception as e:
            return _response(500, {"error": str(e)})

    if not question and not image_urls:
        return _response(400, {"error": "Question and image_urls are both empty"})

    conversation_id = upsert_conversation(conversation_id, user_id)
    history = fetch_history(conversation_id)

    # child: 교과서 RAG 파이프라인
    if mode == "child":
        try:
            result = rag_query(
                question=question,
                image_urls=image_urls,
                history=history,
            )
            answer = result["answer"]
            insert_message(conversation_id, user_id, question, image_urls, answer)

            return _response(200, {
                "answer": answer,
                "image_urls": [],
                "conversation_id": conversation_id,
                "curiosity_hooks": result.get("curiosity_hooks", []),
                "curriculum_refs": result.get("curriculum_refs", []),
            })
        except Exception as e:
            return _response(500, {"error": str(e)})

    # default: Gemini 직접 호출
    messages = [
        {
            "role": "system",
            "content": "항상 한국어로 답변하세요. 답변은 Markdown 형식으로 작성하고, 제목·목록·강조 등 Markdown 문법을 적극 활용하세요.",
        }
    ]
    for turn in history:
        messages.append({"role": "user",      "content": build_content(turn["question"], turn.get("image_urls") or [])})
        messages.append({"role": "assistant", "content": turn["answer"]})
    messages.append({"role": "user", "content": build_content(question, image_urls)})

    try:
        completion = _get_openai().chat.completions.create(
            model="gpt-4o",
            messages=messages
        )
        answer = completion.choices[0].message.content
        insert_message(conversation_id, user_id, question, image_urls, answer)

        return _response(200, {
            "answer": answer,
            "image_urls": [],
            "conversation_id": conversation_id
        })
    except Exception as e:
        return _response(500, {"error": str(e)})


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": body
    }
