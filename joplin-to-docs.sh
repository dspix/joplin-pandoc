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
#   ./joplin-to-docs.sh drafts/note.md custom-output-dir path/to/references.bib
#
# If a .bib file is given (or BIBLIOGRAPHY env var is set), Pandoc resolves
# @citekey references in the note and generates a bibliography using
# --citeproc. Citation keys should match your BibTeX file exactly (e.g.
# Better BibTeX citekeys from Zotero).
#
# Requires: colima running, docker CLI available (brew install colima docker)

set -euo pipefail

# Pin a specific Pandoc image version so output stays consistent over time.
# Check https://hub.docker.com/r/pandoc/latex/tags for available tags and
# update deliberately when you want to move to a newer Pandoc version.
# Using the -ubuntu stack explicitly since it's confirmed multi-arch
# (works on both Intel and Apple Silicon / arm64 Macs).
PANDOC_IMAGE="pandoc/latex:3.9.0.2-ubuntu"

# Resolve the repo root as the directory this script lives in, so paths
# work the same whether you run it from inside the repo or elsewhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/outputs"

if [ $# -lt 1 ]; then
  echo "Usage: $0 path/to/note.md [output_dir] [references.bib]" >&2
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_DIR="${2:-$DEFAULT_OUTPUT_DIR}"
BIB_FILE="${3:-${BIBLIOGRAPHY:-}}"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: file not found: $INPUT_FILE" >&2
  exit 1
fi

if [ -n "$BIB_FILE" ] && [ ! -f "$BIB_FILE" ]; then
  echo "Error: bibliography file not found: $BIB_FILE" >&2
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

# Build the extra mount + Pandoc flags for citations, only if a .bib
# file was given. The bib file's own folder gets mounted separately
# since it may live outside both the input and output directories
# (e.g. a Zotero/Better BibTeX auto-export location).
CITEPROC_ARGS=()
BIB_MOUNT_ARGS=()
if [ -n "$BIB_FILE" ]; then
  BIB_DIR="$(cd "$(dirname "$BIB_FILE")" && pwd)"
  BIB_NAME="$(basename "$BIB_FILE")"
  BIB_MOUNT_ARGS=(-v "$BIB_DIR:/bib:ro")
  CITEPROC_ARGS=(--citeproc --bibliography="/bib/$BIB_NAME")
  echo "Bibliography: $BIB_FILE"
fi

echo "Converting $INPUT_FILE ..."
echo "Output folder: $OUTPUT_DIR"

# --- Word (.docx) ---
docker run --rm \
  -v "$INPUT_DIR:/input:ro" \
  -v "$OUTPUT_DIR:/output" \
  "${BIB_MOUNT_ARGS[@]}" \
  "$PANDOC_IMAGE" \
  "/input/$INPUT_NAME" "${CITEPROC_ARGS[@]}" -o "/output/$BASE_NAME.docx"

echo "  -> $OUTPUT_DIR/$BASE_NAME.docx"

# --- LaTeX (.tex) ---
docker run --rm \
  -v "$INPUT_DIR:/input:ro" \
  -v "$OUTPUT_DIR:/output" \
  "${BIB_MOUNT_ARGS[@]}" \
  "$PANDOC_IMAGE" \
  "/input/$INPUT_NAME" "${CITEPROC_ARGS[@]}" -o "/output/$BASE_NAME.tex"

echo "  -> $OUTPUT_DIR/$BASE_NAME.tex"

echo "Done."
