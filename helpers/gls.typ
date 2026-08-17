// Local glossarium wrappers. Force the abbreviation (short form) everywhere,
// including the first occurrence, so the long form only appears in the
// glossary. Chapters import gls/glspl from here instead of from glossarium.
#import "@preview/glossarium:0.5.10": gls as _gls, glspl as _glspl

#let gls(key, ..args) = _gls(key, first: false, ..args)
#let glspl(key, ..args) = _glspl(key, first: false, ..args)
