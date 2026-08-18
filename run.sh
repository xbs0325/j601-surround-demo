#!/usr/bin/env bash
# Surround-view demo on J601 (BEV + occupancy + YOLO-World + VLM caption).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"
# shellcheck disable=SC1091
source "${ROOT}/scripts/env_opencv_cuda.sh"
exec "${ROOT}/scripts/run_perception.sh" --mode nav --range 2.5 --vlm qwen3vl-2b "$@"
