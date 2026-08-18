# Perception

360° GPU BEV with **occupancy**, **YOLO-World** localization, and optional **Qwen3-VL-2B** captions. Visualization only — no chassis or arm commands. Calibration math lives under `avm/`; this doc covers `perception/` and launch scripts.

![Perception BEV](../assets/perception_bev_grasp.png)

## Quick run

```bash
cd ~/j601-surround-demo
source scripts/env_opencv_cuda.sh
./scripts/download_perception_models.sh   # first time

./run.sh
./scripts/run_perception.sh --vlm off --mode nav --range 2.5
./scripts/run_perception.sh --mode grasp --target bottle
./scripts/run_perception.sh --no-window
python3 -m perception.smoke_offline
```

Artifacts: `output/perception/preview.jpg`, `events.jsonl`.

**Occupancy:** metric BEV cells (default 0.2 m). Lower `--occ-thresh` = more sensitive. YOLO boxes are merged into the grid. Red cells = occupied; right panel is a top-down map (up = forward). Toggle with `m`; disable with `--no-occ-map`.

**YOLO-World:** open vocabulary (bottle, chair, phone, …). `--target` selects the grasp candidate; other detections still draw on the BEV. Box center → `base_link` `(x_m, y_m)`. Weights load on CPU briefly so the video loop keeps running, then CUDA stitch resumes.

## Coordinate frame

| Quantity | Convention |
|----------|------------|
| Image | `u` right, `v` down; **up = vehicle forward** |
| `base_link` | Origin ≈ BEV center; **+X forward, +Y left** |
| Scale | `s = scale_px_per_meter` (`--scale`; match `calib_results/extrinsics.json` when possible) |
| Pixel → meters | `x_m = (cy - v) / s`, `y_m = (cx - u) / s` |
| `frame_id` | Always `"base_link"` |
| Schema | `schema_version: 1` |

IPM is a ground-plane approximation — 2D ground pose only. VLM output is assistive language, not detector-grade geometry.

## Keyboard

| Key | Action |
|-----|--------|
| `ESC` / `q` | Quit |
| `o` | YOLO-World once |
| `a` | VLM once |
| `s` | Save frame |
| `m` | Toggle occupancy map |

Ego overlay: `python3 scripts/make_ego_overlay.py topdown.jpg -o assets/ego_overlay.png` (optional `--ego-size-m` for fixed metric size).

## JSON schema (summary)

All messages include `schema_version`, `frame_id`, `stamp_s`, `mode`, `valid`, `infer_ms`, and `summary`.

**nav** — adds `nav.obstacles[]` (label, azimuth, normalized u/v, conf, `x_m`, `y_m`, `radius_m`), plus `nav.free_dirs` and `nav.uncertain`.

**grasp** — adds `grasp.turn_hint`, `grasp.targets[]` (label, azimuth, u/v, conf, `graspable`, `x_m`, `y_m`, `yaw_deg`, `range_m`), `grasp.best_target_id`, `grasp.notes`. `yaw_deg` is computed from geometry (0 = forward; positive = left).

On parse failure: `valid=false`, `error` set, stitch continues.

In-process bus: `perception.bus.PerceptionBus` (`publish` / `latest` / `subscribe`). Fields map 1:1 to a future ROS 2 publisher.

## Thor checklist

- [ ] `source scripts/env_opencv_cuda.sh` — CUDA OpenCV 4.14 with cudawarping
- [ ] `config/camera_profile.json` matches `/dev/video*`
- [ ] `PERCEPTION_VENV_PYTHON` and `PERCEPTION_MODELS` (see [`SETUP.md`](SETUP.md))
- [ ] `calib_results/{front,back,left,right,extrinsics}.json` present
- [ ] `python3 -m perception.smoke_offline` passes
- [ ] `./scripts/run_perception.sh --vlm off` with live cameras
- [ ] VLM on: `./run.sh` or `--vlm qwen3vl-2b`; check `infer_ms` in HUD / `events.jsonl`

## Module map

| Path | Role |
|------|------|
| `perception/occupancy.py` | BEV → occupancy grid |
| `perception/schema.py` | JSON schema + prompts |
| `perception/localize.py` | Pixels → meters |
| `perception/vlm_worker.py` / `vlm_client.py` | Async Qwen3-VL subprocess |
| `perception/viz.py` / `run.py` | Overlay + main loop |
| `scripts/run_perception.sh` | Env + launch |
