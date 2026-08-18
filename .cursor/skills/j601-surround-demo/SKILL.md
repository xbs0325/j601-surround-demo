---
name: j601-surround-demo
description: >-
  Reproduce the J601 surround-view demo on NVIDIA Thor (JetPack R38.x). Use when
  building CUDA OpenCV, fixing cv2.cuda/cudawarping, running BEV stitch, or
  perception on reComputer Thor j6015.
---

# j601-surround-demo on NVIDIA Thor

## Platform (J601 / Thor)

| Item | NVIDIA Thor (j6015) |
|------|---------------------|
| JetPack | **R38.4** |
| GPU | CC **11.0** |
| CUDA target | **sbsa-linux** |
| System OpenCV | 4.6 — **not usable** for BEV (no cudawarping) |
| Side OpenCV | `~/.local/opencv-4.14.0-cuda` — **must rebuild on Thor** |
| Display | Thor GDM often **`:1`** |

**Do not copy** Orin-built `~/.local/opencv-4.14.0-cuda` to Thor — CUDA arch differs.

Full install steps: [`docs/SETUP.md`](../../docs/SETUP.md).

## Mandatory: CUDA OpenCV side install

Project hot path needs `cv2.cuda.remap`, `cv2.cuda.warpPerspective`, `cv2.cuda.multiply`.

```bash
cd ~/j601-surround-demo
./scripts/build_opencv_cuda.sh --jobs $(nproc)   # 30–90 min first time
source scripts/env_opencv_cuda.sh
python3 -c "import cv2; print(cv2.__version__, cv2.cuda.getCudaEnabledDeviceCount())"
# expect: 4.14.0 … devices: 1
```

Build script auto-detects Thor → `CUDA_ARCH_BIN=11.0`.

## Run order (reproduce without cameras first)

```bash
source scripts/env_opencv_cuda.sh
export PYTHONPATH="$PWD${PYTHONPATH:+:$PYTHONPATH}"

# 1) Logic smoke (no camera, no GPU OpenCV)
python3 -m perception.smoke_offline

# 2) CUDA check
python3 -c "from avm.cuda_cv import log_cuda_status; log_cuda_status()"

# 3) Surround demo (needs cameras + calib JSON)
./run.sh

# 4) Calib web (exclusive with demo)
./calib.sh --host 0.0.0.0 --port 8787
```

## Cameras on Thor

- Profile: `config/camera_profile.json` — device indices are board-specific.
- After wiring cameras, probe: `python3 -m avm.camera_io` or Web **Probe** at `:8787`.
- No `/dev/video*` → hardware/driver not ready; offline smoke still passes.

## Perception / VLM

```bash
./scripts/setup_perception_thor.sh
./scripts/download_perception_models.sh
./run.sh   # nav mode, 2.5 m range, qwen3vl-2b
```

- YOLO-World + VLM use `PERCEPTION_VENV` / `PERCEPTION_MODELS` (default under `~/leucus`).
- NumPy split: **system Python + CUDA OpenCV → NumPy 1.x**; VLM subprocess → NumPy 2.x in venv.
- Live try needs `/dev/video*` + calib JSON. No cameras → `--vlm off` via `./scripts/run_perception.sh`.
- `libcudss.so.0` missing → `sudo apt-get install -y libcudss0-cuda-13`.

## Common failures

| Symptom | Fix |
|---------|-----|
| `CUDA=OFF`, `cudawarping unavailable` | Rebuild side OpenCV; `source scripts/env_opencv_cuda.sh` |
| `import cv2` loads `/usr/lib/.../cv2` | `PYTHONPATH` must prepend side-install site-packages |
| Web refuses stream | `cuda_available()` false — fix OpenCV first |
| `cannot open display` | `DISPLAY=:1`, `XAUTHORITY=/run/user/$(id -u)/gdm/Xauthority` |

## Files to touch for Thor-only changes

- `scripts/build_opencv_cuda.sh` — OpenCV build
- `scripts/env_opencv_cuda.sh` — env / prefix detection
- `config/camera_profile.json` — device indices
- `docs/SETUP.md` — board install (this skill mirrors it)

**Do not modify** calibration math in `avm/calibrate_*.py` for platform port.

Implementation workbook (from-scratch calib history): [fisheye-avm-calib](https://github.com/xbs0325/fisheye-avm-calib).
