# LM (Language Model) Service

AWS Lambda 위에서 동작하는 AI 질의응답 서비스. `default` / `child` 두 가지 모드를 지원하며, Gemini API 호출과 대화 이력을 Supabase에서 관리한다.

## 아키텍처

```
클라이언트
    │
    │ { question, image_urls, conversation_id, user_id, mode }
    ▼
AWS Lambda (main.lambda_handler)
    ├── db/db.py          ← Supabase DB 접근
    ├── llm/gemini.py     ← Gemini API 호출
    └── RAG/              ← 교과서 RAG (child 모드 전용)
```

## 요청 흐름

```
1. Lambda 이벤트 수신
        │
2. upsert_conversation()   ← conversation_id 없으면 신규 생성, 있으면 updated_at 갱신
        │
3. fetch_history()         ← 해당 대화의 이전 메시지 최대 10개 로드
        │
4. mode 분기
   ├── child  → RAG 파이프라인 (Vision 분석 → 교과서 검색 → 어린이 응답)
   └── default → Gemini 직접 호출 (대화 이력 + 현재 질문)
        │
5. insert_message()        ← 질문 + 답변 DB 저장
        │
6. 응답 반환
   ├── default: { answer, conversation_id }
   └── child:   { answer, conversation_id, curiosity_hooks, curriculum_refs }
```

## 디렉토리 구조

```
LM/
├── main.py           # Lambda 핸들러 진입점
├── test_local.py     # 로컬 통합 테스트
├── db/
│   └── db.py         # Supabase 클라이언트 및 DB 접근 함수
├── llm/
│   └── gemini.py     # Gemini API 클라이언트 (OpenAI 호환 엔드포인트)
└── RAG/
    ├── indexer.py    # 교과서 PDF 인덱싱 파이프라인 (1회성)
    ├── query.py      # 검색 + 응답 생성 파이프라인
    └── setup.sql     # Supabase 스키마 정의
```

## 주요 모듈

### `main.py`
- `lambda_handler(event, context)` — Lambda 진입점. mode에 따라 RAG 또는 Gemini 직접 호출로 분기

### `db/db.py`
| 함수 | 설명 |
|---|---|
| `upsert_conversation(conversation_id, user_id)` | 대화 생성 또는 갱신, conversation_id 반환 |
| `fetch_history(conversation_id)` | 대화 이력 최대 10개 조회 |
| `insert_message(...)` | 질문/답변 저장 |

### `llm/gemini.py`
- Gemini API를 OpenAI SDK 호환 방식으로 호출
- `build_content(question, image_urls)` — 텍스트+이미지 멀티모달 content 형식으로 변환

### `RAG/`
초등 과학 교과서 벡터 검색 및 어린이 눈높이 응답 생성. 상세 내용은 [RAG/README.md](RAG/README.md) 참조.

## Supabase 테이블

| 테이블 | 역할 |
|---|---|
| `conversations` | 대화 세션 관리 (id, user_id, updated_at) |
| `analysis_requests` | 질문/답변 메시지 저장 (conversation_id, question, image_urls, answer) |
| `curriculum_chunks` | 교과서 청크 및 임베딩 저장 (child 모드 전용) |

## 환경 변수

| 변수 | 설명 |
|---|---|
| `GEMINI_API_KEY` | Gemini API 키 |
| `GEMINI_BASE_URL` | Gemini OpenAI 호환 엔드포인트 URL |
| `OPENAI_API_KEY` | OpenAI 임베딩 키 (child 모드 전용) |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_KEY` | Supabase anon key |

## 배포

Docker 이미지를 빌드해 AWS ECR에 푸시 후 Lambda에 연결한다.

```bash
docker build -f LM/Dockerfile -t sci-snap-lm .
```
