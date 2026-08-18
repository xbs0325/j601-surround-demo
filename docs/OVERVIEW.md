# Surround view: scene and stack

Four fisheye cameras on a mobile chassis (optional robot arm) feed a single metric bird’s-eye view (BEV) for driving and manipulation assist. This stage **visualizes perception only** — no chassis or arm control commands.

## Scene

```
Four fisheye cameras (front / back / left / right)
        │
        ▼
  Fisheye intrinsics + extrinsics (homography H)
        │
        ▼
  GPU undistort → ground BEV stitch
        │
        ├── Occupancy: free space vs obstacles on the floor plane
        ├── YOLO-World: open-vocab boxes → base_link (x, y)
        └── VLM: short English caption of the scene
```

| Use | How BEV is used | Output |
|-----|-----------------|--------|
| Surround display | Four views fused to one top-down image | Live window: stitch + occupancy map |
| Nav assist | 2D ground occupancy (not a lidar map) | `free` ratio, nearest obstacle per side |
| Grasp direction | Open-vocabulary target detection | `(x_m, y_m)` and compass bin (front / front-left / …) |
| VLM assist | Reads the stitched frame | Short English caption — not metric ground truth |

**Image up = vehicle forward.** `base_link` origin is near the BEV center: **+X forward, +Y left**. IPM assumes a flat ground plane; without depth, only 2D ground pose is available (not 6-DoF grasp).

## Perception split

- **Occupancy** — spatial hint (where looks walkable / blocked)
- **YOLO-World** — object boxes and `(x_m, y_m)`
- **VLM (Qwen3-VL-2B)** — human-readable scene language; coordinates come from YOLO only

## Technology

| Layer | Technology | Role |
|-------|------------|------|
| Hardware | Seeed reComputer Thor j6015 (JetPack R38.4) | Four USB fisheye + CUDA |
| Calibration | OpenCV fisheye + chessboard + homography | K/D intrinsics, H extrinsics |
| Stitch hot path | Side-built CUDA OpenCV 4.14 (`cudawarping`) | GPU remap / warp / blend |
| Calib UI | Python Web + WebRTC (aiortc) | Intrinsics → extrinsics → seam 2b |
| Occupancy | Classical BEV appearance model | ~0.2 m grid vs floor appearance |
| Detection | Ultralytics YOLO-World v2 | Open-vocab boxes; BEV imgsz=384 |
| Semantics | Qwen3-VL-2B (separate venv) | Caption only |
| Ego overlay | `assets/ego_overlay.png` | Covers center stitch blind zone |

## Software layout

```
j601-surround-demo/
  run.sh / calib.sh   Entrypoints
  avm/                Calib + GPU stitch
  perception/         Occupancy, YOLO, VLM, demo UI
  config/             Camera profile, chessboard, canvas
  calib_results/      Intrinsics + H (board-specific)
  docs/SETUP.md       Thor install
```

Stitch uses **system Python + NumPy 1.x + CUDA OpenCV**. YOLO and VLM use a separate venv (NumPy 2.x). Do not mix interpreters.

## Run (after calibration)

```bash
source scripts/env_opencv_cuda.sh
./run.sh          # BEV + occupancy + YOLO + VLM
./calib.sh        # Web UI  http://<board-ip>:8787/
```

Demo and calib are **mutually exclusive** (same cameras). Perception details: [`PERCEPTION.md`](PERCEPTION.md). Board setup: [`SETUP.md`](SETUP.md).

## Out of scope

- Chassis velocity or arm joint commands
- SLAM / 3D mapping from the occupancy grid
- Parsing VLM text into coordinates
- Real-time stitch without CUDA (use `--allow-cpu` for debug only)
