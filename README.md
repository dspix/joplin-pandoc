# joplin-to-docs

Convert Joplin-exported Markdown notes to `.docx` and `.tex`, using a pinned
Pandoc Docker image (run via Colima on macOS).

## Setup

```bash
brew install colima docker
colima start
```

## Usage

```bash
git clone <your-repo-url>
cd joplin-pandoc

# Export a note from Joplin as Markdown into drafts/, then:
./joplin-to-docs.sh drafts/your-note.md
```

Output lands in `outputs/your-note.docx` and `outputs/your-note.tex`.

Optionally point at a different output folder:

```bash
./joplin-to-docs.sh drafts/your-note.md path/to/other-folder
```

## Notes

- `drafts/` and `outputs/` are gitignored by default — this repo versions
  the tool, not your writing. Edit `.gitignore` if you want drafts tracked.
- The Pandoc image version is pinned in `joplin-to-docs.sh`
  (`PANDOC_IMAGE`). Bump it deliberately when you want a newer Pandoc —
  see [available tags](https://hub.docker.com/r/pandoc/latex/tags).
