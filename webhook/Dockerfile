FROM docker:cli AS docker-cli

FROM almir/webhook:latest

# Install docker CLI from docker:cli image
COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker

# Make scripts executable
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh
