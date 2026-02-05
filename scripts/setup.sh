#!/usr/bin/env bash
set -euo pipefail

# Create and activate a local venv, then install dependencies.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"

pick_python() {
  local candidates=(
    "${CYCLEGAN_PYTHON:-}"
    "/opt/homebrew/bin/python3"
    "/usr/bin/python3"
    "/usr/local/bin/python3"
    "python3"
  )
  for candidate in "${candidates[@]}"; do
    if [ -n "$candidate" ] && command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" - <<'PY' >/dev/null 2>&1
import sys
sys.exit(0 if ("Anaconda" not in sys.version and "conda" not in sys.version.lower()) else 1)
PY
      then
        echo "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

PYTHON_BIN="$(pick_python || true)"
if [ -z "$PYTHON_BIN" ]; then
  echo "No suitable python3 found (non-conda). Install via Homebrew: brew install python" >&2
  exit 1
fi

if [ -d "$VENV_DIR" ] && [ -x "${VENV_DIR}/bin/python" ]; then
  if [ "${CYCLEGAN_FORCE_RECREATE:-}" = "1" ]; then
    TS="$(date +%s)"
    echo "Forcing venv recreation. Moving existing venv to ${VENV_DIR}.bak.${TS}"
    mv "$VENV_DIR" "${VENV_DIR}.bak.${TS}"
  fi
fi

if [ -d "$VENV_DIR" ] && [ -x "${VENV_DIR}/bin/python" ]; then
  if "${VENV_DIR}/bin/python" - <<'PY' >/dev/null 2>&1
import sys
sys.exit(0 if ("Anaconda" not in sys.version and "conda" not in sys.version.lower()) else 1)
PY
  then
    echo "Using existing venv at ${VENV_DIR}"
  else
    TS="$(date +%s)"
    echo "Existing venv appears to be conda-based. Moving it to ${VENV_DIR}.bak.${TS}"
    mv "$VENV_DIR" "${VENV_DIR}.bak.${TS}"
  fi
fi

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating venv at ${VENV_DIR} with ${PYTHON_BIN}"
  if ! "$PYTHON_BIN" -m venv "$VENV_DIR"; then
    echo "venv creation failed (ensurepip). Trying fallback without pip..." >&2
    if ! "$PYTHON_BIN" -m venv --without-pip "$VENV_DIR"; then
      echo "Failed to create venv. Please check your Python installation." >&2
      exit 1
    fi
  fi
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

if ! python -m pip --version >/dev/null 2>&1; then
  echo "pip not found in venv. Installing pip..." >&2
  if command -v curl >/dev/null 2>&1; then
    TMP_PIP="${TMPDIR:-/tmp}/get-pip.py"
    curl -L --fail -o "$TMP_PIP" https://bootstrap.pypa.io/get-pip.py
    python "$TMP_PIP"
    rm -f "$TMP_PIP"
  else
    echo "curl not available to bootstrap pip. Install curl via Homebrew or conda." >&2
    exit 1
  fi
fi

if ! python -m pip install --upgrade pip; then
  echo "pip upgrade failed. If you are using python.org builds, run Install Certificates.command, or set CYCLEGAN_PYTHON=/usr/bin/python3 and re-run." >&2
  exit 1
fi
if ! python -m pip install -r "${ROOT_DIR}/requirements.txt"; then
  echo "Dependency install failed. Check your SSL certificates or internet access." >&2
  exit 1
fi

echo "Setup complete. Activate with: source ${VENV_DIR}/bin/activate"
