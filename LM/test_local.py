"""
로컬 개발용 테스트 스크립트.
venv에서 python test_local.py 로 실행.
"""
import os
import json
from dotenv import load_dotenv

load_dotenv()  # 환경변수 로드

from main import lambda_handler

# 첫 메시지 (이미지 포함, 새 대화)
print("=== 첫 메시지 테스트 (이미지 포함) ===")
result1 = lambda_handler(
    {
        "body": json.dumps({
            "question": "다시 한번 말해줘",
            "conversation_id": "31b73537-1f53-45a2-9f1d-fed18deef66e",
            "image_urls": None,
        })
    },
    {},
)
print(json.dumps(result1, ensure_ascii=False, indent=2))

# body1 = result1["body"] 
# conversation_id = body1.get("conversation_id")
# print(f"생성된 conversation_id: {conversation_id}")

# # 후속 메시지 (이미지 없음, 같은 대화)
# print("\n=== 후속 메시지 테스트 (텍스트만) ===")
# result2 = lambda_handler(
#     {
#         "body": json.dumps({
#             "question": "앞의 이미지와 이 이미지의 공통점은 뭐에요?",
#             "image_urls": ["https://jakllghtnmkwydeskjee.supabase.co/storage/v1/object/public/images/6._.jpg"],
#             "conversation_id": conversation_id,
#         })
#     },
#     {},
# )
# print(json.dumps(result2, ensure_ascii=False, indent=2))

# # 에러 케이스 (question, image_urls 모두 없음)
# print("\n=== 에러 케이스 테스트 (질문·이미지 없음) ===")
# result3 = lambda_handler(
#     {
#         "body": json.dumps({
#             "conversation_id": conversation_id,
#         })
#     },
#     {},
# )
# print(json.dumps(result3, ensure_ascii=False, indent=2))
