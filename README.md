# J601 Surround View Demo

**Seeed reComputer Thor J601** — four USB fisheye cameras stitched into a live bird’s-eye view (BEV), then occupancy, open-vocabulary detection, and a short English scene caption.

This repository is the **J601 product / website demo**: clone it, follow the setup below, and run `./run.sh`. It ships the latest working Thor stack (GPU stitch + perception) in a **lean** layout. It is **not** a from-scratch calibration workbook.

| Role | Repository |
|------|------------|
| **J601 demo (this repo)** | Showcase surround view on reComputer J601 / JetPack R38.4 |
| Implementation path (chessboard → first stitch, lab notes) | [fisheye-avm-calib](https://github.com/xbs0325/fisheye-avm-calib) |

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

**J601 / Thor only.** Orin, Docker, and J501 paths are intentionally omitted from this repo.

Default `/dev/video*` mapping (edit `config/camera_profile.json` if your cabling differs):

| Direction | Device |
|-----------|--------|
| front | `/dev/video0` |
| back | `/dev/video2` |
| left | `/dev/video3` |
| right | `/dev/video1` |

Cover the **physical front** lens: the **top** of the BEV (label F) should go dark. If front/back are swapped, change devices in the profile only — do **not** swap `calib_results/*.json`.

## Quick start

```bash
cd ~/j601-surround-demo

# First time on a fresh board (see docs/SETUP.md for detail):
./scripts/build_opencv_cuda.sh --jobs $(nproc)
source scripts/env_opencv_cuda.sh
./scripts/install_web_deps.sh
./scripts/setup_perception_thor.sh
./scripts/download_perception_models.sh

./run.sh       # surround demo window
./calib.sh     # optional: web calib / seam refine → http://<board-ip>:8787/
```

Do **not** run the demo and the calib web UI at the same time (cameras are exclusive).

On Thor, the local display is often `DISPLAY=:1` (not `:0`). You can open the calib page from a laptop on the same LAN.

Ubuntu 24.04 is PEP 668: do **not** `pip3 install -r requirements.txt` into system Python. Keep stitch on **system Python + NumPy 1.x**; keep YOLO / VLM in `~/leucus/.venv-worldmm`. Never `import cv2` for stitching inside that venv.

Full board notes: [`docs/SETUP.md`](docs/SETUP.md). Stack overview: [`docs/OVERVIEW.md`](docs/OVERVIEW.md). Perception contract: [`docs/PERCEPTION.md`](docs/PERCEPTION.md).

## Cursor agents

For automated bring-up on Thor, see [`.cursor/skills/j601-surround-demo/SKILL.md`](.cursor/skills/j601-surround-demo/SKILL.md).

## Layout (lean)

| Path | Description |
|------|-------------|
| `run.sh` / `calib.sh` | Surround demo and browser calib entrypoints |
| `avm/` | Fisheye calib + CUDA stitch (Web / CLI) |
| `perception/` | BEV occupancy, YOLO-World, VLM, demo UI |
| `demo_bev_vlm/` | Stitch helpers used by `perception/run.py` |
| `config/` | Camera devices, chessboard, canvas scale |
| `calib_results/` | Intrinsics + homographies (board-specific) |
| `scripts/` | Thor build, env, perception launchers |
| `docs/` | SETUP, OVERVIEW, PERCEPTION (English) |
| `.cursor/skills/j601-surround-demo/` | Cursor skill for Thor reproduction |

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

## Version

**1.0.0** — lean Thor promo repo from the v0.3.0 stack. See [`CHANGELOG.md`](CHANGELOG.md).

## License / origin

Code is the current Thor-ready snapshot of the surround pipeline. Calibration history, Orin notes, and Docker assets live in [fisheye-avm-calib](https://github.com/xbs0325/fisheye-avm-calib).
