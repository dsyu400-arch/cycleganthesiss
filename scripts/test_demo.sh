#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"
CYCLEGAN_DIR="${ROOT_DIR}/pytorch-CycleGAN-and-pix2pix-src"

if [ ! -d "$VENV_DIR" ]; then
  echo "Missing .venv. Run ${ROOT_DIR}/scripts/setup.sh first." >&2
  exit 1
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

if [ ! -f "${CYCLEGAN_DIR}/test.py" ]; then
  echo "test.py not found at ${CYCLEGAN_DIR}. Ensure CycleGAN code is present." >&2
  echo "Next steps: download CycleGAN code into ${CYCLEGAN_DIR} or update scripts/test_demo.sh." >&2
  exit 1
fi

python "${CYCLEGAN_DIR}/test.py" \
  --dataroot "${ROOT_DIR}/data/horse2zebra" \
  --name horse2zebra_demo \
  --model cycle_gan \
  --phase test \
  --epoch 1 \
  --no_dropout \
  --num_test 10 \
  --results_dir "${ROOT_DIR}/outputs/horse2zebra_demo" \
  --checkpoints_dir "${ROOT_DIR}/checkpoints"
