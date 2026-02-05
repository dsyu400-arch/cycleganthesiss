#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${ROOT_DIR}/data/horse2zebra"
ZIP_PATH="${TMPDIR:-/tmp}/horse2zebra.zip"
UA="Mozilla/5.0 (macOS) CycleGAN-Downloader/1.0"

mkdir -p "${ROOT_DIR}/data"

# Mirrors (primary + at least 2 fallbacks)
URLS=(
  "https://codeload.github.com/nhatsmrt/horse2zebra/zip/refs/heads/master"
  "https://efrosgans.eecs.berkeley.edu/cyclegan/datasets/horse2zebra.zip"
  "http://efrosgans.eecs.berkeley.edu/cyclegan/datasets/horse2zebra.zip"
  "https://web.archive.org/web/https://efrosgans.eecs.berkeley.edu/cyclegan/datasets/horse2zebra.zip"
)

has_cmd() { command -v "$1" >/dev/null 2>&1; }

if has_cmd curl; then
  DOWNLOADER="curl"
elif has_cmd wget; then
  DOWNLOADER="wget"
else
  echo "Neither curl nor wget is available. Install one via Homebrew (brew install curl) or conda." >&2
  exit 1
fi

check_url() {
  local url="$1"
  if [ "$DOWNLOADER" = "curl" ]; then
    if curl -I -L --fail --max-time 10 -A "$UA" "$url" >/dev/null 2>&1; then
      return 0
    fi
    curl -L --fail --max-time 10 -A "$UA" -r 0-0 "$url" -o /dev/null >/dev/null 2>&1
  else
    wget --spider --server-response --timeout=10 "$url" >/dev/null 2>&1
  fi
}

download_url() {
  local url="$1"
  if [ "$DOWNLOADER" = "curl" ]; then
    # Fail if download speed is too low for 30s; resume if partial exists.
    curl -L --fail -A "$UA" --retry 3 --retry-delay 2 --speed-time 30 --speed-limit 10240 -C - -o "$ZIP_PATH" "$url"
  else
    wget --tries=3 --timeout=30 --continue -O "$ZIP_PATH" "$url"
  fi
}

if [ -d "${DATA_DIR}/trainA" ] && [ -d "${DATA_DIR}/trainB" ] && [ -d "${DATA_DIR}/testA" ] && [ -d "${DATA_DIR}/testB" ]; then
  echo "Dataset already present at ${DATA_DIR}"
  exit 0
fi

echo "Checking dataset mirrors..."
DOWNLOADED=0
for url in "${URLS[@]}"; do
  if check_url "$url"; then
    echo "Downloading from: $url"
    rm -f "$ZIP_PATH"
    if download_url "$url"; then
      DOWNLOADED=1
      break
    else
      echo "Download failed from: $url"
    fi
  else
    echo "Mirror not reachable: $url"
  fi
done

if [ "$DOWNLOADED" -ne 1 ]; then
  echo "All mirrors failed. Check network or try again later." >&2
  echo "Next steps: verify internet access and retry, or add a custom mirror to scripts/download_horse2zebra.sh." >&2
  exit 1
fi

if [ ! -s "$ZIP_PATH" ]; then
  echo "Downloaded zip is empty. Please retry or switch mirror." >&2
  exit 1
fi

rm -rf "$DATA_DIR"
mkdir -p "$DATA_DIR"

EXTRACT_DIR="${TMPDIR:-/tmp}/horse2zebra_extract_$$"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

if ! unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR"; then
  echo "Failed to unzip dataset. The zip may be corrupted." >&2
  exit 1
fi

# Standard CycleGAN zip contains a top-level horse2zebra directory.
if [ -d "${EXTRACT_DIR}/horse2zebra" ]; then
  mv "${EXTRACT_DIR}/horse2zebra" "$DATA_DIR"
else
  # GitHub repo zip fallback: horse2zebra-master/{horse_train,zebra_train,horse_test,zebra_test}
  ROOT_FALLBACK_DIR="$(find "$EXTRACT_DIR" -maxdepth 2 -type d -name 'horse2zebra-master' -print -quit)"
  if [ -n "$ROOT_FALLBACK_DIR" ] && [ -d "${ROOT_FALLBACK_DIR}/horse_train" ] && [ -d "${ROOT_FALLBACK_DIR}/zebra_train" ] && [ -d "${ROOT_FALLBACK_DIR}/horse_test" ] && [ -d "${ROOT_FALLBACK_DIR}/zebra_test" ]; then
    mkdir -p "${DATA_DIR}/trainA" "${DATA_DIR}/trainB" "${DATA_DIR}/testA" "${DATA_DIR}/testB"
    cp -R "${ROOT_FALLBACK_DIR}/horse_train/." "${DATA_DIR}/trainA/"
    cp -R "${ROOT_FALLBACK_DIR}/zebra_train/." "${DATA_DIR}/trainB/"
    cp -R "${ROOT_FALLBACK_DIR}/horse_test/." "${DATA_DIR}/testA/"
    cp -R "${ROOT_FALLBACK_DIR}/zebra_test/." "${DATA_DIR}/testB/"
  else
    echo "Unexpected archive structure. Expected horse2zebra/ or horse2zebra-master/horse_train, zebra_train, horse_test, zebra_test." >&2
    exit 1
  fi
fi

for split in trainA trainB testA testB; do
  if [ ! -d "${DATA_DIR}/${split}" ]; then
    echo "Missing split: ${DATA_DIR}/${split}" >&2
    exit 1
  fi
  if [ -z "$(ls -A "${DATA_DIR}/${split}" 2>/dev/null)" ]; then
    echo "Split is empty: ${DATA_DIR}/${split}" >&2
    exit 1
  fi
done

rm -f "$ZIP_PATH"
rm -rf "$EXTRACT_DIR"
echo "Download complete. Dataset ready at ${DATA_DIR}"
