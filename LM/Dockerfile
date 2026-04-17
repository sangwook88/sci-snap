FROM public.ecr.aws/lambda/python:3.12 AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --target /build/packages -r requirements.txt

FROM public.ecr.aws/lambda/python:3.12
WORKDIR /var/task

COPY --from=builder /build/packages .
COPY db/ db/
COPY llm/ llm/
COPY RAG/ RAG/
COPY object_detection/ object_detection/
COPY main.py .

CMD ["main.lambda_handler"]
