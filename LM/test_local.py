"""
로컬 개발용 테스트 스크립트.
venv에서 python test_local.py 로 실행.
Docker 이미지에는 포함되지 않음.
"""
import os
import json
from dotenv import load_dotenv

load_dotenv()  # 환경변수 로드

from supabase import create_client
from main import lambda_handler

# Supabase
supabase = create_client(
    os.environ["SUPABASE_URL"],
    os.environ["SUPABASE_KEY"],
)

# 직접 호출 테스트
print("=== 직접 호출 테스트 ===")
response = (
    supabase.table("analysis_requests")
    .select("question, image_urls")
    .order("created_at", desc=True)  
    .limit(1)                       
    .single()                     
    .execute()
)
row = response.data

result = lambda_handler({
      "question": row["question"],
      "image_urls": row["image_urls"], 
  }, {})
print(json.dumps(result, ensure_ascii=False, indent=2))

# API Gateway 테스트 
# print("\n=== API Gateway 형식 테스트 ===")
# result2 = lambda_handler(
#     {
#         "httpMethod": "POST",
#         "body": json.dumps({"question": "광합성이란 무엇인가요? 간단히 설명해 주세요."}),
#     },
#     {},
# )
# print(json.dumps(result2, ensure_ascii=False, indent=2))