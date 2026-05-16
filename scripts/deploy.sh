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
echo "[1/5] Login no GitHub Container Registry..."
if [ -n "$GHCR_TOKEN" ] && [ -n "$GHCR_USER" ]; then
    echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
else
    echo "Pulando login (credenciais não definidas)"
fi

# Pull das imagens
echo ""
echo "[2/5] Baixando imagens..."
docker pull ghcr.io/integrall-tech/archbase-site:${SITE_TAG:-latest} || echo "Imagem site não encontrada"
docker pull ghcr.io/integrall-tech/archbase-react-docs:${REACT_DOCS_TAG:-latest} || echo "Imagem react-docs não encontrada"
docker pull ghcr.io/integrall-tech/archbase-flutter-docs:${FLUTTER_DOCS_TAG:-latest} || echo "Imagem flutter-docs não encontrada"
docker pull ghcr.io/integrall-tech/archbase-java-docs:${JAVA_DOCS_TAG:-latest} || echo "Imagem java-docs não encontrada"
docker pull ghcr.io/integrall-tech/integralltech-site:${INTEGRALLTECH_TAG:-latest} || echo "Imagem integralltech-site não encontrada"

# Deploy Traefik (verifica se já existe)
echo ""
echo "[3/5] Verificando Traefik..."
if docker stack ls | grep -q "^traefik "; then
    echo "Traefik já está rodando. Pulando deploy do Traefik."
    echo "Para atualizar, use: docker stack deploy -c docker-compose.traefik.yml traefik"
else
    echo "Deploy do Traefik..."
    docker stack deploy -c docker-compose.traefik.yml traefik
fi

# Remover stacks antigos (se existirem)
echo ""
echo "[4/5] Removendo stacks antigos..."
for stack in archbase-docs archbase-java archbase-react archbase-site integralltech; do
    if docker stack ls | grep -q "^$stack "; then
        echo "Removendo stack: $stack"
        docker stack rm "$stack" || true
    fi
done

# Deploy das aplicações
echo ""
echo "[5/5] Deploy das aplicações..."
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
echo "  - integrall.tech (landing page)"
echo "  - deploy.archbase.dev (webhook)"
echo ""
echo "Comandos úteis:"
echo "  docker service ls                     # Listar serviços"
echo "  docker service logs archbase_site -f  # Logs do site"
echo "  docker stack ps archbase              # Status dos containers"
echo "  docker stack rm archbase              # Remover stack"
echo ""
