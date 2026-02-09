# CycleGAN Thesis Skeleton

This repo provides a minimal, reproducible project skeleton for a CycleGAN thesis demo.

## 0) Prerequisites (macOS)
- Python 3.9+ (recommended via Homebrew: `brew install python`)
- Optional: conda (if you prefer `conda create -n cyclegan python=3.10`)

## 1) Create venv + install deps
```bash
./scripts/setup.sh
```

## 2) Download horse2zebra dataset
```bash
./scripts/download_horse2zebra.sh
```
Dataset will be placed at `data/horse2zebra/{trainA,trainB,testA,testB}`.

## 3) Add CycleGAN code
This skeleton expects `train.py` and `test.py` in the repo root.
If you’re using the official PyTorch implementation, place its files here.

## 4) Train 1 epoch (demo)
```bash
./scripts/train_demo.sh
```
Checkpoints will be written under `checkpoints/horse2zebra_demo`.

## 5) Test and export results
```bash
./scripts/test_demo.sh
```
Results will be written to `outputs/horse2zebra_demo/`.

## Folder layout
```
.
├── scripts/
├── data/
├── outputs/
├── checkpoints/
└── notebooks/
```

## Notes
- If you use conda, activate it before running scripts, or skip `scripts/setup.sh`.
- If a dataset mirror is unavailable, the download script will fall back automatically.
