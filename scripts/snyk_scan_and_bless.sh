#!/usr/bin/env bash
set -euo pipefail

: "${AWS_ACCOUNT_ID:?Missing AWS_ACCOUNT_ID}"
: "${AWS_REGION:?Missing AWS_REGION}"
: "${ECR_REPO:?Missing ECR_REPO}"
: "${IMAGE_SHA:?Missing IMAGE_SHA}"

if ! command -v snyk >/dev/null 2>&1; then
  echo "Snyk CLI not found. Install or use snyk/actions in CI." >&2
  exit 1
fi

IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_SHA}"

echo "Scanning image: ${IMAGE} (severity >= high will fail)"
snyk container test "${IMAGE}" --severity-threshold=high --fail-on=all

echo "Scan passed. Tagging blessed image..."
BLESSED_TAG="${IMAGE_SHA}-blessed"
MANIFEST=$(aws ecr batch-get-image --repository-name "${ECR_REPO}" --image-ids imageTag="${IMAGE_SHA}" --query 'images[0].imageManifest' --output text)
aws ecr put-image --repository-name "${ECR_REPO}" --image-tag "${BLESSED_TAG}" --image-manifest "${MANIFEST}"
echo "Blessed tag pushed: ${ECR_REPO}:${BLESSED_TAG}"
