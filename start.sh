#!/usr/bin/env bash
# Starts the web app on port 7860. Open it from RunPod: Connect -> HTTP Service [7860].
#   bash start.sh          run in this terminal (Ctrl+C stops it)
#   bash start.sh --bg     keep running after you close the terminal; log in app.log
set -euo pipefail
cd "$(dirname "$0")"
source ./runpod_env.sh
mkdir -p /workspace/outputs

if [ "${1:-}" = "--bg" ]; then
  nohup python app.py > app.log 2>&1 &
  echo "Running in background (pid $!). Log: $(pwd)/app.log"
else
  exec python app.py
fi
