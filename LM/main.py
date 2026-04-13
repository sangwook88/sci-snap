import os
import json
from openai import OpenAI

# 모듈 레벨 초기화
client = OpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
)


def lambda_handler(event, context):
    # API Gateway 이벤트: event["body"] 에 JSON 문자열로 전달됨
    if "body" in event:
        body = event["body"]
        if isinstance(body, str):
            body = json.loads(body)
        question = body.get("question", "")
    # 직접 Lambda 호출: event["question"] 으로 전달됨
    else:
        question = event.get("question", "")

    if not question:
        return _response(400, {"error": "Missing 'question' field in request"})

    try:
        completion = client.chat.completions.create(
            model="gemini-3-flash-preview",
            messages=[{"role": "user", "content": question}]
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
