#!/usr/bin/env bash
# One-time setup on any RunPod PyTorch pod. Safe to re-run.
#   cd /workspace && git clone https://github.com/Sweeite/face.git && cd face && bash runpod_setup.sh
#
# Builds its own Python 3.10 + CUDA 11.8 environment in /workspace/venv, so it
# doesn't matter which Python/CUDA the pod template ships with, and it survives
# pod restarts (only /workspace is kept).
set -euo pipefail
cd "$(dirname "$0")"

VENV=/workspace/venv
export UV_INSTALL_DIR=/workspace/.uv/bin
export UV_PYTHON_INSTALL_DIR=/workspace/.uv/python
export UV_CACHE_DIR=/workspace/.uv/cache
export PIP_CACHE_DIR=/workspace/.cache/pip

echo "==> System packages"
bash ./runpod_sysdeps.sh

echo "==> Python 3.10 environment in $VENV"
if [ ! -x "$UV_INSTALL_DIR/uv" ]; then
  curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
fi
if [ ! -x "$VENV/bin/python" ]; then
  "$UV_INSTALL_DIR/uv" venv --seed --python 3.10 "$VENV"
fi
PY="$VENV/bin/python"
"$PY" -m pip install --upgrade "pip<25" wheel "setuptools<70"

echo "==> PyTorch (CUDA 11.8)"
"$PY" -m pip install torch==2.1.2 torchvision==0.16.2 --index-url https://download.pytorch.org/whl/cu118

echo "==> App packages"
"$PY" -m pip install -r requirements-runpod.txt

echo "==> GPU runtime for onnxruntime (CUDA 11.8 / cuDNN 8)"
"$PY" -m pip uninstall -y onnxruntime >/dev/null 2>&1 || true
"$PY" -m pip install onnxruntime-gpu==1.15.1 \
  "nvidia-cudnn-cu11<9" nvidia-cublas-cu11 nvidia-cufft-cu11 nvidia-curand-cu11 nvidia-cuda-runtime-cu11

echo "==> Patch basicsr for torchvision"
BASICSR_DEG=$("$PY" -c 'import importlib.util as u, os; s=u.find_spec("basicsr"); print(os.path.join(os.path.dirname(s.origin), "data", "degradations.py"))')
sed -i 's/torchvision.transforms.functional_tensor/torchvision.transforms.functional/' "$BASICSR_DEG"

source ./runpod_env.sh

echo "==> Downloading models"
python - <<'EOF'
import roop.processors.frame.face_swapper as swapper
import roop.processors.frame.face_enhancer as enhancer
assert swapper.pre_check(), "face swapper model download failed"
assert enhancer.pre_check(), "face enhancer model download failed"
import opennsfw2
opennsfw2.make_open_nsfw_model()
print("models ready")
EOF

echo "==> Checking the GPU is used"
python - <<'EOF'
import torch, onnxruntime as ort
session = ort.InferenceSession("models/inswapper_128.onnx", providers=["CUDAExecutionProvider", "CPUExecutionProvider"])
active = session.get_providers()[0]
print("GPU:", torch.cuda.get_device_name(0) if torch.cuda.is_available() else "none")
print("onnxruntime is using:", active)
if active != "CUDAExecutionProvider":
    print("WARNING: running on CPU - swaps will be slow. RTX 50-series / B200 cards are not supported by CUDA 11.8.")
EOF

mkdir -p /workspace/outputs
echo
echo "Setup complete. Start the app with:  bash start.sh --bg"
