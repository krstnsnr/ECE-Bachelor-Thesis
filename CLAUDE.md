# ECE Bachelor Thesis

This repo is a **bachelor's thesis document** for the Electronics and Computer
Engineering (ECE) programme at FH JOANNEUM, written in
[Typst](https://typst.app) instead of LaTeX/Word. It's built on the
`typst-ECE-template` (this branch, `salloker`, is the "clean" variant without
the extra visual header aids). The chapters already carry section-level
outlines and scope notes, but most prose is still placeholder text, so treat
this as thesis infrastructure plus outline, not a finished document.

## Thesis Topic and Scope

Working title (see `main.typ`): "Development of an automated test and tuning
platform for CrazyCar using the AI-MotionLab."

The original registration form (Anmeldung, signed 2026-03-17) listed these
goals: write firmware for the new CrazyCar platform, and develop an automated
test environment, including automatic detection of the track in the room via
the AI-MotionLab plus lap/segment timing via the AI-MotionLab. The scope that
was actually carried out differs from that plan in two important ways:

- **Track/circuit detection is manual, not automatic.** The AI-MotionLab does
  not auto-detect the track geometry. Track boundaries are defined and loaded
  by hand (see `src/ai_motionlab/mapping/circuit.json` and `track_logic.py`
  in the companion repo below). Never describe circuit recognition as
  automated anywhere in the thesis; frame it as manually authored track
  geometry that the testsuite consumes.
- **Lap/segment timing is a colleague's contribution, not part of this
  thesis.** Timing logic in the AI-MotionLab GUI (event/lap detection) was
  implemented by a colleague. Mention it only as supporting infrastructure the
  test workflow relies on, never as this thesis's own contribution.

The **non-goals** from the original registration are unchanged:

- No rebuild or modification of the AI-MotionLab itself ("Umbau des
  AI-MotionLab").
- No PCB design work on the CrazyCar platform ("PCB-Design der CrazyCar
  Plattform"). The main PCB is an inherited design (see `sec:main-pcb` in
  chapter 2, cited via `@LaesserXRayLegacy2023`). Note that the evaluation
  chapter has a section summarizing PCB oversight impact on testing
  (`sec:pcb-impact-summary`); that section covers a hardware issue found
  while testing, it is not a PCB design contribution.

## Companion Source Repository and Authorship Boundaries

The code this thesis documents lives in a separate repository:
`C:\.Krisch\Github\CrazyCar_STM`. It is not built from here, but it is the
ground truth for every technical chapter (its own `CLAUDE.md` documents its
architecture in depth: OTA protocol, wire format, telemetry field tables,
GUI module layout). Three code trees live under its `src/`, and each has a
different relevance to this thesis:

- **`src/STM32/CrazyCar_STM32/`** (the STM32 firmware): entirely Kristian's
  own work and the main subject of the thesis. Chapters 2 through 4 (hardware
  platform, sensor/actuation firmware, state machine and turn detection) and
  the evaluation chapter should draw their technical detail from here: sensor
  drivers (`ads7128`, `bno055`, `tof_sensor`, `hall_sensor`), actuation
  (`motor_control`, `servo_steering`, `pid`, `control_loop`), the state
  machine (`state_machine.c`, `event_detection.c`), and the OTA/telemetry
  protocol (`ota.c`, `telemetry_fields.c`).
- **`src/ai_motionlab/`** (the PyQt5 "Automated Testsuite" GUI): not
  Kristian's work, with one exception. **`src/ai_motionlab/mapping/`** (track
  geometry loading and the manual circuit definition, `track_logic.py` and
  `circuit.json`) is his contribution and belongs in the thesis; it maps to
  the appendix's "Circuit Mapping Diagrams" (`app:diagrams`). Everything else
  in `ai_motionlab` (scene rendering, event detection/lap timing, car
  communication wiring, graphing, session logging) is a colleague's work
  (mostly authored by "Beenno" / Benedikt Polivka per git history) and should
  appear only as background needed to explain what the firmware exposes to
  it, never as a claimed contribution. Chapter 5 already carries a scope note
  to this effect; keep it that way as prose gets filled in.
- **`src/esp8266_bridge/`** (WiFi to UART bridge firmware): not Kristian's
  work and out of scope beyond a passing mention. The only place it should
  surface is when explaining why telemetry fields are shaped the way they
  are, and only at a top level, for example "telemetry fields exist so the
  PC side testsuite can read them out over the ESP8266 WiFi bridge." Do not
  describe its internal protocol handling (frame routing, OTA staging over
  LittleFS, bootloader driving) as thesis content.

When in doubt whether a piece of code belongs in the thesis, check
`git log --format='%an' -- <path>` in the companion repo: `krstnsnr` and
`Krisch` commits are Kristian's; `Beenno` and `Benedikt Polivka Lab PC` are
the colleague's.

## Toolchain

- **Typst**, compiled via the VSCode **Tinymist** extension (no Typst CLI
  installed on this machine, so compile and preview through the editor).
- Package manifest: [typst.toml](typst.toml); entrypoint is
  `iee-template.typ`.
- Recommended font: "Latin Modern Roman" (for the original IEE LaTeX look).
  See README.md for the download link.

## Structure

- [main.typ](main.typ): the actual document entrypoint. Imports the template
  and helpers, fills in thesis metadata (title, author, supervisors, program,
  language), and `#include`s the frontmatter, chapters, and bibliography in
  order.
- [iee-template.typ](iee-template.typ): the template engine itself
  (`iee-thesis(...)` function). Defines page layout, title page, per-chapter
  numbering, headings, TOC/list-of-figures/tables/equations/listings,
  glossary wiring, and colors. Ported from the original LaTeX IEE template
  (`Mayer Florian`) and an IIT Typst template.
- [helpers/lib.typ](helpers/lib.typ): reusable content helpers such as
  `blue-box`, `quote`/`directquote`, `fhjcode` (numbered code blocks),
  `textit`/`textbf` macros, `fhjtable` (CSV to styled table),
  `fhjrevisionmark`, and a `flowchart`/`fnode`/`fdecision`/`fedge` mini-DSL
  built on `fletcher`.
- [helpers/glossary-definitions.typ](helpers/glossary-definitions.typ): the
  abbreviations/glossary term list (via `@preview/glossarium`). Add new terms
  here as `(key, short, long, description)` tuples; reference them in text
  with `#gls(<key>)` / `#glspl(<key>)`.
- [helpers/bib/ECEtempBib.bib](helpers/bib/ECEtempBib.bib): BibTeX
  references, cited via Typst's built-in `#cite`/`bibliography()` (IEEE
  style, set in `main.typ`).
