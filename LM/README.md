# LM Service — AI 질문 분석 Lambda

Gemini 모델을 통해 텍스트·이미지 기반 질문에 답변하는 AWS Lambda 서비스입니다.
대화 히스토리를 Supabase에 저장하여 멀티턴 대화를 지원합니다.

---

## 아키텍처 개요

```
FE (Next.js 등)
    │
    │  POST (JSON body)
    ▼
AWS Lambda (main.py)
    ├── Gemini API (gemini-3-flash-preview)   ← AI 답변 생성
    └── Supabase (PostgreSQL)                 ← 대화 기록 저장/조회
```

**핵심 흐름**

1. FE가 `question` / `image_urls` / `conversation_id` 를 Lambda로 전송
2. Lambda가 해당 대화의 이전 턴(최대 10개)을 Supabase에서 조회
3. 히스토리 + 현재 질문을 Gemini에 전달 → 답변 수신
4. 질문·답변을 `analysis_requests` 테이블에 저장
5. `answer` + `conversation_id` 를 FE에 반환

---

## 환경 변수

| 변수명 | 설명 |
|---|---|
| `GEMINI_API_KEY` | Google Gemini API 키 |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_KEY` | Supabase service_role 또는 anon 키 |

---

## DB 테이블 스키마

### `conversations` — 대화 세션

```sql
create table public.conversations (
  id         uuid      not null default gen_random_uuid(),
  user_id    uuid      null,
  title      text      null,
  created_at timestamptz null default now(),
  updated_at timestamptz null default now(),
  constraint conversations_pkey primary key (id)
);
```

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `id` | uuid (PK) | 대화 세션 고유 ID — FE가 이 값을 유지해야 멀티턴 가능 |
| `user_id` | uuid | 로그인 유저 ID (없으면 null) |
| `title` | text | 대화 제목 (현재 미사용, FE에서 자유롭게 활용) |
| `created_at` | timestamptz | 최초 생성 시각 |
| `updated_at` | timestamptz | 마지막 메시지 시각 — 새 턴마다 자동 갱신 |

---

### `analysis_requests` — 질문/답변 메시지

```sql
create table public.analysis_requests (
  id              uuid  not null default gen_random_uuid(),
  user_id         uuid  null,
  question        text  not null,
  image_urls      jsonb null,
  answer          text  null,
  created_at      timestamptz null default now(),
  conversation_id uuid  null,
  constraint analysis_requests_pkey primary key (id),
  constraint analysis_requests_conversation_id_fkey
    foreign key (conversation_id) references conversations (id) on delete cascade
);
```

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `id` | uuid (PK) | 메시지 고유 ID |
| `user_id` | uuid | 로그인 유저 ID (없으면 null) |
| `question` | text | 유저가 보낸 질문 텍스트 |
| `image_urls` | jsonb | 이미지 URL 배열 (없으면 null) — 예: `["https://..."]` |
| `answer` | text | Gemini 답변 텍스트 |
| `created_at` | timestamptz | 메시지 생성 시각 |
| `conversation_id` | uuid (FK → conversations) | 어느 대화 세션에 속하는지 |

**관계 요약**

```
conversations (1) ──< analysis_requests (N)
```

---

## API 명세

### `POST /` — AI 질문

Lambda는 API Gateway 또는 Function URL을 통해 단일 엔드포인트로 호출됩니다.

#### Request

**Headers**

```
Content-Type: application/json
```

**Body**

```jsonc
{
  "question": "이 이미지를 설명해 주세요.",   // string — 텍스트 질문 (image_urls 없을 때 필수)
  "image_urls": [                             // string[] | null — 이미지 URL 배열
    "https://example.com/image.jpg"
  ],
  "conversation_id": "uuid-string",           // string | null — 이전 대화 이어가기 (없으면 신규 생성)
  "user_id": "uuid-string"                    // string | null — 유저 식별자 (없어도 동작)
}
```

> `question` 과 `image_urls` 중 하나 이상은 반드시 있어야 합니다.

---

#### Response — 200 OK

```jsonc
{
  "answer": "이 이미지는 ...",           // string — Gemini 답변
  "conversation_id": "uuid-string"       // string — 현재/신규 대화 세션 ID (다음 턴에 재사용)
}
```

#### Response — 400 Bad Request

```jsonc
{
  "error": "Question and image_urls are both empty"
}
```

#### Response — 500 Internal Server Error

```jsonc
{
  "error": "에러 메시지"
}
```

---

## FE 연동 예시

### 신규 대화 시작

```ts
const res = await fetch(LAMBDA_URL, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    question: "이 사진에서 뭘 볼 수 있나요?",
    image_urls: ["https://..."],
    user_id: session?.user?.id ?? null,   // 비로그인 시 null
  }),
});

const data = await res.json();
// data.answer         → AI 답변
// data.conversation_id → 이 값을 state에 저장해 두었다가 다음 요청에 재사용
```

### 대화 이어가기 (멀티턴)

```ts
const res = await fetch(LAMBDA_URL, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    question: "더 자세하게 설명해 주세요.",
    conversation_id: savedConversationId,   // 이전 응답에서 받은 ID
    user_id: session?.user?.id ?? null,
  }),
});
```

### 이미지만 전송 (텍스트 없음)

```ts
body: JSON.stringify({
  image_urls: ["https://..."],
  conversation_id: savedConversationId,
})
```

---

## 멀티턴 동작 방식

- `conversation_id` 를 전달하면 해당 대화의 **이전 턴 최대 10개**를 히스토리로 로드해 Gemini에게 컨텍스트로 전달합니다.
- `conversation_id` 를 전달하지 않으면 새 대화 세션이 자동 생성되며, 응답의 `conversation_id` 를 다음 요청에 사용하면 됩니다.
- `answer` 가 null인 레코드(저장 실패 등)는 히스토리에서 제외됩니다.

---

## 로컬 개발

```bash
# 1. 가상환경 및 의존성
python -m venv .venv
source .venv/bin/activate
pip install openai supabase python-dotenv

# 2. 환경변수 파일
cat > .env <<EOF
GEMINI_API_KEY=...
SUPABASE_URL=...
SUPABASE_KEY=...
EOF

# 3. 테스트 실행
python test_local.py
```

---

## 배포 (Docker → AWS Lambda)

```bash
# 빌드
docker build -t lm-service .

# ECR 푸시 후 Lambda 이미지 업데이트
aws ecr get-login-password | docker login --username AWS --password-stdin <ECR_URI>
docker tag lm-service:latest <ECR_URI>/lm-service:latest
docker push <ECR_URI>/lm-service:latest
```

핸들러: `main.lambda_handler`

---

## 파일 구조

```
LM/
├── main.py           # Lambda 핸들러 + Gemini 호출 + Supabase 연동
├── test_local.py     # 로컬 테스트 스크립트 (Docker 이미지 미포함)
├── requirements.txt  # openai, supabase
├── Dockerfile        # multi-stage 빌드 (python:3.12 Lambda 베이스)
└── README.md
```
