#!/usr/bin/env bash
set -euo pipefail

BACKEND_DIR_REL=${BACKEND_DIR:-backend}
BACKEND_DIR_ABS="/workspaces/ai-Muramatu/${BACKEND_DIR_REL}"

if [ ! -d "$BACKEND_DIR_ABS" ]; then
  echo "[backend] Directory not found: $BACKEND_DIR_ABS. Skipping backend start."
  exit 0
fi

echo "[backend] Using directory: $BACKEND_DIR_ABS"
cd "$BACKEND_DIR_ABS"

if ls *.csproj >/dev/null 2>&1; then
  echo "[backend] Detected .NET project"
  if ! command -v dotnet >/dev/null 2>&1; then
    echo "[backend] 'dotnet' is not installed in this container. Install the .NET SDK feature or update the base image. Skipping."
    exit 0
  fi
  export ASPNETCORE_URLS="${ASPNETCORE_URLS:-http://0.0.0.0:8000}"
  echo "[backend] Restoring: dotnet restore"
  dotnet restore || exit 1
  echo "[backend] Starting: dotnet watch run --no-restore --urls $ASPNETCORE_URLS"
  exec dotnet watch run --no-restore --urls "$ASPNETCORE_URLS"
fi

if [ -f package.json ]; then
  echo "[backend] Detected Node.js project"
  if [ -f package-lock.json ]; then npm ci || npm install; else npm install; fi
  if npm run | grep -q " dev\b"; then
    echo "[backend] Starting: npm run dev"
    exec npm run dev
  fi
  echo "[backend] No 'dev' script found. Skipping."
  exit 0
fi

if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  echo "[backend] Detected Python project"
  VENV_DIR="/home/vscode/.venv"
  python3 -m venv "$VENV_DIR"
  . "$VENV_DIR/bin/activate"
  python -m pip install -U pip
  if [ -f requirements.txt ]; then pip install -r requirements.txt || true; fi
  if [ -f pyproject.toml ]; then pip install -e . || true; fi
  if command -v uvicorn >/dev/null 2>&1 && [ -d "app" ]; then
    echo "[backend] Starting: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
    exec uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
  fi
  echo "[backend] Uvicorn app not found. Provide start command manually."
  exit 0
fi

echo "[backend] No recognizable project files found. Skipping."
