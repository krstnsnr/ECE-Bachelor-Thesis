= Integration with the AI-MotionLab Testsuite <ch:integration>
// Scope note: the GUI/testsuite itself is not this thesis's contribution.
// This chapter should be framed from the firmware side -- what the STM32
// exposes (GET/SET, telemetry fields) that the testsuite consumes -- with
// the GUI/testsuite described only as much as needed for context.

== Testsuite Architecture Overview <sec:testsuite-architecture>
// dock-based PySide app, relevant modules only

== Car Communication Module <sec:car-comm-module>
// bridging car_ota.py into the GUI

== Live Telemetry Graphing <sec:telemetry-graphing>
// PID/tuning feedback loop

== Session Logging <sec:session-logging>
// laps, events, PID changes

== Using GET/SET Commands for On-the-Fly PID Tuning <sec:pid-tuning>

== Workflow: From Firmware Build to On-Track Parameter Tuning <sec:workflow>
