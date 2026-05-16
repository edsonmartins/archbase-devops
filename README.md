# Archbase DevOps

Infraestrutura centralizada para deploy do site e documentações do Archbase.

## Domínios

| Serviço | Domínio | Repositório |
|---------|---------|-------------|
| Site Principal | archbase.dev | edsonmartins/archbase-site |
| React Docs | react.archbase.dev | edsonmartins/archbase-react |
| Flutter Docs | flutter.archbase.dev | edsonmartins/archbase-flutter-docs |
| App Docs | app.archbase.dev | edsonmartins/archbase-app-documentation |

## Quick Start

### 1. Configurar Secrets no GitHub

No repositório `integrall-tech/archbase-devops`, configure em **Settings > Secrets and variables > Actions**:

| Secret | Valor |
|--------|-------|
| `VPS_HOST` | 54.145.219.180 |
| `VPS_USER` | ec2-user |
| `VPS_SSH_KEY` | Conteúdo de `IaT_aws_siteserver.pem` |
| `GHCR_USER` | Seu username GitHub |
| `GHCR_TOKEN` | PAT com `read:packages` |

### 2. Configurar VPS (primeira vez)

```bash
# Conectar na VPS
ssh -i /path/to/IaT_aws_siteserver.pem ec2-user@54.145.219.180

# Clonar o repositório
git clone https://github.com/integrall-tech/archbase-devops.git
cd archbase-devops

# Configurar ambiente
cp .env.example .env
nano .env  # Preencher GHCR_USER e GHCR_TOKEN

# Setup inicial
./scripts/setup.sh

# Deploy
./scripts/deploy.sh
```

## Workflows

Cada workflow pode ser disparado de duas formas:

### 1. Manual (workflow_dispatch)

No GitHub, vá em **Actions** > selecione o workflow > **Run workflow**

### 2. Via API (repository_dispatch)

```bash
# Exemplo: disparar build do site
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/integrall-tech/archbase-devops/dispatches \
  -d '{"event_type":"build-site","client_payload":{"ref":"main"}}'
```

### 3. Trigger automático nos repos de origem

Adicione este workflow em cada repositório de origem (ex: `edsonmartins/archbase-site`):

```yaml
# .github/workflows/trigger-build.yml
name: Trigger Build

on:
  push:
    branches: [main]

jobs:
  trigger:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger archbase-devops build
        uses: peter-evans/repository-dispatch@v2
        with:
          token: ${{ secrets.DEVOPS_TRIGGER_TOKEN }}
          repository: integrall-tech/archbase-devops
          event-type: build-site  # ou build-react-docs, build-flutter-docs, build-app-docs
          client-payload: '{"ref": "${{ github.ref }}"}'
```

## Scripts

| Script | Descrição |
|--------|-----------|
| `./scripts/setup.sh` | Setup inicial (rede, diretórios, login) |
| `./scripts/deploy.sh` | Deploy completo (Traefik + apps) |
| `./scripts/update-service.sh <service> [tag]` | Atualizar serviço específico |

### Exemplos

```bash
# Atualizar site para tag específica
./scripts/update-service.sh site v1.2.0

# Atualizar react-docs para latest
./scripts/update-service.sh react-docs

# Atualizar flutter-docs
./scripts/update-service.sh flutter-docs
```

## Estrutura

```
archbase-devops/
├── .github/workflows/
│   ├── build-site.yml          # Build archbase-site
│   ├── build-react-docs.yml    # Build archbase-react
│   ├── build-flutter-docs.yml  # Build archbase-flutter-docs
│   └── build-app-docs.yml      # Build archbase-app-documentation
├── scripts/
│   ├── setup.sh                # Setup inicial
│   ├── deploy.sh               # Deploy completo
│   └── update-service.sh       # Atualizar serviço
├── traefik/
│   ├── traefik.yml             # Config estática
│   └── dynamic/
│       └── middlewares.yml     # Middlewares HTTP
├── docker-compose.yml          # Stack das aplicações
├── docker-compose.traefik.yml  # Stack do Traefik
├── .env.example                # Template de configuração
└── README.md
```

## Arquitetura

```
                    ┌─────────────────┐
                    │   GitHub Repos  │
                    │  (source code)  │
                    └────────┬────────┘
                             │ push
                             ▼
                    ┌─────────────────┐
                    │  archbase-devops│
                    │ GitHub Actions  │
                    └────────┬────────┘
                             │ build & push
                             ▼
                    ┌─────────────────┐
                    │     GHCR        │
                    │ ghcr.io/integrall│
                    └────────┬────────┘
                             │ pull
                             ▼
┌──────────────────────────────────────────────────┐
│                    VPS (AWS)                      │
│                                                   │
│  ┌──────────┐    ┌────────────────────────────┐  │
│  │ Traefik  │───▶│     Docker Swarm Stack     │  │
│  │  :80/443 │    │                            │  │
│  └──────────┘    │  ┌──────┐ ┌────────────┐   │  │
│                  │  │ site │ │ react-docs │   │  │
│                  │  └──────┘ └────────────┘   │  │
│                  │                            │  │
│                  │  ┌──────────────┐ ┌──────┐ │  │
│                  │  │ flutter-docs │ │app-doc│ │  │
│                  │  └──────────────┘ └──────┘ │  │
│                  └────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

## Comandos Úteis

```bash
# Ver status dos serviços
docker service ls

# Logs de um serviço
docker service logs archbase_site -f

# Ver containers do stack
docker stack ps archbase

# Remover stack
docker stack rm archbase

# Forçar redeploy de um serviço
docker service update --force archbase_site
```

## Requisitos dos Repositórios de Origem

Cada repositório deve ter um `Dockerfile` na raiz que:
1. Faz build da aplicação (Next.js, Docusaurus, etc)
2. Serve com nginx na porta 80

### Exemplo de Dockerfile para Next.js

```dockerfile
FROM node:20-alpine AS builder
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

FROM nginx:alpine
COPY --from=builder /app/out /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Exemplo de nginx.conf

```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ $uri/index.html =404;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
```
