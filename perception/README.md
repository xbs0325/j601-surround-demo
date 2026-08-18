# Perception (BEV occupancy + YOLO-World + VLM)

J601 surround demo: GPU BEV for 360° context, **YOLO-World** for `base_link` `(x_m, y_m)`, occupancy for a 2D free-space hint, **Qwen3-VL** for an English caption. No chassis or arm commands.

![Perception BEV](../assets/perception_bev_grasp.png)

Default: occupancy on the stitched BEV (calibration code is not modified). Grasp mode uses YOLO-World v2 (open-vocab boxes → metric `x, y`). While weights load, stitch falls back to CPU so the video does not freeze, then CUDA resumes.

```bash
./scripts/download_perception_models.sh

./scripts/run_perception.sh --vlm off --mode nav --range 2.5
./scripts/run_perception.sh --mode grasp --target bottle
./scripts/run_perception.sh --mode nav --range 2.5 --vlm qwen3vl-2b

python3 -m perception.smoke_offline
```

Or just `./run.sh` from the repo root.

Full contract (JSON, coordinates, keys): [`docs/PERCEPTION.md`](../docs/PERCEPTION.md).
