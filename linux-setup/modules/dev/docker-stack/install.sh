#!/bin/bash
set -e

VARIANT="${1:-all}"
STACK_DIR="$HOME/docker-dev-stack"
mkdir -p "$STACK_DIR"

echo "🐳 Setting up Docker dev stack: $VARIANT"

# Check if Docker is running
if ! docker ps >/dev/null 2>&1; then
    echo "❌ Docker daemon is not running or permission denied."
    exit 1
fi

pull_image() {
    local name=$1
    local image=$2
    echo "📥 Downloading $name image ($image)..."
    docker pull "$image"
}

# 1. Expand image download logic
case "$VARIANT" in
    postgres) pull_image "PostgreSQL" "postgres:latest" ;;
    mysql)    pull_image "MySQL" "mysql:latest" ;;
    redis)    pull_image "Redis" "redis:latest" ;;
    mongodb)  pull_image "MongoDB" "mongo:latest" ;;
    rabbitmq) pull_image "RabbitMQ" "rabbitmq:3-management" ;;
    kafka)    
        pull_image "Zookeeper" "bitnami/zookeeper:latest"
        pull_image "Kafka" "bitnami/kafka:latest" 
        ;;
    prometheus-grafana)
        pull_image "Prometheus" "prom/prometheus:latest"
        pull_image "Grafana" "grafana/grafana:latest"
        ;;
    jenkins)  pull_image "Jenkins" "jenkins/jenkins:lts" ;;
    gitea)    pull_image "Gitea" "gitea/gitea:latest" ;;
    portainer) pull_image "Portainer" "portainer/portainer-ce:latest" ;;
    keycloak) pull_image "Keycloak" "quay.io/keycloak/keycloak:latest" ;;
    localstack) pull_image "LocalStack" "localstack/localstack:latest" ;;
    all)
        echo "Downloading all default development images..."
        for img in "postgres:latest" "mysql:latest" "redis:latest" "mongo:latest" "rabbitmq:3-management" "portainer/portainer-ce:latest"; do
            docker pull "$img"
        done
        ;;
esac

# 2. Create docker-compose.yml template (Overwrite)
if [ ! -f "$STACK_DIR/docker-compose.yml" ]; then
    echo "version: '3.8'" > "$STACK_DIR/docker-compose.yml"
    echo "services:" >> "$STACK_DIR/docker-compose.yml"
fi

cat <<EOF > "$STACK_DIR/docker-compose.yml"
version: '3.8'
services:
  # Databases
  postgres:
    image: postgres:latest
    container_name: dev-postgres
    ports: ["5432:5432"]
    environment: {POSTGRES_USER: devuser, POSTGRES_PASSWORD: devpassword, POSTGRES_DB: devdb}
    profiles: ["db", "all"]

  redis:
    image: redis:latest
    container_name: dev-redis
    ports: ["6379:6379"]
    profiles: ["db", "all"]

  # Message Brokers
  rabbitmq:
    image: rabbitmq:3-management
    container_name: dev-rabbitmq
    ports: ["5672:5672", "15672:15672"]
    profiles: ["mq", "all"]

  # Monitoring
  grafana:
    image: grafana/grafana:latest
    container_name: dev-grafana
    ports: ["3000:3000"]
    profiles: ["monitor", "all"]

  # CI/CD & Git
  gitea:
    image: gitea/gitea:latest
    container_name: dev-gitea
    ports: ["3001:3000", "2222:22"]
    profiles: ["infra", "all"]

  # Tools
  portainer:
    image: portainer/portainer-ce:latest
    container_name: dev-portainer
    ports: ["9000:9000"]
    volumes: ["/var/run/docker.sock:/var/run/docker.sock"]
    profiles: ["tools", "all"]
EOF

echo "✅ Docker stack and configuration files updated"
