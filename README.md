# Face Swap

Gradio web app built on [roop](https://github.com/s0md3v/roop): swap a source face into one target image or a batch of them. Targets flagged as explicit are refused.

## Run on RunPod

1. **Deploy a pod** with the **RunPod PyTorch 2.4.0** template (Python 3.11). Any NVIDIA GPU works; an RTX 4090 or A40 is plenty.
2. **Edit the template** before deploying:
   - Expose HTTP port: `7860`
   - Volume mount path: `/workspace` (outputs and the code persist across restarts)
3. **Open the pod's Web Terminal** (Connect → Start Web Terminal) and paste:

   ```bash
   cd /workspace && git clone https://github.com/Sweeite/face.git && cd face && bash runpod_setup.sh && bash start.sh --bg
   ```

   Setup takes about 5–10 minutes. At the end it prints which GPU it found and whether onnxruntime is using `CUDAExecutionProvider`.
4. **Open the app**: Connect → HTTP Service [Port 7860].

Results are saved on the pod in `/workspace/outputs` as `a1.jpg`, `a2.jpg`, …

### After a pod restart

```bash
cd /workspace/face && bash start.sh --bg
```

### Update to the latest code

```bash
cd /workspace/face && git pull && bash start.sh --bg
```

Stop the app with `pkill -f app.py`; see its log with `tail -f /workspace/face/app.log`.
