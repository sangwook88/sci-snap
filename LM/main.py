import os
import json
from openai import OpenAI

# 모듈 레벨 초기화
client = OpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
)


def lambda_handler(event, context):
    # API Gateway 이벤트
    if "body" in event:
        body = event["body"]
        if isinstance(body, str):
            body = json.loads(body)
        question = body.get("question", "")
        image_urls = body.get("image_urls", [])  # Supabase JSONB 배열: ["url1", "url2", ...]
    # 직접 Lambda 호출
    else:
        question = event.get("question", "")
        image_urls = event.get("image_urls", [])

    if not question:
        return _response(400, {"error": "Missing 'question' field in request"})

    # 멀티모달 이미지 추가
    if image_urls:
        content = [
            {"type": "image_url", "image_url": {"url": url}}
            for url in image_urls
        ]
        content.append({"type": "text", "text": question})
    else:
        content = question

    try:
        completion = client.chat.completions.create(
            model="gemini-3-flash-preview",
            messages=[{"role": "user", "content": content}]
        )
        answer = completion.choices[0].message.content
        return _response(200, {"answer": answer})
    except Exception as e:
        return _response(500, {"error": str(e)})


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, ensure_ascii=False),
    }
