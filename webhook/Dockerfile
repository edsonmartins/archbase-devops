FROM docker:cli AS docker-cli

FROM almir/webhook:latest

USER root

# Install docker CLI from docker:cli image
COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker

# Copy scripts and make executable
COPY --chmod=755 scripts/ /scripts/
