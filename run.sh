#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"
source "${ROOT}/scripts/env_opencv_cuda.sh"
exec "${ROOT}/scripts/run_perception.sh" --mode nav --range 2.5 --vlm qwen3vl-2b "$@"
