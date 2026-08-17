= Integration with the AI-MotionLab Testsuite <ch:integration>
// Scope note: the GUI/testsuite itself is not this thesis's contribution.
// This chapter should be framed from the firmware side -- what the STM32
// exposes (GET/SET, telemetry fields) that the testsuite consumes -- with
// the GUI/testsuite described only as much as needed for context.

The firmware is built to be observed and tuned from outside the car. It exposes
its telemetry and parameters through a small text protocol carried over the
WiFi bridge, and it accepts new firmware images the same way. On the other end
sits the AI-MotionLab testsuite, a desktop application that a colleague,
Benedikt Polivka, developed alongside this firmware @PolivkaTestsuite2026. This
chapter describes the integration from the car side. It covers what the STM32
exposes and how the testsuite uses it, and describes the testsuite itself only
as far as that context needs.

== Testsuite Architecture Overview <sec:testsuite-architecture>

The testsuite is a dock-based PySide desktop application. Each panel is a dock
that can be shown, hidden, or rearranged, and each owns one job. A live map
draws the track and the cars on it, a parameters panel reads and writes the
car's tuning fields, a sensors panel shows incoming telemetry, and a messaging
panel exchanges raw commands with the car. Lap timing, event detection, and
session logging run alongside these.

Only a few of these panels reach the firmware directly, and they all speak the
same text protocol over the WiFi bridge. The rest of this chapter follows that
protocol from the car side. The parts of the testsuite that consume it, the
graphing, logging, and lap timing, are Polivka's work @PolivkaTestsuite2026 and
appear here only to show what the firmware's telemetry and parameter fields are
used for.

== Car Communication Module <sec:car-comm-module>

The testsuite reaches a car over WiFi. It opens a network connection to the
car's ESP8266 bridge, which passes the traffic on to the STM32 over a UART
link. Each car carries its own bridge and answers to its own name on the
network, so the testsuite can address one of several cars at a time.

#figure(
  image("/assets/graphics/selfdrawn/comm_chain.svg", width: 90%),
  caption: [Communication path from the testsuite to the car firmware],
) <fig:comm-chain>

On the car, the firmware receives each command as a framed packet, a command
byte, a length, the payload, and a CRC32 trailer. It checks the CRC with the
STM32's hardware CRC unit, and only a frame that passes is acted on. A text
command is dispatched to a small handler that produces a reply, which is framed
and CRC-tagged the same way before it is sent back. The command set itself is
covered in @sec:pid-tuning.

On the PC side, the car communication module wraps this protocol so the docks
do not deal with framing or transport. Its low-level send, receive, and
discovery functions come from a standalone OTA tool that carries the same wire
format. Both the module and that tool are Polivka's work @PolivkaTestsuite2026,
and the firmware's role is only to answer the commands they send.

== Live Telemetry Display <sec:telemetry-display>

The firmware keeps its telemetry in two flat tables of named values. One holds
the read-only sensor fields the car reports, such as the three distances, speed
and direction, acceleration, heading and yaw rate, battery voltage and motor
current, and the current state and event. The other holds the writable
parameters, mainly the steering and throttle PID gains. Each entry is just a
name and a pointer to a global variable, and the table a field lives in sets
its permission, so a sensor can only be read while a parameter can also be
written. The sensor drivers, control loop, and state machine write into these
globals every tick, and the command handler reads or writes them by name when a
request comes in.

The testsuite shows the sensor fields in a live table, one row per field, that
it refreshes on demand or polls continuously. Values arrive as plain numbers,
and the coded fields are annotated with their meaning, so a state of 5 reads as
full throttle and an event of 2 as a crash. This display is part of Polivka's
testsuite @PolivkaTestsuite2026. The writable parameters are shown and edited in
a separate panel, used for the tuning workflow in @sec:pid-tuning.

== Session Logging <sec:session-logging>
// laps, events, PID changes

== Using GET/SET Commands for On-the-Fly PID Tuning <sec:pid-tuning>

== Workflow: From Firmware Build to On-Track Parameter Tuning <sec:workflow>
