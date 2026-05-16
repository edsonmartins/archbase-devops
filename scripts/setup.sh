#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================"
echo "  Archbase DevOps - Setup Inicial"
echo "======================================"
echo ""

# Verificar Docker
echo "[1/5] Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "ERRO: Docker não está instalado"
    exit 1
fi
echo "Docker encontrado: $(docker --version)"

# Verificar Docker Swarm
echo ""
echo "[2/5] Verificando Docker Swarm..."
SWARM_STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}')
if [ "$SWARM_STATUS" != "active" ]; then
    echo "Inicializando Docker Swarm..."
    docker swarm init || true
fi
echo "Docker Swarm: ativo"

# Login no GHCR
echo ""
echo "[3/5] Login no GitHub Container Registry..."
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

if [ -n "$GHCR_TOKEN" ] && [ -n "$GHCR_USER" ]; then
    echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
    echo "Login no GHCR: OK"
else
    echo "AVISO: GHCR_TOKEN ou GHCR_USER não definidos em .env"
    echo "Configure manualmente: docker login ghcr.io"
fi

# Criar rede
echo ""
echo "[4/5] Criando rede traefik-network..."
docker network create --driver overlay traefik-network 2>/dev/null || echo "Rede já existe"

# Criar diretórios
echo ""
echo "[5/5] Criando diretórios..."
mkdir -p "$PROJECT_DIR/traefik/dynamic"
mkdir -p "$PROJECT_DIR/backups"

echo ""
echo "======================================"
echo "  Setup concluído com sucesso!"
echo "======================================"
echo ""
echo "Próximos passos:"
echo "  1. Configure o arquivo .env (copie de .env.example)"
echo "  2. Execute: ./scripts/deploy.sh"
echo ""
