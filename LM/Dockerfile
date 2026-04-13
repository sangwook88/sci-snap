# ── 빌드 스테이지: 의존성 설치 ──────────────────────────────────────────────
FROM public.ecr.aws/lambda/python:3.12 AS builder

WORKDIR /build

COPY requirements.txt .

# /build/packages 에 설치 (최종 이미지에만 복사)
RUN pip install --no-cache-dir --target /build/packages -r requirements.txt

# ── 최종 스테이지 ─────────────────────────────────────────────────────────────
FROM public.ecr.aws/lambda/python:3.12

# 설치된 패키지 복사
COPY --from=builder /build/packages /var/task

# 핸들러 코드 복사
COPY main.py /var/task/

# Lambda 핸들러: main.py 의 lambda_handler 함수
CMD ["main.lambda_handler"]
