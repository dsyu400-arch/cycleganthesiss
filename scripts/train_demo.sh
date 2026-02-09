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

if [ ! -f "${CYCLEGAN_DIR}/train.py" ]; then
  echo "train.py not found at ${CYCLEGAN_DIR}. Ensure CycleGAN code is present." >&2
  echo "Next steps: download CycleGAN code into ${CYCLEGAN_DIR} or update scripts/train_demo.sh." >&2
  exit 1
fi

python "${CYCLEGAN_DIR}/train.py" \
  --dataroot "${ROOT_DIR}/data/horse2zebra" \
  --name horse2zebra_demo \
  --model cycle_gan \
  --epoch_count 1 \
  --n_epochs 1 \
  --n_epochs_decay 0 \
  --max_dataset_size 200 \
  --num_threads 0 \
  --save_epoch_freq 1 \
  --checkpoints_dir "${ROOT_DIR}/checkpoints"
