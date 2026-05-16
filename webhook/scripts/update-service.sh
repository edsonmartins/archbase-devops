#!/bin/sh
set -e

SERVICE_NAME=$1
IMAGE_NAME=$2

echo "$(date): Updating service archbase_${SERVICE_NAME} with image ${IMAGE_NAME}:latest"

# Pull nova imagem
docker pull "${IMAGE_NAME}:latest"

# Atualizar serviço
docker service update \
  --image "${IMAGE_NAME}:latest" \
  --force \
  "archbase_${SERVICE_NAME}"

echo "$(date): Service archbase_${SERVICE_NAME} updated successfully"
