import json
from db.db import upsert_conversation, fetch_history, insert_message
from llm.gemini import client, build_content


def lambda_handler(event, context):
    body = event.get("body", event)
    if isinstance(body, str):
        body = json.loads(body)

    question        = body.get("question") or ""
    image_urls      = body.get("image_urls") or []
    conversation_id = body.get("conversation_id") or None
    user_id         = body.get("user_id") or None

    if not question and not image_urls:
        return _response(400, {"error": "Question and image_urls are both empty"})

    conversation_id = upsert_conversation(conversation_id, user_id)

    history = fetch_history(conversation_id)
    messages = [
        {
            "role": "system",
            "content": "답변은 항상 Markdown 형식으로 작성해 주세요. 제목, 목록, 강조 등 Markdown 문법을 적극 활용하세요.",
        }
    ]
    for turn in history:
        messages.append({"role": "user",      "content": build_content(turn["question"], turn.get("image_urls") or [])})
        messages.append({"role": "assistant", "content": turn["answer"]})
    messages.append({"role": "user", "content": build_content(question, image_urls)})

    try:
        completion = client.chat.completions.create(
            model="gemini-3-flash-preview",
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
