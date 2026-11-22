#!/usr/bin/env bash
# One-time setup on a RunPod PyTorch pod. Safe to re-run.
#   cd /workspace && git clone https://github.com/Sweeite/face.git && cd face && bash runpod_setup.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> System packages"
PYV=$(python -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')
apt-get update -y
apt-get install -y --no-install-recommends ffmpeg libgl1 libglib2.0-0 build-essential python3-tk
apt-get install -y --no-install-recommends "python${PYV}-tk" 2>/dev/null || true

echo "==> Python packages (keeping the pod's own torch)"
python -m pip install --upgrade pip wheel setuptools
python -m pip install -r requirements-runpod.txt

echo "==> GPU runtime for onnxruntime"
CUDA_MAJOR=$(python -c 'import torch; print((torch.version.cuda or "12").split(".")[0])')
python -m pip uninstall -y onnxruntime onnxruntime-gpu >/dev/null 2>&1 || true
if [ "$CUDA_MAJOR" = "11" ]; then
  python -m pip install onnxruntime-gpu==1.15.1
else
  # cuDNN/cuBLAS usually come with the pod's torch; this only fills gaps, never upgrades.
  python -m pip install onnxruntime-gpu==1.20.1 nvidia-cudnn-cu12 nvidia-cublas-cu12 nvidia-cufft-cu12 nvidia-curand-cu12
fi
echo "    torch CUDA ${CUDA_MAJOR}.x detected"

echo "==> Patch basicsr for newer torchvision"
BASICSR_DEG=$(python -c 'import importlib.util as u, os; s=u.find_spec("basicsr"); print(os.path.join(os.path.dirname(s.origin), "data", "degradations.py"))')
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
    print("WARNING: running on CPU - swaps will be slow")
EOF

mkdir -p /workspace/outputs
echo
echo "Setup complete. Start the app with:  bash start.sh"
