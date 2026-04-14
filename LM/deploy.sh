#!/usr/bin/env bash
# 사용법: ./deploy.sh <AWS_ACCOUNT_ID> <REGION> [FUNCTION_NAME]

set -euo pipefail

AWS_ACCOUNT_ID="${1:?AWS Account ID 필요}"
REGION="${2:?리전 필요 (예: ap-northeast-2)}"
FUNCTION_NAME="${3:-sci-snap/lm}"

IMAGE_NAME="sci-snap/lm"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE_NAME}"

echo "=== 1. ECR 로그인 ==="
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin \
    "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# echo "=== 2. ECR 리포지토리 생성 (이미 있으면 무시) ==="
# aws ecr describe-repositories \
#   --repository-names "$IMAGE_NAME" --region "$REGION" 2>/dev/null \
#   || aws ecr create-repository \
#     --repository-name "$IMAGE_NAME" --region "$REGION"

echo "=== 3. Docker 빌드 (linux/amd64 — Lambda 아키텍처) ==="
docker build --platform linux/amd64 --provenance=false -t "${IMAGE_NAME}:latest" .

echo "=== 4. 태그 & ECR 푸시 ==="
docker tag "${IMAGE_NAME}:latest" "${ECR_REPO}:latest"
docker push "${ECR_REPO}:latest"

# echo "=== 5. Lambda 함수 업데이트 또는 생성 안내 ==="
# if aws lambda get-function \
#   --function-name "$FUNCTION_NAME" --region "$REGION" 2>/dev/null; then
#   aws lambda update-function-code \
#     --function-name "$FUNCTION_NAME" \
#     --image-uri "${ECR_REPO}:latest" \
#     --region "$REGION"
#   echo "Lambda 이미지 업데이트 완료"
# else
#   echo ""
#   echo "Lambda 함수가 없습니다. 아래 명령으로 신규 생성하세요:"
#   echo ""
#   echo "aws lambda create-function \\"
#   echo "  --function-name $FUNCTION_NAME \\"
#   echo "  --package-type Image \\"
#   echo "  --code ImageUri=${ECR_REPO}:latest \\"
#   echo "  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/lambda-execution-role \\"
#   echo "  --region $REGION \\"
#   echo "  --environment 'Variables={GEMINI_API_KEY=<your-key>}' \\"
#   echo "  --timeout 30 \\"
#   echo "  --memory-size 512"
# fi

echo "=== 완료 ==="
