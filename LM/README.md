# LM (Language Model) Service

AWS Lambda 위에서 동작하는 AI 질의응답 서비스. `default` / `child` / `detect` / `child_detect` 네 가지 모드를 지원하며, GPT-4o 및 Gemini API 호출과 대화 이력을 Supabase에서 관리한다.

## 아키텍처

```
클라이언트
    │
    │ { question, image_urls, conversation_id, user_id, mode }
    ▼
AWS Lambda (main.lambda_handler)
    ├── db/db.py                 ← Supabase DB 접근
    ├── llm/gemini.py            ← Gemini API (OpenAI 호환)
    ├── RAG/                     ← 교과서 RAG (child 모드)
    └── object_detection/        ← 사물 탐지 + 과학 현상 분석 (detect 모드)
```

## 요청 모드

| mode | 동작 |
|---|---|
| `default` | 대화 이력 + 질문을 GPT-4o에 직접 전달, Markdown 응답 |
| `child` | RAG 파이프라인 — 교과서 검색 후 어린이 눈높이 응답 |
| `detect` | GPT-4o Vision으로 사물 탐지 + 과학 현상 좌표 반환 |
| `child_detect` | detect + 교과서 RAG 기반 어린이 과학 현상 분석 |

## 요청/응답 형식

**공통 요청**
```json
{
  "question": "왜 하늘은 파란가요?",
  "image_urls": ["https://..."],
  "conversation_id": "uuid (없으면 신규 생성)",
  "user_id": "optional",
  "mode": "default | child | detect | child_detect",
  "word": "탐구할 단어 (child 모드 전용, 선택)"
}
```

**default 응답**
```json
{
  "answer": "...",
  "conversation_id": "uuid",
  "curiosity_hooks": ["..."]
}
```

**child 응답**
```json
{
  "answer": "...",
  "conversation_id": "uuid",
  "curiosity_hooks": ["..."]
}
```

**detect / child_detect 응답**
```json
{
  "detect": [["사물/현상 이름", [x, y]], ...]
}
```

## 디렉토리 구조

```
LM/
├── main.py                 # Lambda 핸들러 진입점
├── test_local.py           # 로컬 통합 테스트
├── requirements.txt        # 프로덕션 의존성
├── requirements-dev.txt    # 로컬 개발 의존성 (python-dotenv 포함)
├── Dockerfile              # AWS Lambda 컨테이너 이미지
├── db/
│   └── db.py               # Supabase 클라이언트 및 DB 접근 함수
├── llm/
│   └── gemini.py           # Gemini API 클라이언트 (OpenAI 호환 엔드포인트)
├── RAG/
│   ├── indexer.py          # 교과서 PDF 인덱싱 파이프라인 (1회성)
│   ├── query.py            # 검색 + 응답 생성 파이프라인
│   └── setup.sql           # Supabase 스키마 정의
└── object_detection/
    ├── detector.py         # GPT-4o Vision 사물 탐지
    └── analyzer.py         # 과학 현상 분석 (child_detect 시 RAG 연동)
```

## 환경 변수

| 변수 | 설명 |
|---|---|
| `GEMINI_API_KEY` | Gemini API 키 |
| `GEMINI_BASE_URL` | Gemini OpenAI 호환 엔드포인트 URL |
| `OPENAI_API_KEY` | GPT-4o / 임베딩용 OpenAI API 키 |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_KEY` | Supabase anon key |

## Supabase 테이블

| 테이블 | 역할 |
|---|---|
| `conversations` | 대화 세션 (id, user_id, updated_at) |
| `analysis_requests` | 질문·답변 메시지 (conversation_id, question, image_urls, answer) |
| `curriculum_chunks` | 교과서 청크 및 512차원 임베딩 (child 모드 전용) |

## 로컬 실행

```bash
# 1. 가상환경 생성 및 패키지 설치
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt

# 2. 환경 변수 설정
cp .env_example .env
# .env 파일에 API 키 입력

# 3. 테스트 실행
python test_local.py
```

## Docker 빌드 및 배포

```bash
# 이미지 빌드 (프로젝트 루트에서 실행)
docker build -f LM/Dockerfile -t sci-snap-lm LM/

# AWS ECR 푸시 후 Lambda에 연결
aws ecr get-login-password | docker login --username AWS --password-stdin <ECR_URI>
docker tag sci-snap-lm:latest <ECR_URI>/sci-snap-lm:latest
docker push <ECR_URI>/sci-snap-lm:latest
```

## RAG 상세

교과서 인덱싱 파이프라인 및 하이브리드 검색 상세는 [RAG/README.md](RAG/README.md) 참조.
