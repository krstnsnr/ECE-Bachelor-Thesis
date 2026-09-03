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
  Plattform"). The main PCB was designed by someone else (A. Läßer, cited
  via `@LaesserXRayLegacy2023`, see `sec:main-pcb` in chapter 2) specifically
  for this STM32-based generation of the platform. **Correction: this is not
  a legacy or carried-over board reused from an older generation.** It is a
  new design that had never been brought up or tested before this thesis;
  bringing it up and finding its problems firsthand was part of this
  thesis's own work (see the "first attempt at bringing that hardware up"
  framing in `sec:motivation`), not something inherited from prior testing.
  Don't describe the PCB as "inherited" or "carried over" anywhere in the
  thesis; describe it as a pre-existing design this thesis builds firmware
  for and evaluates, not one it created or one that was previously verified.
  Note that the evaluation chapter has a section summarizing PCB oversight
  impact on testing (`sec:pcb-impact-summary`); that section covers hardware
  issues found while testing, not a PCB design contribution.

## Background Research: Crazy Car Competition, Curriculum, and the AI-MotionLab

Web research done 2026-07-24 to ground the historical/institutional framing
used in the introduction and motivation sections. Sources are official
FH JOANNEUM pages and a course GitHub org, all live at research time; verify
again before citing if a chapter needs a formal reference, since these are
web sources that can change or move.

