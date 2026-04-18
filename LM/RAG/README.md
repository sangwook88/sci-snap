# RAG (Retrieval-Augmented Generation)

초등 과학 교과서를 벡터 DB에 인덱싱하고, 사진·질문에 맞는 교과서 내용을 검색해 어린이 눈높이 응답을 생성하는 파이프라인.

## 파이프라인

```
[indexer] PDF → 텍스트/이미지 추출 → Gemini 캡셔닝 → 청킹 → OpenAI 임베딩 → Supabase 저장
                                                                                      │
[query]   질문/사진 → Vision 분석 → 하이브리드 검색(벡터 + 풀텍스트) ──────────────────┘
                                                                    │
                                              Gemini 응답 생성 → { answer, curiosity_hooks, curriculum_refs }
```

## 파일 구조

```
RAG/
├── indexer.py   # PDF 인덱싱 파이프라인 (1회성 작업)
├── query.py     # 검색 + 응답 생성 파이프라인 (Lambda에서 호출)
└── setup.sql    # Supabase 스키마 및 hybrid_search 함수 정의
```

## 모듈

### `indexer.py`
교과서 PDF를 파싱해 Supabase `curriculum_chunks` 테이블에 저장한다.

| 함수 | 역할 |
|---|---|
| `index_all_pdfs(directory)` | 디렉토리 내 모든 PDF 인덱싱 |
| `index_pdf(pdf_path)` | 단일 PDF 인덱싱 |
| `caption_image(image_bytes, nearby_text)` | 교과서 이미지를 Gemini Vision으로 캡셔닝 |
| `_embed_batch(texts)` | OpenAI `text-embedding-3-large` 배치 임베딩 (512차원) |

### `query.py`
Lambda `child` 모드에서 호출되는 RAG 쿼리 파이프라인.

| 함수 | 역할 |
|---|---|
| `analyze_photo(image_urls, question)` | 사진을 Vision으로 분석해 과학 개념·키워드 추출 |
| `analyze_text_only(question)` | 텍스트 질문에서 과학 개념·키워드 추출 |
| `hybrid_search(analysis)` | 벡터 + 풀텍스트 RRF 하이브리드 검색 |
| `generate_child_response(...)` | 교과서 컨텍스트 기반 어린이 눈높이 응답 생성 |
| `query(question, image_urls, history)` | 위 3단계를 묶는 통합 진입점 |

### `setup.sql`
Supabase에서 1회 실행하는 스키마 정의.

- `curriculum_chunks` 테이블 생성 (content, image_caption, embedding(512), metadata)
- `hybrid_search` 함수 정의 (벡터 코사인 유사도 + 풀텍스트 FTS, RRF 스코어링)

## Supabase 테이블

| 테이블 | 역할 |
|---|---|
| `curriculum_chunks` | 교과서 청크 저장 (텍스트, 이미지 캡션, 512차원 임베딩, 메타데이터) |

## 환경 변수

| 변수 | 사용처 |
|---|---|
| `OPENAI_API_KEY` | 임베딩 생성 (`text-embedding-3-large`) |
| `GEMINI_API_KEY` | Vision 캡셔닝 및 응답 생성 |
| `GEMINI_BASE_URL` | Gemini OpenAI 호환 엔드포인트 |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_KEY` | Supabase anon key |

## 교과서 PDF

| 파일 | 대상 |
|---|---|
| `JIHAKSA_과학_초_3-1_교과서.pdf` | 초등 3학년 1학기 과학 |
| `JIHAKSA_과학_초_3-2_교과서.pdf` | 초등 3학년 2학기 과학 |
| `JIHAKSA_과학_초_4-1_교과서.pdf` | 초등 4학년 1학기 과학 |
| `JIHAKSA_과학_초_4-2_교과서.pdf` | 초등 4학년 2학기 과학 |