- [chapters/](chapters/): the actual thesis prose, in the order `main.typ`
  includes them: `01_introduction.typ`, `02_hardware_platform.typ`,
  `03_firmware_sensors_actuation.typ`, `04_firmware_state_machine.typ`,
  `05_ai_motionlab_integration.typ`, `06_evaluation.typ`,
  `07_discussion.typ`, `08_conclusion.typ`, `09_appendices.typ`. Each file
  currently holds a heading/section outline with scope comments; fill prose
  in place rather than restructuring headings without reason.
  `chapters/frontmatter/` holds `abstract_de.typ`, `abstract_en.typ`,
  `acknowledgments.typ`, `declaration_of_honor.typ`, and
  `eidesstattliche_erklaerung.typ`. `chapters/demo/` is leftover template
  demo content (`introduction.typ`, `methods.typ`, `conclusion.typ`); it is
  not included from `main.typ` and is not part of the thesis.
- [assets/graphics/](assets/graphics/): logos and background graphics.
  Originals are `.eps` (kept for provenance from the LaTeX template), but
  Typst needs PDF/PNG/SVG, so the template references pre-rendered
  `*-eps-converted-to.pdf` siblings for each `.eps`. If one goes missing,
  check git history (`git log -- '*.pdf'`) before re-converting from
  scratch; the converted PDFs were previously committed and can usually be
  restored rather than regenerated.
- [assets/data/](assets/data/): CSV sample data, e.g. for `fhjtable`.

## Conventions worth knowing

- **Body font is Cambria at 11pt**; the title page uses a serif Latin
  Modern/Computer Modern font in white over `bgGraphic`. Don't change this
  without checking `iee-template.typ`; it's meant to match FH JOANNEUM's
  official Word template look.
- **Per-chapter numbering**: figures, tables, equations, and listings all
  reset to 1 at every `= Heading` (level-1 chapter start), mirroring the
  Word `ECE.dotm` convention. Handled by counter resets in the
  `show heading.where(level: 1)` rule in `iee-template.typ`.
- `program:` in `main.typ` controls organization name, location, and degree
  text via `get-meta()`: one of `PROGRAM_ECE`, `PROGRAM_MEC`, `PROGRAM_ECM`,
  `PROGRAM_STM`, `PROGRAM_EEM` (Bachelor vs Master matters for wording).
- `language:` is `"en"` or `"de"` and switches section titles
  (Inhaltsverzeichnis/Contents, Abkürzungsverzeichnis/Glossary, etc.)
  throughout the template.
- `show-list-of:` in `main.typ` controls which front-matter lists render
  (`"figures"`, `"tables"`, `"equations"`, `"listings"`, `"glossary"`).
- Declarations (`Eidesstattliche Erklärung` / `Declaration of Honor`) are
  legally required honor statements for FH JOANNEUM submissions; don't
  reword their content casually.

## Writing Style

- Never use an em dash (—) in thesis prose or in this file. Rewrite with a
  comma, a period and a new sentence, a colon, or parentheses instead.
- Use a hyphen (-) only when grammar requires it (compound modifiers like
  "level-1", "top-level", "STM32-based"); prefer rewording to avoid it
  otherwise.