**The public "Crazy Car" competition** is a separate thing from this thesis's
CrazyCar research platform, though the two share a name and lineage. It is
an autonomous 1:18-scale model car race that originated in Switzerland;
FH JOANNEUM students first took part in 2007, and the race has been hosted
at FH JOANNEUM itself every year since 2008. It is organized by the
Institute of Electronic Engineering and overseen by DI Florian Mayer
(this thesis's supervisor), with school and university teams programming
their own cars to complete an obstacle course with no remote control.
FH JOANNEUM provides ready-made "Controller Package" starter kits built on
either a Texas Instruments MSP430 or an Arduino, documented in manuals such
as the "Crazy Car Controller Arduino V2.0" manual.
(Sources:
[Crazy Car project page](https://www.fh-joanneum.at/en/project/crazycar/),
[Crazy Car competition press release](https://www.fh-joanneum.at/presse/technikspass-beim-crazy-car-wettbewerb-an-der-fh-joanneum/),
[Arduino V2.0 controller manual](https://cdn.fh-joanneum.at/media/sites/1/2016/02/CrazyCarController_Arduino2.0_Manual.pdf).)

**The CrazyCar platform is also the lab vehicle for the ECE bachelor's
3rd-semester "Embedded Systems" course**, the same course already cited in
this thesis as `@OkornDiererMayerES`. That course's public lab materials
(GitHub org `Electronic-and-Computer-Engineering/EmbeddedSystems`) target an
MSP430F5335-based Crazy Car and walk students through a 10-chapter, three
layer HAL/DL/AL architecture (Hardware Abstraction Layer, Driver Layer,
Application Layer): GPIO, clock system, and TimerB0 first, then PWM
actuation, SPI, and an ST7565 LCD, then ADC with DMA and Sharp IR distance
sensors, and finally driving algorithms (state machines, PID control,
lane-following). This is useful grounding for the motivation and history
sections: the MSP430-based, layered, sensor-plus-actuator-plus-state-machine
architecture taught in that course is the direct academic predecessor of the
STM32-based firmware this thesis builds, which follows the same broad shape
(sensor drivers, actuator control, a driving state machine) on newer,
research-grade hardware and with an AI-MotionLab-integrated test and tuning
workflow instead of a teaching lab exercise.
(Source: [EmbeddedSystems course repository](https://github.com/Electronic-and-Computer-Engineering/EmbeddedSystems).)

**Curriculum naming caveat:** FH JOANNEUM's current curriculum page
distinguishes an active curriculum from a discontinued one for older
cohorts. Students who started in 2023 (as documented by a public syllabus
for "Embedded Computing 2 (STECE-2023)") are on the **older, discontinued**
track: "Embedded Systems" in semester 3 (8 ECTS, 6 SWS, German, the MSP430
Crazy Car course above), "Embedded Computing 1" in semester 4, and
"Embedded Computing 2" in semester 5 (object-oriented C++, Linux systems
programming, embedded Linux hardware interfaces). Newer cohorts instead take
differently named, differently scoped courses ("Embedded Systems" 7 ECTS in
semester 3, "Embedded Linux Development" in semester 4, "Embedded
Applications Development" in semester 5). When citing or describing "the
Embedded Systems lecture," it means the semester-3, MSP430/Crazy-Car-based
course on the older/2023-cohort track, matching `@OkornDiererMayerES`; don't
conflate it with the newer curriculum's course of the same name, which has
different content and ECTS.
(Sources:
[ECE bachelor curriculum](https://www.fh-joanneum.at/elektronik-und-computer-engineering/bachelor/en/my-studies/curriculum/),
[Embedded Computing 2 (STECE-2023) syllabus](https://www.faschingbauer.me/about/site/work-in-progress/fh-joanneum/2023/ws2025-26/syllabus.html).)

**The AI-MotionLab is a real, separate lab facility**, not just the name of
the PySide testsuite (correction: the GUI is built with PySide6, not PyQt5;
`pyproject.toml` in the companion repo pins `PySide6`, and the companion
repo's own `CLAUDE.md` calling it "PyQt5" is stale). The AI-MotionLab is a
motion-capture-based research infrastructure run by FH JOANNEUM's Electronic
Engineering Institute (headed by Christian Vogel), built for "self-learning,
mobile and connected cyber-physical systems" research with partners TU Graz
and Montanuniversität Leoben, funded by the Styrian regional government from
February 2018 to August 2019. Its core hardware is a twelve-camera optical
tracking system on a truss covering roughly 7 by 7 by 3 meters, with
sub-millimeter positional accuracy at 360 fps, able to track up to 14 rigid
bodies at once (the same class of system as the OptiTrack integration in
`src/ai_motionlab/broadcast/`). The CrazyCar project's "Automated Testsuite"
is a separate PySide application built on top of this shared lab facility,
not the lab itself. Kristian's colleague developed the testsuite alongside
this thesis's firmware, in parallel rather than as pre-existing
infrastructure, so don't describe it as something that already existed
before this thesis started. When the introduction explains "the
AI-MotionLab," it should distinguish the general-purpose motion-capture lab
from the CrazyCar-specific testsuite software that consumes its tracking
data.
(Source: [aiMotionLab project page](https://www.fh-joanneum.at/en/projekt/aimotionlab-artificial-intelligence-in-motion-laboratory/).)

## Companion Source Repository and Authorship Boundaries

The code this thesis documents lives in a separate repository:
`C:\.Krisch\Github\CrazyCar_STM`. It is not built from here, but it is the
ground truth for every technical chapter (its own `CLAUDE.md` documents its
architecture in depth: OTA protocol, wire format, telemetry field tables,
GUI module layout). Three code trees live under its `src/`, and each has a
different relevance to this thesis:

- **`src/STM32/CrazyCar_STM32/`** (the STM32 firmware): mostly Kristian's own
  work and the main subject of the thesis, but **not the GET/SET protocol or
  the OTA update mechanism**. Chapters 2 through 4 (hardware platform,
  sensor/actuation firmware, state machine and turn detection) and the
  evaluation chapter should draw their technical detail from here: sensor
  drivers (`ads7128`, `bno055`, `tof_sensor`, `hall_sensor`), actuation
  (`motor_control`, `servo_steering`, `pid`, `control_loop`), and the state
  machine (`state_machine.c`, `event_detection.c`) are his.
  **Correction: the command protocol, its framing/CRC/dispatch machinery, the
  OTA update path, and the ESP8266 USART/DMA link driver are Beenno's work,
  not Kristian's**, confirmed via `git log --diff-filter=A -- <path>` and
  full author history in the companion repo: `ota.c`/`ota.h` and
  `esp_uart.c`/`esp_uart.h` carry only Beenno commits (including "communication
  protocol car side done (ota also working, dual bank)"), and `telemetry_fields.c`
  was built and repeatedly refactored by Beenno ("simplefied telemetry fields",
  "Biiiig refactor", "refactoring"); Kristian's own commits there only ever add
  specific field entries (quaternion/linear-acceleration, the 4-pin Hall
  fields, point-follow telemetry) into a table mechanism Beenno already built.
  Frame the GET/SET protocol, telemetry/parameter table mechanism, and OTA
  path throughout the thesis as existing infrastructure Kristian's sensor,
  actuation, and state machine modules plug their data into, the same way the
  PySide testsuite is already framed, never as this thesis's own contribution.
  What remains Kristian's within that integration is real and worth stating
  plainly: the specific fields exposed (his sensor readings, PID gains, state
  and event values) and making sure his firmware builds are flashable over
  that OTA path.
- **`src/ai_motionlab/`** (the PySide "Automated Testsuite" GUI, developed by
  a colleague alongside this thesis's firmware, not beforehand): not
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
  here as `(key, short, long, description)` tuples; keep `description` short,
  ideally a single line, since the glossary is printed in one column and long
  descriptions wrap (see `helpers/glossary.typ`).
  Reference them in text with `#gls("key")` / `#glspl("key")`, a plain string
  matching the `key` field, not a Typst label (`#gls(<key>)` panics inside
  glossarium 0.5.10 with "type label has no method `first`"; its own doc
  comment says `key (str)`). **Every chapter file that uses `#gls`/`#glspl`
  needs its own** `#import "/helpers/gls.typ": gls, glspl` **at the top**;
  `#include` does not inherit the includer's imports, so each chapter is
  its own scope. Import from `helpers/gls.typ`, not from glossarium directly:
  those wrappers force the short form (`first: false`) so only the
  abbreviation ever appears in the text, including the first occurrence. The
  long form lives only in the glossary. `show-list-of` in `main.typ` must
  contain `"glossary"` or the glossary registry is never populated
  (`register-glossary` only runs inside that front-matter branch in
  `iee-template.typ`), so `#gls()` calls anywhere in the thesis would fail to
  resolve if it were turned off. Convention going forward: the first time a
  new acronym or unfamiliar term appears anywhere in the document (reading
  order, chapter 1 onward), add it to `gls-entries` if it isn't there yet and
  wrap that first occurrence with `#gls("key")`; leave later occurrences of
  the same term as plain text. Don't wrap terms inside headings.
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
- **Image source citations live inside the figure caption**, appended via
  `#imgsrc(<key>)` (or `#imgsrc(<key1>, <key2>)` for more than one source),
  for example `caption: [XRAY M18 Pro LiPo 4WD chassis
  #imgsrc(<MKRacingXRAYM18Pro2026>)]` as done for `@fig:chassis` in
  `sec:chassis`. This renders as "Figure 2.1: XRAY M18 Pro LiPo 4WD chassis
  [5]." Import it per chapter with
  `#import "/helpers/lib.typ": imgsrc`, the same per-file import rule as
  `#gls`/`#glspl`. Don't call `@key`/`#cite(<key>)` directly inside a
  caption; the List of Figures outline entry
  (`show outline.entry.where(level: 1)` in `iee-template.typ`) re-renders
  the full caption body in the frontmatter before chapter 1, and a citation
  seen there first would grab a lower IEEE reference number than citations
  appearing earlier in the actual chapter text. `imgsrc` (in
  `helpers/lib.typ`) avoids this by checking the shared `in-outline` state
  (set around the `#cap.body` re-render in `iee-template.typ`) and
  suppressing the citation when rendering inside that outline, so citation
  numbering follows first appearance in the chapter text.

## Writing Style

- Never use an em dash (—) in thesis prose or in this file. Rewrite with a
  comma, a period and a new sentence, or parentheses instead.
- Use a hyphen (-) only when grammar requires it (compound modifiers like
  "level-1", "top-level", "STM32-based"); prefer rewording to avoid it
  otherwise.
- Use a colon only to introduce an actual formatted list (a `-` bullet
  list, or an inline enumeration that is genuinely a list of items) and
  only when there's no easy way to write the sentence without it. Don't
  use a colon to introduce a single elaboration, example, or explanatory
  clause in running prose; rewrite as two sentences, or join with a comma
  or "namely"/"including" instead. Heading-style colons in chapter section
  titles (e.g. "Microcontroller: STM32H533RE") are an existing, separate
  convention and are unaffected by this rule.
- Keep sentences short and flat, not nested ("verschachtelt"). One sentence
  should carry one idea. If a sentence needs more than one "since"/"that"/
  "which" clause stacked together, or buries its main point after several
  subordinate clauses, split it into two or three plain sentences instead.
  This matters more than trimming a sentence to a target length; a short
  sentence that still crams two reasons and a conclusion together is not
  the goal, clarity is.
- Focus thesis prose on what was achieved, not on what wasn't done or on
  which earlier framing was wrong. Never write a sentence that states an
  assumption and then negates it in the same breath (for example, "the
  testsuite was developed alongside the firmware, instead of before").
  Nobody reading the finished thesis cares what an earlier draft assumed;
  write the current understanding directly, as if it had been known from
  the start. This applies to editing passes on already-written chapters
  too: when a fact changes, rewrite the sentence clean rather than layering
  a correction onto the old one.
- When editing a paragraph, reread it together with the paragraph right
  before and right after it, not in isolation. Adjacent paragraphs drift
  out of sync easily, for example two paragraphs in a row both opening
  with "CrazyCar is ..." after separate edits. Check that the paragraph
  transitions still flow and rework the opening/transition sentence if a
  fix to one paragraph made it repeat or clash with its neighbor.
- Weave cross-references and citations into the sentence grammar instead of
  tacking them on as a trailing parenthetical. Write "the bring-up is
  covered in `@sec:main-pcb`" or "as `@sec:i2c-stack` describes", not "the
  board (`@sec:main-pcb`)"; and let citations read as part of the prose, for
  example "documented by its original author `@LaesserXRayLegacy2023`" rather
  than a bare "(`@LaesserXRayLegacy2023`)". The same applies to figures,
  "shown in `@fig:x`" reads better than a trailing "(`@fig:x`)". End-of-
  sentence `(@sec:x)` pointers should usually become part of the sentence, or
  a short sentence of their own ("`@sec:pcb-impact-summary` reports the
  oversights that surfaced."). A brief parenthetical is only acceptable when
  the reference is genuinely incidental, or inside a definitional aside that
  is already parenthetical (for example listing "the sensor suite in
  `@ch:hardware`" among other items). Don't stack two "as ... describes"
  clauses in one sentence; if a sentence needs two references, split it.
  **Refinement from supervisor feedback:** a cross-reference that is not
  itself part of the statement should become its own short, neutral
  sentence at the end of the paragraph rather than an appositive clause.
  "@sec:i2c-stack describes this sequence." replaced "a sequence
  @sec:i2c-stack walks through", and "The firmware implementation is
  described in @sec:actuator-control." replaced "How the firmware drives
  them is covered in @sec:actuator-control." Use plain verbs for these
  pointers, namely "describes", "reports", "is described in". Avoid
  "covered in", "detailed in", "walks through", "as ... notes".

## Supervisor Feedback: Academic Register (FM review, commits 5591ffa and e294f5b)

The supervisor (DI Florian Mayer) reviewed the introduction and chapter 2 and
rewrote them line by line. The edits are almost entirely about **register**,
not about content: the prose was already correct, but it read like a
well-written blog post rather than a thesis. Apply these rules to every
chapter, and apply them when drafting new prose so the same pass does not
have to happen again.

- **Neutral technical verbs, never conversational ones.** This is the single
  most frequent edit. Replacements actually made: "sits on/next to" to "is
  mounted on / is connected to / listens on", "talks over I2C" to
  "communicates over I2C", "answers to one of eight addresses" to "the
  address is selected by", "the kit ships bare" to "the kit is available
  standalone", "bolts onto" to "are mounted on", "walks through" to
  "describes", "a reset costs about a second" to "a reset requires
  approximately one second", "tristates both sides" to "sets both sides to
  high impedance", "a plain byte pipe" to "a transparent byte stream",
  "surfaces the calibration status" to "transmits the calibration status",
  "picks up a nearby wall" and "keeps calibration turned on" to "detects" and
  "enables". Also drop stance verbs like "it turned out to be a good fit",
  which became "it proved well suited to the requirements".
- **Prefer "the X of the Y" over the Saxon genitive "the Y's X",** especially
  for the recurring self-references. "The platform's IMU" became "The IMU of
  the platform", "this platform's driver" became "the driver of this
  platform", "the platform's only wireless link" became "the only wireless
  interface of the platform". More generally, cut the possessive entirely
  where a definite article works: "This thesis's firmware runs on a
  Nucleo-H533RE" became "The firmware runs on a Nucleo-H533RE".
- **Use "this thesis" sparingly and only for genuine contribution or scope
  statements.** Elsewhere use "the firmware", "the platform", "the work
  presented here", or a passive construction. "This thesis gives that
  hardware baseline its first application firmware" became "The work
  presented here provides the first application firmware for this baseline".
  "This thesis is the first work to put this board into operation" was kept,
  because that sentence really is a contribution claim.
- **Delete reader-facing justification and colour commentary.** Sentences
  that explain why a fact is interesting, or that anticipate the reader's
  reaction, were cut wholesale. Removed examples: "Being a widely sold
  competition kit also means worn or crashed parts are easy to source and
  replace, which matters when a fleet of these cars is driven by students",
  "letting more than one ADS7128 share a bus if a design ever needs it",
  "properties that matter when a fleet of cars is driven by students and
  expected to survive repeated crashes", "It is the board that ties the rest
  of the platform together". State the fact and stop. A short consequence
  clause survives only when it is technically load-bearing, for example
  "which matters on a track where the car measures its distance to wooden
  barriers".
- **Cut filler and hedging adverbs.** "just", "simply", "actually", "exactly",
  "already", "straight", "ends up", "on the order of", "more ... than this
  platform ends up needing". "the three cannot simply share one bus" became
  "the three sensors cannot share a single bus without further measures";
  "which of its eight channels it actually uses" became "the channel
  assignment used on this platform"; "The AI-MotionLab itself is just the
  lab" became a plain apposition naming what it is.
- **State things positively; don't define by negation.** "It is not a single,
  fixed design. Chassis, PCB, and microcontroller have all changed between
  iterations" was compressed into one positive sentence, "It is not a single
  fixed design but an MSP430-based platform that has been redesigned several
  times during student projects up to its STM32-based version". Where a
  contrast is genuinely needed, put the contrast first and the fact second,
  as in "Unlike conventional infrared proximity sensors, which derive
  distance from the intensity of the reflected light, the VL53L1X measures
  the time a 940 nm laser pulse requires to travel to the target and back."
- **Do not restate scope or authorship boundaries outside the sections that
  own them.** The introduction repeated "@sec:non-goals places this out of
  scope" and "not as contributions of this work" in several sections; the
  supervisor left the statement once, in @sec:non-goals, and deleted the
  echoes. Say the boundary where it belongs and reference it once.
- **Split, don't stack.** Long sentences with a trailing subordinate clause
  were broken into two or three sentences. "a 1/18-scale RC chassis detailed
  in @sec:chassis and chosen for its robustness and ready availability of
  spare parts" became "a 1/18-scale RC chassis described in @sec:chassis. It
  was chosen for its robustness and the availability of spare parts."
  Similarly the dense problem-statement paragraph was rebuilt as three short
  paragraphs, namely the gap, the consequence that follows from it, and what
  the thesis does about both.
- **Keep list items grammatically parallel.** In @sec:goals, "Implement
  drivers and integration for" became "Implement and integrate drivers for",
  and "a crash, a low battery, or the car getting stuck can be detected and
  acted on" became "a crash, a low battery, or a stuck car can be detected
  and handled". Every item in a bullet list should start with the same part
  of speech and keep the same shape.
- **Prefer restating the noun over "namely" lists** when the list is really a
  description. "one complex system to work on, namely sensing the
  environment, actuating steering and throttle and reacting in real time"
  became "a car that senses the environment, actuates steering and throttle,
  and reacts in real time". "namely" survives where it introduces a genuine
  definition, as in "the basic idea, namely a four-wheel-drive, 1/18-scale
  car that ...".
- **Name people in full on first mention.** "A. Läßer" became "Andreas
  Läßer"; "A colleague, Benedikt Polivka, developed the testsuite alongside
  this thesis's firmware, in parallel, so the two projects grew together"
  became "The testsuite was developed by Benedikt Polivka
  @PolivkaTestsuite2026". Drop the relationship narrative and keep the
  attribution.
- **Terminology consistency.** "lecture" became "course", "devboard" became
  "development board", "car" became "vehicle" in several formal contexts,
  "over-the-air update infrastructure" became `#gls("ota")` at its first
  occurrence. Pick one term per concept and keep it.

### Units, numbers, and symbols

The supervisor consistently normalised these; follow the convention in new
prose.

- **Always put a space between a number and its unit ("Einheit"), with no
  exceptions.** Write "220 mm", "165 g", "2.9 m", "100 Hz", "940 nm",
  "400 kHz", "512 KB", "250 MHz", "1200 µs", never "220mm" or "100Hz". This
  is the SI convention and it applies to every unit everywhere in the
  document, including inside figure captions, table cells, and listing
  comments. Grep for `[0-9](mm|cm|m|g|kg|s|ms|µs|ns|nm|Hz|kHz|MHz|GHz|V|mV|A|mA|W|KB|MB|GB)\b`
  before committing a chapter to catch new ones.
  - The space belongs between value and unit only. Percent and degree signs
    stay attached to the number ("40%", "27°", "$plus.minus$90°"), and so do
    non-unit suffixes that are part of a product designation, such as the
    "36T" and "42T" spur gears in `sec:chassis`.
  - Compound modifiers before a noun keep their hyphen and no space, as in
    "a 12-bit converter" or "a 1.6-mm plate", but the standalone form always
    takes the space.
  - If a value and unit end up split across a line break in the rendered
    PDF, use Typst's non-breaking space (`250~MHz`) for that occurrence.
    Use a plain space by default so the source stays readable.
- **Use the correct unit symbol, not an ASCII stand-in.** Microseconds are
  "µs", not "us", which reads as the English word in running prose. Likewise
  "Ω" not "Ohm", and "°C" not "degC".
- **Angles use the degree sign, never the word.** Write "90° corners",
  "180° hairpins", "a tolerance of 10°", "from -180° to 180°", "1 °/s",
  never "90 degrees", "90-degree corners", or "one degree per second". Sign
  every value in a range, not just the last one. The word "degree" survives
  only where it is not an angle, as in "nine degrees of freedom" and "loses
  a degree of freedom" in `sec:imu`.
- **Dimension pairs use the multiplication sign with spaces**, matching
  "3 mm × 3 mm" in `sec:adc`. Write "16 × 16 SPAD array", "4 × 4 ROI",
  "10 × 10 ROI", never "16x16" with a letter x. Hexadecimal literals
  (`0x28`, `0x30`) are unrelated and keep their "0x" prefix.
- **Use SI/byte abbreviations, not spelled-out words**: "512 Kbytes" to
  "512 KB", "272 Kbytes" to "272 KB", "meters per second squared" to "m/s²".
- **Use real typographic symbols**: `°` for degrees ("27 degrees" to "27°"),
  `°/s` for angular rate ("2000 degrees per second" to "2000 °/s"), `×` for
  multiplication, `$plus.minus$` for ±, and a real superscript in "m/s²".
- **Use "per" for scale factors**: "16384 LSB to one unitless quaternion
  component" became "16384 LSB per unit quaternion component".

### Citations

- **Back general technical concepts with a real academic reference, not only
  with the datasheet.** The gimbal-lock explanation in @sec:imu gained
  `@Diebel2006` (a Stanford technical report on attitude representations)
  alongside the BNO055 datasheet, which is cited separately for the concrete
  consequence in the part. Datasheets support device facts; a named
  phenomenon or method needs a proper source.
- Image sources belong in the caption via `#imgsrc`, as described above under
  Conventions. The supervisor's pass converted every "Image source:" line
  under a figure into that form.

