#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Carregar variáveis de ambiente
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

SERVICE=$1
TAG=${2:-latest}

if [ -z "$SERVICE" ]; then
    echo "Uso: ./update-service.sh <service> [tag]"
    echo ""
    echo "Serviços disponíveis:"
    echo "  site         - archbase.dev"
    echo "  react-docs   - react.archbase.dev"
    echo "  flutter-docs - flutter.archbase.dev"
    echo "  java-docs    - java.archbase.dev"
    echo ""
    echo "Exemplo: ./update-service.sh site v1.0.0"
    exit 1
fi

# Mapear serviço para imagem
case $SERVICE in
    site)
        IMAGE="ghcr.io/integrall-tech/archbase-site:$TAG"
        STACK_SERVICE="archbase_site"
        ;;
    react-docs)
        IMAGE="ghcr.io/integrall-tech/archbase-react-docs:$TAG"
        STACK_SERVICE="archbase_react-docs"
        ;;
    flutter-docs)
        IMAGE="ghcr.io/integrall-tech/archbase-flutter-docs:$TAG"
        STACK_SERVICE="archbase_flutter-docs"
        ;;
    java-docs)
        IMAGE="ghcr.io/integrall-tech/archbase-java-docs:$TAG"
        STACK_SERVICE="archbase_java-docs"
        ;;
    *)
        echo "Serviço desconhecido: $SERVICE"
        exit 1
        ;;
esac

echo "======================================"
echo "  Atualizando $SERVICE para $TAG"
echo "======================================"
echo ""

# Login no GHCR
if [ -n "$GHCR_TOKEN" ] && [ -n "$GHCR_USER" ]; then
    echo "[1/3] Login no GHCR..."
    echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
fi

# Pull da imagem
echo ""
echo "[2/3] Baixando imagem $IMAGE..."
docker pull $IMAGE

# Atualizar serviço
echo ""
echo "[3/3] Atualizando serviço $STACK_SERVICE..."
docker service update --image $IMAGE $STACK_SERVICE --with-registry-auth

echo ""
echo "Serviço atualizado!"
docker service ps $STACK_SERVICE
