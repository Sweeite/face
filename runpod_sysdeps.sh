#!/usr/bin/env bash
# System packages live on the container disk, which RunPod wipes on restart,
# so start.sh calls this too. It only runs apt when something is missing.
set -euo pipefail
if command -v ffmpeg >/dev/null && ldconfig -p | grep -q 'libGL.so.1' && ldconfig -p | grep -q 'libgthread-2.0'; then
  exit 0
fi
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ffmpeg libgl1 libglib2.0-0 build-essential curl git
