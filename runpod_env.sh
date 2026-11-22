# Sourced by runpod_setup.sh and start.sh.
# Uses the app's own Python in /workspace/venv and puts the CUDA/cuDNN
# libraries that came with pip on the loader path for onnxruntime-gpu.
export PATH="/workspace/venv/bin:$PATH"
NV_LIBS=$(python - <<'EOF'
import glob, os, site
dirs = []
for sp in site.getsitepackages():
    dirs += glob.glob(os.path.join(sp, "nvidia", "*", "lib"))
print(":".join(dirs))
EOF
)
export LD_LIBRARY_PATH="${NV_LIBS}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export TF_CPP_MIN_LOG_LEVEL=2
export GRADIO_ANALYTICS_ENABLED=False
