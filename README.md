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

Output lands in `outputs/your-note.docx` and `outputs/your-note.tex`. It might need executable permissions updating `chmod +x jolpin-to-docs.sh`.

Optionally point at a different output folder:

```bash
./joplin-to-docs.sh drafts/your-note.md path/to/other-folder
```

## Citations

Write citations in your note using Pandoc's standard syntax, e.g. `[@smith2020]`
or `@smith2020`. Citekeys should match your `.bib` file exactly (Better BibTeX
citekeys from Zotero work well here).

Pass a `.bib` file as a third argument to resolve citations and generate a
bibliography in both outputs:

```bash
./joplin-to-docs.sh drafts/your-note.md outputs path/to/references.bib
```

Or set it once via an environment variable so you don't have to repeat it:

```bash
export BIBLIOGRAPHY=~/Zotero/library.bib
./joplin-to-docs.sh drafts/your-note.md
```

The Joplin [BibTeX plugin](https://joplinapp.org/plugins/plugin/com.xUser5000.bibtex/)
can insert `@citekey` references into notes directly from a `.bib` file if you
want autocomplete rather than typing keys by hand.

## Notes

- `drafts/` and `outputs/` are gitignored by default — this repo versions
  the tool, not your writing. Edit `.gitignore` if you want drafts tracked.
- The Pandoc image version is pinned in `joplin-to-docs.sh`
  (`PANDOC_IMAGE`). Bump it deliberately when you want a newer Pandoc —
  see [available tags](https://hub.docker.com/r/pandoc/latex/tags).
