# J601 Surround View Demo

**Seeed reComputer Thor J601** — four USB fisheye cameras stitched into a live bird’s-eye view (BEV), then occupancy, open-vocabulary detection, and a short English scene caption.

This repository is the **J601 product / website demo**: clone it, follow the setup below, and run `./run.sh`. It starts from the latest working Thor stack (fisheye calib + GPU stitch + perception). It is **not** a from-scratch calibration workbook.

| Role | Repository |
|------|------------|
| **J601 demo (this repo)** | Showcase surround view on reComputer J601 / JetPack R38.4 |
| Implementation path (chessboard → first stitch) | [fisheye-avm-calib](https://github.com/xbs0325/fisheye-avm-calib) |

The demo **visualizes perception only**. It does not send chassis velocity or arm joint commands.

![Surround perception: stitch + occupancy](assets/perception_bev_grasp.png)

Left: GPU stitch, ego overlay, YOLO-World boxes, English caption. Right: occupancy map (up = vehicle forward).

## What it does

Four fisheye cameras around the chassis are undistorted and warped onto a metric ground plane, then blended on GPU. From that BEV:

| Head | Job | Not used for |
|------|-----|----------------|
| **Occupancy** | Classical 2D grid (~0.2 m cells): which side looks free, how close nearby obstacles are | LiDAR SLAM / 3D map |
| **YOLO-World** | Open-vocab boxes → `base_link` `(x_m, y_m)` and a compass bin (front / front-left / …) | 6-DoF grasp pose |
| **VLM (Qwen3-VL-2B)** | Short English caption of what to watch around the vehicle | Coordinates (boxes and xy stay with YOLO) |

Image **up = vehicle forward**. `base_link` origin is roughly the BEV center: **+X forward, +Y left**.

## Hardware

- **Seeed reComputer Thor J601** (j6015), JetPack **R38.4**, Ubuntu 24.04, aarch64
- Four USB fisheye cameras (front / back / left / right)
- Optional mobile chassis with a robot arm (FOV / direction assist only)

This demo is **J601-only**. AGX Orin / J501 images and Docker are not supported here.

Default `/dev/video*` mapping (edit `config/camera_profile.json` if your cabling differs):

| Direction | Device |
|-----------|--------|
| front | `/dev/video0` |
| back | `/dev/video2` |
| left | `/dev/video3` |
| right | `/dev/video1` |

Cover the **physical front** lens: the **top** of the BEV (label F) should go dark. If front/back are swapped, change devices in the profile only — do **not** swap `calib_results/*.json`.

## Quick start (board already set up)

```bash
cd ~/j601-surround-demo
source scripts/env_opencv_cuda.sh

./run.sh       # surround demo window
./calib.sh     # optional: web calib / seam refine → http://<board-ip>:8787/
```

Do **not** run the demo and the calib web UI at the same time (cameras are exclusive).

On Thor, the local display is often `DISPLAY=:1` (not `:0`). You can open the calib page from a laptop on the same LAN.

### First-time setup

CUDA OpenCV must be **built on this Thor** (compute capability 11.0). Do not copy an Orin OpenCV tree.

```bash
cd ~/j601-surround-demo

# 1) CUDA OpenCV 4.14 (~30–90 min)
./scripts/build_opencv_cuda.sh --jobs $(nproc)
source scripts/env_opencv_cuda.sh
python3 -c "import cv2; print(cv2.__version__, cv2.cuda.getCudaEnabledDeviceCount())"
# expect: 4.14.0  1

# 2) WebRTC for calib UI (system Python, NumPy 1.x — required by CUDA OpenCV)
./scripts/install_web_deps.sh

# 3) YOLO-World + Qwen3-VL (separate venv, NumPy 2.x)
./scripts/setup_perception_thor.sh
./scripts/download_perception_models.sh

# 4) Offline smoke (no cameras)
export PYTHONPATH="$PWD${PYTHONPATH:+:$PYTHONPATH}"
python3 -m perception.smoke_offline
```

Ubuntu 24.04 is PEP 668: do **not** `pip3 install -r requirements.txt` into system Python. Keep stitch on **system Python + NumPy 1.x**; keep YOLO / VLM in `~/leucus/.venv-worldmm`. Never `import cv2` for stitching inside that venv.

Full board notes: [`docs/SETUP.md`](docs/SETUP.md). Perception contract (JSON, keys, occupancy): [`docs/PERCEPTION.md`](docs/PERCEPTION.md).

## Layout

```
j601-surround-demo/
  run.sh              Surround demo (BEV + occupancy + YOLO + VLM)
  calib.sh            Browser calib / seam refine (:8787)
  avm/                Fisheye calib + CUDA stitch
  perception/         Occupancy, YOLO-World, VLM, film UI
  config/             Camera devices, chessboard, canvas scale
  calib_results/      Intrinsics + homographies (board-specific)
  docs/SETUP.md       J601 install
```

## Keyboard (demo window)

| Key | Action |
|-----|--------|
| `ESC` / `q` | Quit |
| `o` | Run YOLO-World once |
| `a` | Run VLM caption once |
| `s` | Save frame |
| `m` | Toggle occupancy map |

Default launch is nav mode, 2.5 m range, Qwen3-VL-2B on (`./run.sh`). Examples:

```bash
./scripts/run_perception.sh --vlm off --mode nav --range 2.5
./scripts/run_perception.sh --mode grasp --target bottle
```

## License / origin

Code is the current Thor-ready snapshot of the surround pipeline. Calibration history, failed experiments, and Orin/J501 notes live in [fisheye-avm-calib](https://github.com/xbs0325/fisheye-avm-calib).
