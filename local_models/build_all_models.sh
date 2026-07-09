#!/usr/bin/env bash
# Build ALL custom models (alus, ropus, potus — v1..v3) into your local Ollama.
#
# Usage:
#   ./build_all_models.sh                          # build from default base (llama3.2)
#   ./build_all_models.sh --base qwen2.5:7b        # build on a different base model
#   ./build_all_models.sh --weights ~/my.gguf      # build from YOUR OWN weight file
#   ./build_all_models.sh --only ropus             # build just one family
#
# Requires: ollama (https://ollama.com) running locally.
set -euo pipefail

cd "$(dirname "$0")/modelfiles"

BASE=""
WEIGHTS=""
ONLY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)    BASE="$2"; shift 2 ;;
    --weights) WEIGHTS="$2"; shift 2 ;;
    --only)    ONLY="$2"; shift 2 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if ! command -v ollama >/dev/null 2>&1; then
  echo "ERROR: ollama not found. Install it from https://ollama.com and retry."
  exit 1
fi

if [[ -n "$WEIGHTS" ]]; then
  if [[ ! -f "$WEIGHTS" ]]; then
    echo "ERROR: weights file not found: $WEIGHTS"
    exit 1
  fi
  FROM_LINE="FROM $WEIGHTS"
elif [[ -n "$BASE" ]]; then
  FROM_LINE="FROM $BASE"
else
  FROM_LINE=""
fi

built=0
for mf in *.Modelfile; do
  name="${mf%.Modelfile}"
  if [[ -n "$ONLY" && "$name" != "$ONLY"* ]]; then
    continue
  fi
  echo "==> Building model: $name"
  if [[ -n "$FROM_LINE" ]]; then
    # Override the FROM line so the tuned parameters apply to YOUR base/weights.
    sed "s|^FROM .*|$FROM_LINE|" "$mf" | ollama create "$name" -f -
  else
    ollama create "$name" -f "$mf"
  fi
  built=$((built + 1))
done

echo
echo "Done. Built $built model(s). Run 'ollama list' to see them,"
echo "or open local_models/ui/index.html to chat with them."
