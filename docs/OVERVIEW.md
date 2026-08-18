# Surround view: scene and stack (J601)

Four fisheye cameras on a mobile chassis (optional arm) are stitched into a 360° top-down ground view (BEV) for driving assist, grasp *direction*, and a short English scene caption. This demo **visualizes perception only** — it does not send chassis or arm commands.

**Platform:** Seeed reComputer Thor **J601** (j6015), JetPack R38.4.

```
Front / back / left / right fisheye
        │
        ▼
  Fisheye intrinsics + homographies (H)
        │
        ▼
  GPU undistort → ground BEV stitch
        │
        ├── Occupancy: which side looks free, nearby obstacle distance
        ├── YOLO-World: bottle / chair / carton / … → base_link (x, y)
        └── Qwen3-VL: two or three English sentences of what to watch
```

| Use | How BEV is used | Output |
|-----|-----------------|--------|
| Surround showcase | Four cameras → one top-down image | Live window: stitch left, occupancy right |
| Nav assist | Ground 2D occupancy, not a lidar map | `free` ratio, nearest F/B/L/R distance |
| Grasp direction | Open-vocab box center | `base_link` `(x_m, y_m)` and azimuth |
| VLM assist | Caption the stitch | Short English text, not a coordinate source |

Convention: image **up = vehicle forward**; `base_link` origin ≈ BEV center, **+X forward, +Y left**. IPM assumes a ground plane (no depth), so poses are 2D on the floor, not 6-DoF grasps.

## Stack

| Layer | Tech | Role |
|-------|------|------|
| Hardware | reComputer Thor J601 · four USB fisheye + CUDA | Capture |
| Calib | OpenCV `fisheye` + chessboard SB detect + `findHomography` | K/D, H (undistorted → BEV) |
| Stitch hot path | CUDA OpenCV 4.14 (`cudawarping`) | GPU `remap` / `warpPerspective` / blend |
| Calib UI | Python web + WebRTC (aiortc) | Intrinsics → extrinsics → seam 2b |
| Occupancy | Classical BEV appearance (no seg net) | Floor vs object → 0.2 m grid |
| Detect | Ultralytics YOLO-World v2 (`yolov8s-worldv2`) | Open-vocab boxes; BEV imgsz=384 |
| Language | Qwen3-VL-2B (own venv, Transformers) | Caption only |
| Ego overlay | `assets/ego_overlay.png` | Covers the center stitch hole |

Split of labor (do not mix):

- **Occupancy** = space (free / occupied)
- **YOLO-World** = boxes and `xy`
- **VLM** = short description for a human

Stitch uses **system Python + NumPy 1.x + CUDA OpenCV**. YOLO / VLM use a separate venv (NumPy 2.x). Do not mix the two interpreters.

## Run (after calib)

```bash
source scripts/env_opencv_cuda.sh
./run.sh          # surround demo
./calib.sh        # http://<board-ip>:8787/
```

Demo and calib are mutually exclusive (cameras). Details: [`SETUP.md`](SETUP.md), [`PERCEPTION.md`](PERCEPTION.md).

## Out of scope

- Chassis velocity or arm joint commands
- Occupancy as SLAM / 3D mapping
- Parsing VLM sentences into coordinates (trust YOLO for `xy`)
- Real-time stitch without CUDA (`--allow-cpu` is debug-only)
- AGX Orin / J501 as a first-class target (see [fisheye-avm-calib](https://github.com/xbs0325/fisheye-avm-calib) for the from-scratch / multi-board workbook)
