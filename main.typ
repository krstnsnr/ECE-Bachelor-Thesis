#import "iee-template.typ": *

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

  // Content from abstract.tex and acknowledgments.tex
  abstract-de: [
    Hier sollte Ihre Zusammenfassung der Arbeit stehen! Dies ist der Platzhalter für die Kurzfassung.
  ],
  abstract-en: [
    Please put the summary of your work here! This corresponds to the content of `abstract.tex`.
  ],
  acknowledgments: [
    Thanks to...

    Choose whatever suits you best. This corresponds to `acknowledgments.tex`.
  ],

  doc
)

// ==========================================================
// CHAPTERS
// Each chapter lives in its own file under chapters/.
// Add more includes here as your thesis grows.
// ==========================================================
#include "chapters/introduction.typ"
#include "chapters/body.typ"
