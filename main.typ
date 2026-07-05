#import "iee-template.typ": *
#import "helpers/lib.typ": *

// ==========================================================
// USER CONFIGURATION
// ==========================================================

#show: doc => iee-thesis(
  // Metadata
  title: "Development of an automated test and tuning platform for CrazyCar using the AI-MotionLab",
  //subtitle: "Optional Subtitle",
  author: "Kristian Seiner",
  supervisors: (
    "DI Florian Mayer, BSc",
  ),
  
  // Program: PROGRAM_ECE, PROGRAM_MEC, PROGRAM_ECM, PROGRAM_STM, PROGRAM_EEM
  program: PROGRAM_ECE, 
  language: "en", // "en" or "de"
  doc-type: "thesis", // "thesis" or "report"
  show-list-of: ("figures"),
  
  // Content from abstract.tex and acknowledgments.tex
  abstract-de: [
    #include "/chapters/frontmatter/abstract_de.typ"
  ],
  abstract-en: [
    #include "/chapters/frontmatter/abstract_en.typ"
  ],
  acknowledgments: [
    #include "/chapters/frontmatter/acknowledgments.typ"
  ],

  doc
)

#include "chapters/01_introduction.typ"

#include "chapters/02_state_of_the_art.typ"

#include "chapters/03_hardware_platform.typ"

#include "chapters/04_firmware_sensors_actuation.typ"

#include "chapters/05_firmware_state_machine.typ"

#include "chapters/06_ai_motionlab_integration.typ"

#include "chapters/07_evaluation.typ"

#include "chapters/08_discussion.typ"

#include "chapters/09_conclusion.typ"

#include "chapters/10_appendices.typ"

#heading(numbering: "A.1")[Bibliography]
#bibliography("helpers/bib/ECEtempBib.bib", style: "ieee", title: none)