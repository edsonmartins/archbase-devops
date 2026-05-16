#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================"
echo "  Archbase DevOps - Deploy"
echo "======================================"
echo ""

# Carregar variáveis de ambiente
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo "AVISO: Arquivo .env não encontrado"
fi

cd "$PROJECT_DIR"

# Login no GHCR
echo "[1/4] Login no GitHub Container Registry..."
if [ -n "$GHCR_TOKEN" ] && [ -n "$GHCR_USER" ]; then
    echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
else
    echo "Pulando login (credenciais não definidas)"
fi

# Pull das imagens
echo ""
echo "[2/4] Baixando imagens..."
docker pull ghcr.io/integrall-tech/archbase-site:${SITE_TAG:-latest} || echo "Imagem site não encontrada"
docker pull ghcr.io/integrall-tech/archbase-react-docs:${REACT_DOCS_TAG:-latest} || echo "Imagem react-docs não encontrada"
docker pull ghcr.io/integrall-tech/archbase-flutter-docs:${FLUTTER_DOCS_TAG:-latest} || echo "Imagem flutter-docs não encontrada"
docker pull ghcr.io/integrall-tech/archbase-java-docs:${JAVA_DOCS_TAG:-latest} || echo "Imagem java-docs não encontrada"

# Deploy Traefik
echo ""
echo "[3/4] Deploy do Traefik..."
docker stack deploy -c docker-compose.traefik.yml traefik

# Deploy das aplicações
echo ""
echo "[4/4] Deploy das aplicações..."
docker stack deploy -c docker-compose.yml archbase

echo ""
echo "======================================"
echo "  Deploy concluído!"
echo "======================================"
echo ""
echo "Serviços:"
echo "  - archbase.dev (site principal)"
echo "  - react.archbase.dev (docs React)"
echo "  - flutter.archbase.dev (docs Flutter)"
echo "  - java.archbase.dev (docs Java)"
echo ""
echo "Comandos úteis:"
echo "  docker service ls                     # Listar serviços"
echo "  docker service logs archbase_site -f  # Logs do site"
echo "  docker stack ps archbase              # Status dos containers"
echo "  docker stack rm archbase              # Remover stack"
echo ""
