#!/bin/bash
# =============================================================================
# TeamSync Editor - Stop Local Services
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Stopping TeamSync Editor services..."
docker compose down

echo "Services stopped."
