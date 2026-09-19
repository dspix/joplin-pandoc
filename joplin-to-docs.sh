#!/usr/bin/env bash
#
# joplin-to-docs.sh — Convert a Joplin-exported Markdown note to .docx and .tex
# using a pinned Pandoc Docker image (via Colima).
#
# Expects to live in a repo structured like:
#   repo/
#   ├── joplin-to-docs.sh
#   ├── drafts/     (put exported .md files here)
#   └── outputs/    (converted .docx / .tex land here)
#
# Usage (from anywhere, paths resolve relative to the script's own location):
#   ./joplin-to-docs.sh drafts/note.md
#   ./joplin-to-docs.sh drafts/note.md custom-output-dir
#
# Requires: colima running, docker CLI available (brew install colima docker)

set -euo pipefail

# Pin a specific Pandoc image version so output stays consistent over time.
# Check https://hub.docker.com/r/pandoc/latex/tags for available tags and
# update deliberately when you want to move to a newer Pandoc version.
PANDOC_IMAGE="pandoc/latex:3.1.11"

# Resolve the repo root as the directory this script lives in, so paths
# work the same whether you run it from inside the repo or elsewhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/outputs"

if [ $# -lt 1 ]; then
  echo "Usage: $0 path/to/note.md [output_dir]" >&2
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_DIR="${2:-$DEFAULT_OUTPUT_DIR}"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: file not found: $INPUT_FILE" >&2
  exit 1
fi

# Create the output directory if it doesn't exist yet.
mkdir -p "$OUTPUT_DIR"

# Resolve absolute paths, since Docker needs absolute host paths to mount
# as volumes. Input and output live in different folders, so each gets
# its own mount.
INPUT_DIR="$(cd "$(dirname "$INPUT_FILE")" && pwd)"
INPUT_NAME="$(basename "$INPUT_FILE")"
BASE_NAME="${INPUT_NAME%.*}"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

echo "Converting $INPUT_FILE ..."
echo "Output folder: $OUTPUT_DIR"

# --- Word (.docx) ---
docker run --rm \
  -v "$INPUT_DIR:/input:ro" \
  -v "$OUTPUT_DIR:/output" \
  "$PANDOC_IMAGE" \
  "/input/$INPUT_NAME" -o "/output/$BASE_NAME.docx"

echo "  -> $OUTPUT_DIR/$BASE_NAME.docx"

# --- LaTeX (.tex) ---
docker run --rm \
  -v "$INPUT_DIR:/input:ro" \
  -v "$OUTPUT_DIR:/output" \
  "$PANDOC_IMAGE" \
  "/input/$INPUT_NAME" -o "/output/$BASE_NAME.tex"

echo "  -> $OUTPUT_DIR/$BASE_NAME.tex"

echo "Done."
