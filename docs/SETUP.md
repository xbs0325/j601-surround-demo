# J601 setup (Seeed reComputer Thor)

Platform: **Seeed reComputer j6015** · JetPack **R38.4** · Ubuntu 24.04 · aarch64.

CUDA OpenCV must be compiled **on this board**. Do not copy `~/.local/opencv-4.14.0-cuda` from AGX Orin (J501).

Commands assume user `seeed` and clone path `~/j601-surround-demo`.

## 1. CUDA OpenCV (stitch + calib)

```bash
cd ~/j601-surround-demo
./scripts/build_opencv_cuda.sh --jobs $(nproc)    # ~30–90 min
source scripts/env_opencv_cuda.sh
python3 -c "import cv2; print(cv2.__version__, cv2.cuda.getCudaEnabledDeviceCount())"
# expect: 4.14.0  1
```

On Ubuntu, CMake may install bindings into `dist-packages` (not `site-packages`). `scripts/env_opencv_cuda.sh` searches both. Re-`source` if the current shell still has an old `PYTHONPATH`.

No-camera self-check:

```bash
source scripts/env_opencv_cuda.sh
export PYTHONPATH="$PWD${PYTHONPATH:+:$PYTHONPATH}"
python3 -m perception.smoke_offline
```

## 2. Calib web deps (system Python + NumPy 1.x)

Ubuntu 24.04 forbids a bare `pip3 install` (PEP 668). The calib streamer uses **system python3** (same interpreter as CUDA OpenCV). Do **not** install these into `~/leucus/.venv-worldmm`.

```bash
sudo apt-get install -y python3-pip python3-venv
./scripts/install_web_deps.sh
```

Equivalent (for wiki copy-paste):

```bash
/usr/bin/python3 -m pip install --user --break-system-packages \
  'numpy>=1.26,<2' 'aiortc>=1.9.0' 'av>=12.0.0'
```

Pin `numpy<2` or the side-installed CUDA OpenCV will fail.

If `aiortc` is missing, `./calib.sh` prints the same install command.

## 3. Perception (YOLO-World + VLM, separate venv)

Stitch stays on system Python. Qwen3-VL and YOLO-World use a NumPy 2.x venv.

```bash
sudo apt-get install -y python3-venv python3-pip
./scripts/setup_perception_thor.sh          # torch + transformers + ultralytics + CLIP + Qwen3-VL-2B
./scripts/download_perception_models.sh     # models/perception/yolov8s-worldv2.pt
```

If `libcudss.so.0` is missing:

```bash
sudo apt-get install -y libcudss0-cuda-13
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu/libcudss/13:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

YOLO-World needs **OpenAI CLIP** (`openai-clip` + `ftfy`). A missing CLIP install shows `No module named 'clip'`. `setup_perception_thor.sh` already includes it.

| Asset | Path |
|-------|------|
| Qwen3-VL-2B | `~/leucus/models/worldmm/Qwen3-VL-2B-Instruct/` |
| YOLO-World | `~/j601-surround-demo/models/perception/yolov8s-worldv2.pt` |
| Perception venv | `~/leucus/.venv-worldmm` |

## 4. Camera indices

Devices live in `config/camera_profile.json` (keep `config/camera_config.json` in sync).

This repo’s J601 default:

| Direction | `/dev/video*` |
|-----------|----------------|
| front | 0 |
| back | 2 |
| left | 3 |
| right | 1 |

Check: cover the **front** lens → BEV **top (F)** darkens; cover the rear → bottom (B) darkens. If only front/back are wrong, swap those two devices. Do **not** edit `calib_results/*.json` to “fix” a swapped cable.

## 5. Daily run (cameras cannot be shared)

```bash
cd ~/j601-surround-demo

./run.sh      # surround demo: stitch + occupancy + YOLO + VLM caption
./calib.sh    # web UI: intrinsics / extrinsics / seam 2b
# browser: http://<board-ip>:8787/
```

| | `./run.sh` | `./calib.sh` |
|--|------------|--------------|
| Role | 360° BEV demo after calib | Browser wizard, including **2b seam** |
| Stop first | Stop calib web | Stop surround demo |

Seam refine: open **2b**, order `front+left` → `front+right` → `back+left` → `back+right`. Place the chessboard in the overlap; when both views show a green READY box, the follower homography locks. After all four pairs, Ctrl+C, then `./run.sh`.

Thor’s local window is often `DISPLAY=:1`. Use a laptop browser for calib; you do not need a browser on the board.

## Do not

- Copy Orin-built OpenCV trees onto Thor
- `import cv2` for stitching inside `~/leucus/.venv-worldmm` (NumPy conflict)
- Run demo and calib at the same time

Perception messages: [`PERCEPTION.md`](PERCEPTION.md). Stack overview: [`OVERVIEW.md`](OVERVIEW.md).
