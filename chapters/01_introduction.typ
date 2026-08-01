#import "@preview/glossarium:0.5.10": gls, glspl

= Introduction <ch:introduction>

== Motivation and Context <sec:motivation>

Embedded systems are easier to learn by building something concrete and
fun, not just isolated exercises on a devboard. Within the Electronics and
Computer Engineering (ECE) programme at FH JOANNEUM, CrazyCar is that
concrete project. It is a small, autonomous 1/18-scale racing car that
gives students one complex system to work on, namely sensing the
environment, actuating steering and throttle and reacting in real time.
Iteration cycles stay short, and the hardware is cheap to replace broken parts.

The third-semester "Embedded Systems" lecture uses that same CrazyCar as
its lab vehicle. Students build a layered (#gls("hal"), #gls("dl"),
#gls("al")) firmware stack for it on an MSP430F5335 microcontroller as a
single-semester lab exercise. It covers #gls("gpio"), timers, #gls("pwm"),
#gls("spi") and a distance-sensor driver as well as a first driving state
machine with #gls("pid") control @OkornDiererMayerES. That
generation of the platform was built to teach embedded systems fundamentals
within one semester. Within that scope, the application layer, the state
machine and #gls("pid") control students build in the last part of the course, can
already be tuned to some degree, but only the slow and manual way. Changing
a gain means editing code, recompiling, and reflashing over a wired
debugger session, and there is no infrastructure to gather quantifiable,
repeatable performance data across many runs.

This thesis is about modernizing that platform lineage into one that
supports this kind of ongoing, research-grade testing and tuning.
The chassis and main #gls("pcb") have already moved to a newer
hardware baseline built around an STM32H533RE microcontroller
(@sec:crazycar-history, @ch:hardware). This thesis gives that hardware
baseline its first application firmware, brings the board up, and debugs
the problems that surfaced along the way. It also connects the platform to
FH JOANNEUM's AI-MotionLab for the first time, a shared test infrastructure
that can observe a car on track without instrumenting the track itself
(@sec:ai-motionlab-role).
This thesis defines modernizing the platform in three parts. First, the new
firmware must drive the car autonomously. Second, it must expose its
internal state and parameters at runtime. Third, #gls("pid") gains for steering and
throttle control are rarely correct on the first attempt, so they need to  
be able to be tuned in a reproducible way, and the platform must support 
that tuning workflow.


== The CrazyCar Project <sec:crazycar-history>

CrazyCar is FH JOANNEUM's name for a small, sensor-driven car that drives
itself autonomously around a track. It is not a single, fixed
design. Chassis, main #gls("pcb"), and microcontroller have all changed between
iterations of the project, from the MSP430-based lab exercise discussed
above (@sec:motivation) to the platform this thesis works with. What stays
constant is the basic idea, namely a four-wheel-drive, 1/18-scale car that
senses its surroundings, decides how to steer and accelerate, and races
around a course on its own.

The specific instance this thesis builds firmware for is built on an XRAY
M18 Pro LiPo 4WD chassis (@ch:hardware, @sec:chassis), a commercially
available 1/18-scale RC chassis chosen for its robustness and ready
availability of spare parts, properties that matter when a fleet of cars is
driven by students and expected to survive repeated crashes. The main
#gls("pcb") was designed by A. Läßer specifically for this STM32-based generation of
the platform and is documented separately by its original author
@LaesserXRayLegacy2023. This thesis is the first to bring that board up and
test it; redesigning it is explicitly out of scope (@sec:non-goals). The
work described here starts from that hardware baseline, a Nucleo-H533RE
board (STM32H533RE microcontroller) mounted on that #gls("pcb") together with its
sensor and actuator peripherals, and develops the application firmware for
it from the ground up.

== The AI-MotionLab Testsuite <sec:ai-motionlab-role>

The AI-MotionLab itself is just the lab, a shared OptiTrack motion-capture
facility that FH JOANNEUM's Electronic Engineering Institute runs as
research infrastructure. The "Automated Testsuite" is a separate piece of
software built on top of that lab, a PySide desktop application that
renders a live map of the track and the cars on it, logs events during a
run, and lets a user send commands to a car over WiFi. A colleague
developed the testsuite alongside this thesis's firmware, in parallel
so the two projects grew together. The parts of the
testsuite relevant to this thesis are the ones the STM32 firmware talks to
directly, primarily the car communication module that issues text commands
over the wireless bridge (@ch:integration). Track geometry used by the
testsuite is supplied manually, as a hand-authored map of the room and lap and segment
timing is computed by testsuite logic that the same colleague implemented.
Both are used in this thesis as existing infrastructure the evaluation in
@ch:evaluation builds on, not as contributions of this work; @sec:non-goals
makes this boundary explicit.

== Problem Statement <sec:problem-statement>

The new CrazyCar hardware baseline (STM32H533RE, its #gls("pcb"), the sensor and
actuator suite in @ch:hardware) had no application firmware of its own.
Sensor drivers, actuation control, autonomous driving logic, and the
communication path to the AI-MotionLab all needed to be designed and
implemented before the platform could be driven, let alone tuned or
evaluated. At the same time, developing that firmware without a way to
observe its behavior and adjust its parameters without a wired debugger
session would make iterating on control-loop tuning and turn detection
slow and hard to reproduce between runs. This thesis addresses both
problems together. It builds the STM32 firmware the CrazyCar platform needs
to drive autonomously, and it builds that firmware so that its parameters
and telemetry are readable and writable at runtime and its images are
updatable over the air, so that the existing AI-MotionLab infrastructure can
be used to tune and evaluate it reproducibly.

== Goals <sec:goals>

The goals of this thesis are:

- Implement drivers and integration for the platform's sensor and actuator
  peripherals, including time-of-flight distance sensors, an inertial
  measurement unit, an external #gls("adc"), a Hall-effect speed sensor,
  and the motor and steering actuation hardware.
- Provide a flag-based event mechanism in the firmware's state machine, so
  that conditions such as a crash, a low battery, or the car getting stuck
  can be detected and acted on without polling every sensor from every
  state.
- Develop application firmware for the new CrazyCar hardware baseline
  (STM32H533RE) that drives the car autonomously around a track.
- Implement the firmware side of an automated test and tuning platform,
  with runtime-readable and runtime-writable telemetry and parameter
  fields and an over-the-air firmware update path, so that the AI-MotionLab
  testsuite can observe and tune the car without a wired connection.
- Evaluate the resulting platform and report the findings, including
  oversights found in the #gls("pcb") design during that evaluation.

== Non-Goals <sec:non-goals>

The following are explicitly out of scope for this thesis:

- #gls("pcb") design for the CrazyCar platform. The main #gls("pcb") was designed by someone
  else specifically for this platform generation (@sec:main-pcb,
  @LaesserXRayLegacy2023). This thesis brings that board up, evaluates it,
  and reports oversights found while testing (@sec:pcb-impact-summary), but
  does not redesign it.
- Modifications to the AI-MotionLab itself, including its OptiTrack setup
  and the PySide testsuite application beyond the firmware-facing
  communication path described in @ch:integration.

== Thesis Structure <sec:thesis-structure>

@ch:hardware describes the hardware baseline this firmware runs on, namely
the chassis, the main #gls("pcb"), the STM32H533RE microcontroller, the
sensor suite, and the motor drivers, together with the #gls("pcb") oversights found
during this work. @ch:firmware-sensors and @ch:firmware-state-machine cover
the firmware itself, application structure, sensor drivers, and actuator
control in the former, and the driving state machine, its flag-based event
mechanism, and the turn detection algorithm in the latter.
@ch:integration explains how that firmware connects to the AI-MotionLab
testsuite from the firmware side, the telemetry and parameter fields it
exposes and the text commands it answers, describing the testsuite itself
only as far as needed for that context. @ch:evaluation reports on the
platform's sensor performance, state machine and turn detection behavior,
and the usability of the tuning workflow, including the impact of the
#gls("pcb") oversights on testing. @ch:discussion interprets those results, discusses
the current implementation's limitations, and reflects on lessons learned,
and @ch:conclusion summarizes the thesis's contributions and closes with
final remarks.
