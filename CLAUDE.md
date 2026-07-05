# ECE Bachelor Thesis

This repo is a **bachelor's thesis document** for the Electronics and Computer
Engineering (ECE) programme at FH JOANNEUM, written in
[Typst](https://typst.app) instead of LaTeX/Word. It's built on the
`typst-ECE-template` (this branch, `salloker`, is the "clean" variant without
the extra visual header aids). The content chapters are currently placeholder
text — this is thesis infrastructure/scaffolding, not a finished document.

## Toolchain

- **Typst**, compiled via the VSCode **Tinymist** extension (no Typst CLI
  installed on this machine — compile/preview through the editor).
- Package manifest: [typst.toml](typst.toml) — entrypoint is
  `iee-template.typ`.
- Recommended font: "Latin Modern Roman" (for the original IEE LaTeX look).
  See README.md for the download link.

## Structure

- [main.typ](main.typ) — the actual document entrypoint. Imports the template
  and helpers, fills in thesis metadata (title, author, supervisors, program,
  language), and `#include`s the frontmatter/chapters/bibliography in order.
- [iee-template.typ](iee-template.typ) — the template engine itself
  (`iee-thesis(...)` function). Defines page layout, title page, per-chapter
  numbering, headings, TOC/list-of-figures/tables/equations/listings,
  glossary wiring, and colors. Ported from the original LaTeX IEE template
  (`Mayer Florian`) and an IIT Typst template.
- [helpers/lib.typ](helpers/lib.typ) — reusable content helpers: `blue-box`,
  `quote`/`directquote`, `fhjcode` (numbered code blocks), `textit`/`textbf`
  macros, `fhjtable` (CSV → styled table), `fhjrevisionmark`, and a
  `flowchart`/`fnode`/`fdecision`/`fedge` mini-DSL built on `fletcher`.
- [helpers/glossary-definitions.typ](helpers/glossary-definitions.typ) — the
  abbreviations/glossary term list (via `@preview/glossarium`). Add new terms
  here as `(key, short, long, description)` tuples; reference them in text
  with `#gls(<key>)` / `#glspl(<key>)`.
- [helpers/bib/ECEtempBib.bib](helpers/bib/ECEtempBib.bib) — BibTeX
  references, cited via Typst's built-in `#cite`/`bibliography()` (IEEE
  style, set in `main.typ`).
- [chapters/](chapters/) — the actual thesis prose:
  `introduction.typ`, `methods.typ`, `conclusion.typ` at the top level, plus
  `chapters/frontmatter/` for `abstract_de.typ`, `abstract_en.typ`,
  `acknowledgments.typ`, `declaration_of_honor.typ`,
  `eidesstattliche_erklaerung.typ`. New chapters go here and get
  `#include`d from `main.typ`.
- [assets/graphics/](assets/graphics/) — logos and background graphics.
  Originals are `.eps` (kept for provenance from the LaTeX template), but
  Typst needs PDF/PNG/SVG — the template references pre-rendered
  `*-eps-converted-to.pdf` siblings for each `.eps`. If one goes missing,
  check git history (`git log -- '*.pdf'`) before re-converting from
  scratch — the converted PDFs were previously committed and can usually be
  restored rather than regenerated.
- [assets/data/](assets/data/) — CSV sample data, e.g. for `fhjtable`.

## Conventions worth knowing

- **Body font is Cambria at 11pt**; the title page uses a serif Latin
  Modern/Computer Modern font in white over `bgGraphic`. Don't change this
  without checking `iee-template.typ` — it's meant to match FH JOANNEUM's
  official Word template look.
- **Per-chapter numbering**: figures, tables, equations, and listings all
  reset to 1 at every `= Heading` (level-1 chapter start) — this mirrors the
  Word `ECE.dotm` convention. Handled by counter resets in the
  `show heading.where(level: 1)` rule in `iee-template.typ`.
- `program:` in `main.typ` controls organization name/location/degree text
  via `get-meta()` — one of `PROGRAM_ECE`, `PROGRAM_MEC`, `PROGRAM_ECM`,
  `PROGRAM_STM`, `PROGRAM_EEM` (Bachelor vs Master matters for wording).
- `language:` is `"en"` or `"de"` and switches section titles
  (Inhaltsverzeichnis/Contents, Abkürzungsverzeichnis/Glossary, etc.)
  throughout the template.
- `show-list-of:` in `main.typ` controls which front-matter lists render
  (`"figures"`, `"tables"`, `"equations"`, `"listings"`, `"glossary"`).
- Declarations (`Eidesstattliche Erklärung` / `Declaration of Honor`) are
  legally-required honor statements for FH JOANNEUM submissions — don't
  reword their content casually.
