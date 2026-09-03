= Integration with the AI-MotionLab Testsuite <ch:integration>
// Scope note: the GUI/testsuite itself is not this thesis's contribution.
// This chapter should be framed from the firmware side -- what the STM32
// exposes (GET/SET, telemetry fields) that the testsuite consumes -- with
// the GUI/testsuite described only as much as needed for context.

The firmware is designed to be observed and tuned from outside the car. It
exposes its telemetry and parameters through a text protocol carried over the
WiFi bridge, and it accepts new firmware images over the same path. The
counterpart on the PC side is the AI-MotionLab testsuite, which Benedikt
Polivka developed alongside this firmware @PolivkaTestsuite2026. This chapter
describes the integration from the car side. It covers what the STM32 exposes
and how the testsuite uses it. The testsuite itself is described only as far
as that context requires.

== Testsuite Architecture Overview <sec:testsuite-architecture>

The testsuite is a dock-based PySide desktop application. Each dock can be
shown, hidden, or rearranged, and covers one function. A live map draws the
track and the cars on it, and a parameters panel reads and writes the tuning
fields of the car. A sensors panel shows incoming telemetry, and a messaging
panel exchanges raw commands with the car. Lap timing, event detection, and
session logging run alongside these docks.

Only a few of these panels reach the firmware directly, and they all use the
same text protocol over the WiFi bridge. The rest of this chapter follows that
protocol from the car side. 

== Car Communication Module <sec:car-comm-module>

The testsuite reaches a car over WiFi. It opens a TCP connection to the
ESP8266 bridge of the car, which forwards the traffic to the STM32 over a UART
link. Each car carries its own bridge and is addressed by its own name on the
network, so that the testsuite can select one of several cars.
@fig:comm-chain shows the resulting path and the frame that travels along it.

#figure(
  image("/assets/graphics/selfdrawn/comm_chain.svg", width: 90%),
  caption: [Communication path from the testsuite to the car firmware],
) <fig:comm-chain>

On the car, the firmware receives each command as a framed packet consisting
of a command byte, a length, the payload, and a CRC32 trailer. It verifies the
CRC with the hardware CRC unit of the STM32, and only a frame that passes the
check is processed. A text command is dispatched to a handler that produces a
reply, which is framed and CRC-tagged in the same way before it is sent back.
@sec:pid-tuning describes the command set.

On the PC side, the car communication module wraps this protocol, so that the
docks remain independent of framing and transport. Its low-level send,
receive, and discovery functions come from a standalone OTA tool that uses the
same wire format.

The protocol is existing infrastructure on both ends. The testsuite module,
the OTA tool, and the framing and dispatch code in the car are Polivka's work
@PolivkaTestsuite2026. This thesis contributes the fields that travel over it,
which @sec:telemetry-display describes.

== Live Telemetry Display <sec:telemetry-display>

The firmware stores its telemetry in two flat tables of named values. One
holds the read-only sensor fields that the car reports. Among them are the
three distances, the speed and direction, the acceleration, the heading and
yaw rate, the battery voltage and motor current, and the current state and
event. The other table holds the writable parameters, mainly the steering and
throttle PID gains.

Each entry is a name and a pointer to a global variable, and the table that
holds a field sets its permission. A sensor field can therefore only be read,
while a parameter can also be written. The sensor drivers, control loop, and
state machine write into these globals on every tick, and the command handler
reads or writes them by name when a request arrives.

The testsuite shows the sensor fields in a live table with one row per field.
It refreshes the table on demand or polls it continuously. Values arrive as
plain numbers, and the coded fields are annotated with their meaning, so that
a state of 5 is shown as full throttle and an event of 2 as a crash. The
writable parameters are shown and edited in a separate panel.
@sec:pid-tuning describes the tuning workflow that uses it.

== Session Logging <sec:session-logging>

The testsuite can record a run in two ways. Both write plain-text JSON files
with one record per line.

- A continuous run log captures timestamped telemetry and pose at the
  streaming rate for the whole run. It covers both the parameter and sensor
  fields that the car reports, so an entire run, including unfinished laps,
  can be replayed field by field. Each new run overwrites the file.
- A complete-laps log appends one record per finished lap. Each record carries
  the lap time and its sector splits, the position trace, the active PID
  gains, and the sensor readings.

The telemetry in both logs comes from the fields that the firmware exposes.
The logging itself, together with the lap timing and pose data it draws on, is
part of the testsuite.

== Using GET/SET Commands for On-the-Fly PID Tuning <sec:pid-tuning>

The text protocol has two commands for the telemetry fields. `GET` reads a
field and `SET` writes one. A `GET` names a single field and returns its
value. It can also name a whole group, namely all fields, only the parameters,
or only the sensors, and then returns each field of that group in turn. A
`SET` names a writable field and a value. Only fields in the parameters table
accept a `SET`, so write access from outside is limited to the parameters.

Every `SET` is validated on the car before it takes effect. The firmware
parses the value and requires the whole token to be a valid number. It then
checks that the value is finite and within a fixed range. A value that passes
is written, and the car replies `OK`. A value that fails leaves the field
unchanged, and the car replies with an error. Because the check runs on the
car, only a valid value ever reaches a parameter.

Live tuning follows from this mechanism. The steering and throttle PID gains
are parameters, and @sec:actuator-control describes how the state machine
reloads them at the start of every tick. A gain written over the link
therefore takes effect on the next control step, without a rebuild and without
a reflash. The operator can adjust the car while it drives and observe the
result immediately.

== Workflow: From Firmware Build to On-Track Parameter Tuning <sec:workflow>

The individual pieces combine into a build, test, and tune loop.
@fig:workflow shows its five stages and the two paths that close it.

A firmware change starts with a build. The STM32 project is compiled to a
binary image and transferred to the car over WiFi. A new image therefore
requires no wired debugger, provided the board has been brought up with one
once. With the image running, the car is started on the track and drives
autonomously in the AI-MotionLab. Its telemetry streams back to the testsuite
through the live table, the map, and the logs.

The control parameters are tuned within the running image. The PID gains are
written with `SET` while the car drives and take effect on the next control
step. Each change is captured in the session log next to the telemetry, so
that its effect can be compared across runs. Only a change to the firmware
logic itself requires another build and a fresh flash.

#figure(
  image("/assets/graphics/selfdrawn/tuning_workflow.svg", width: 100%),
  caption: [Build, test, and tune loop, with fast parameter tuning and a
  slower firmware rebuild path],
) <fig:workflow>