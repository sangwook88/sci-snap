# LM (Language Model) Service

AWS Lambda 위에서 동작하는 AI 질의응답 서비스. Gemini API를 호출하고 대화 이력을 Supabase에 저장한다.

## 아키텍처

```
클라이언트
    │
    │ { question, image_urls, conversation_id, user_id }
    ▼
AWS Lambda (main.lambda_handler)
    ├── db/db.py          ← Supabase DB 접근
    └── llm/gemini.py     ← Gemini API 호출
```

## 요청 흐름

```
1. Lambda 이벤트 수신
        │
2. upsert_conversation()   ← conversation_id 없으면 신규 생성, 있으면 updated_at 갱신
        │
3. fetch_history()         ← 해당 대화의 이전 메시지 최대 10개 로드
        │
4. messages 조립
   ├── system: Markdown 형식으로 답변하라는 지시
   ├── (이전 대화 history)
   └── user: 현재 질문 + 이미지 URL
        │
5. Gemini API 호출 (gemini-3-flash-preview)
        │
6. insert_message()        ← 질문 + 답변 DB 저장
        │
7. 응답 반환 { answer, conversation_id }
```

## 디렉토리 구조

```
LM/
├── main.py           # Lambda 핸들러 진입점
├── db/
│   └── db.py         # Supabase 클라이언트 및 DB 접근 함수
└── llm/
    └── gemini.py     # Gemini API 클라이언트 (OpenAI 호환 엔드포인트)
```

## 주요 모듈

### `main.py`
- `lambda_handler(event, context)` — Lambda 진입점. 요청 파싱 → DB 조회 → LLM 호출 → DB 저장 → 응답 반환

### `db/db.py`
| 함수 | 설명 |
|---|---|
| `upsert_conversation(conversation_id, user_id)` | 대화 생성 또는 갱신, conversation_id 반환 |
| `fetch_history(conversation_id)` | 대화 이력 최대 10개 조회 |
| `insert_message(...)` | 질문/답변 저장 |

### `llm/gemini.py`
- Gemini API를 OpenAI SDK 호환 방식으로 호출
- `build_content(question, image_urls)` — 텍스트+이미지 멀티모달 content 형식으로 변환

## Supabase 테이블

| 테이블 | 역할 |
|---|---|
| `conversations` | 대화 세션 관리 (id, user_id, updated_at) |
| `analysis_requests` | 질문/답변 메시지 저장 (conversation_id, question, image_urls, answer) |

## 환경 변수

| 변수 | 설명 |
|---|---|
| `GEMINI_API_KEY` | Gemini API 키 |
| `GEMINI_BASE_URL` | Gemini OpenAI 호환 엔드포인트 URL |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_KEY` | Supabase anon key |

## 배포

Docker 이미지를 빌드해 AWS ECR에 푸시 후 Lambda에 연결한다.

```bash
docker build -f LM/Dockerfile -t sci-snap-lm .
```
