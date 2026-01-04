#!/bin/bash
# =============================================================================
# TeamSync Editor - Local Development Start Script
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=========================================="
echo "TeamSync Editor - Local Development"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running!"
    echo ""
    echo "Please start Docker Desktop and try again."
    echo "On macOS: Open Docker Desktop from Applications"
    echo ""
    exit 1
fi

echo "Docker is running."
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Creating .env from template..."
    cp .env.example .env
    echo "Created .env file. Please review and update if needed."
fi

echo "Starting services..."
echo ""

# Pull latest images
echo "[1/4] Pulling Docker images..."
docker compose pull minio 2>/dev/null || true

# Build WOPI host
echo "[2/4] Building WOPI host..."
docker compose build wopi-host

# Start all services
echo "[3/4] Starting all services..."
docker compose up -d

# Wait for services to be healthy
echo "[4/4] Waiting for services to be ready..."
echo ""

# Wait for Collabora
echo -n "Waiting for Collabora Online..."
for i in {1..60}; do
    if curl -sf http://localhost:9980/hosting/discovery > /dev/null 2>&1; then
        echo " Ready!"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for MinIO
echo -n "Waiting for MinIO..."
for i in {1..30}; do
    if curl -sf http://localhost:9000/minio/health/live > /dev/null 2>&1; then
        echo " Ready!"
        break
    fi
    echo -n "."
    sleep 1
done

# Wait for WOPI Host
echo -n "Waiting for WOPI Host..."
for i in {1..30}; do
    if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then
        echo " Ready!"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""
echo "=========================================="
echo "All services are running!"
echo "=========================================="
echo ""
echo "Service URLs:"
echo "  Collabora Discovery: http://localhost:9980/hosting/discovery"
echo "  WOPI Host API:       http://localhost:3000/api/health"
echo "  MinIO Console:       http://localhost:9001"
echo "    Username: minioadmin"
echo "    Password: minioadmin123"
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
echo ""
echo "To stop services:"
echo "  docker compose down"
echo ""
echo "=========================================="
