"""
로컬 개발용 테스트 스크립트.
venv에서 python test_local.py 로 실행.
Docker 이미지에는 포함되지 않음.
"""
import json
from dotenv import load_dotenv

load_dotenv()  # LM/.env 에서 GEMINI_API_KEY 로드

from main import lambda_handler

# 1. 직접 호출 형식 테스트
print("=== 직접 호출 테스트 ===")
result = lambda_handler({"question": "안녕! 잘 돌아가고 있니?"}, {})
print(json.dumps(result, ensure_ascii=False, indent=2))

# 2. API Gateway 형식 테스트
print("\n=== API Gateway 형식 테스트 ===")
result2 = lambda_handler(
    {
        "httpMethod": "POST",
        "body": json.dumps({"question": "광합성이란 무엇인가요? 간단히 설명해 주세요."}),
    },
    {},
)
print(json.dumps(result2, ensure_ascii=False, indent=2))
