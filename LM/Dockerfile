FROM public.ecr.aws/lambda/python:3.12 AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --target /build/packages -r requirements.txt

FROM public.ecr.aws/lambda/python:3.12
WORKDIR /var/task

# 패키지 및 코드 복사
COPY --from=builder /build/packages .
COPY db/ db/
COPY llm/ llm/
COPY main.py .

# 실행 시 main.py를 직접 실행할 수 있도록 핸들러 지정
CMD ["main.lambda_handler"]
