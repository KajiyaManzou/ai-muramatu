#!/usr/bin/env bash
set -euo pipefail

echo "[devcontainer] Initialization starting..."

echo "[devcontainer] Workspace: /workspaces/ai-Muramatu"
echo "[devcontainer] Backend dir: ${BACKEND_DIR:-backend}"
echo "[devcontainer] Frontend1 dir: apps/frontend1"
echo "[devcontainer] Frontend2 dir: apps/frontend2"

echo "[devcontainer] Skipping installs here; frontends install on container start and backend starts via run-backend.sh."

echo "[devcontainer] Initialization complete."

