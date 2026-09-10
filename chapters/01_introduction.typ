#import "/helpers/gls.typ": gls, glspl

= Introduction <ch:introduction>

== Motivation and Context <sec:motivation>

Embedded systems are easier to learn by building something concrete and
fun, not just isolated exercises on a development board. Within the Electronics and
Computer Engineering (ECE) programme at FH JOANNEUM, CrazyCar is that
concrete project. It is a small, autonomous 1/18-scale racing car that
gives students one complex system to work on, a car that senses the environment, actuates steering and throttle, and reacts in real time.

The third-semester "Embedded Systems" course uses that same CrazyCar as
its lab vehicle. Students build a layered (#gls("hal"), #gls("dl"),
#gls("al")) firmware stack for it on an MSP430F5335 microcontroller as a
single-semester lab exercise. It covers #gls("gpio"), timers, #gls("pwm"),
#gls("spi") and a distance-sensor driver as well as a first driving state
machine with #gls("pid") control @OkornDiererMayerES. That
generation of the platform was built to teach embedded systems fundamentals
within one semester. Students can already tune the state machine and #gls("pid") control they
build in the last part of the course, but only the slow and manual way. Changing parameters
means editing code, recompiling, and reflashing over a wired
debugger session, and there is no infrastructure to gather quantifiable,
repeatable performance data across many runs.

This thesis is about supporting this kind of ongoing, research-grade testing and tuning.
The chassis and main #gls("pcb") have already been migrated to a newer
hardware baseline built around an STM32H533RE microcontroller, introduced in
@sec:crazycar-history and described in @ch:hardware. The work presented here
provides the first application firmware for this baseline, covers the initial
board bring-up, and debugs the problems that surfaced along the way. It also connects the
platform to FH JOANNEUM's AI-MotionLab, and introduces a shared test
infrastructure described in @sec:ai-motionlab-role that can observe a car on
track without instrumenting the track itself.
This thesis approaches modernizing the platform in three parts. First, the new
firmware must navigate the car autonomously. Second, it should send its
internal state and parameters at runtime. Third, #gls("pid") gains for steering and throttle control have to be tunable in a reproducible way.


== The CrazyCar Project <sec:crazycar-history>

CrazyCar is FH JOANNEUM's name for a small, sensor-driven car that drives
itself autonomously around a track. It is not a single fixed
design but an MSP430-based platform that has been redesigned several times during
student projects up to its STM32-based version.
What stays constant is the basic idea, namely a four-wheel-drive, 1/18-scale car that
senses its surroundings, decides how to steer and accelerate, and races
around a course on its own.

The specific instance this thesis targets uses an XRAY
M18 Pro LiPo 4WD chassis, a commercially available 1/18-scale RC chassis
described in @sec:chassis. It was chosen for its robustness and the
availability of spare parts. The new main
#gls("pcb") was designed by Andreas Läßer especially for the STM32-based platform and is documented separately by its original author
@LaesserXRayLegacy2023. The
work described here starts from a given hardware configuration, a Nucleo-H533RE
board (STM32H533RE microcontroller) mounted on that #gls("pcb") together with its
sensor and actuator peripherals, and develops the application firmware for
it from the ground up.

== The AI-MotionLab Testsuite <sec:ai-motionlab-role>

The AI-MotionLab, a shared OptiTrack motion-capture laboratory run by FH JOANNEUM's Institute of Electronic Engineering as research infrastructure, serves as the development environment.
Built on the lab's tracking data, the "Automated Testsuite" is a PySide desktop application that renders a live map of the track and cars, logs run events and sends commands to a car over WiFi. The testsuite was developed by Benedikt Polivka @PolivkaTestsuite2026
in parallel with the firmware presented here, so the two projects grew together. The parts of the
testsuite relevant to this thesis are the telemetry and parameter fields that
the STM32 firmware exposes through the existing communication module,
described in @ch:integration. Track geometry used by the
testsuite is supplied manually, as a hand-authored map, and lap and segment
timing is computed by the testsuite logic as well.
Neither is a contribution of this work. Both are used as existing infrastructure on which the evaluation of @ch:evaluation builds. @sec:non-goals states this boundary explicitly.

== Problem Statement <sec:problem-statement>

The new CrazyCar hardware baseline had no application firmware. It consists of an STM32H533RE on a new #gls("pcb"), together with the sensor and actuator suite described in @ch:hardware. Sensor drivers, motor and steering control, the autonomous driving logic, and the link to the AI-MotionLab all had to be developed before the car could move.

A second problem follows from the first. Firmware whose behavior cannot be observed at runtime must be tuned over a wired debugger: the car is stopped, connected, reflashed, and tested again. Control-loop gains and turn detection require many such cycles, which makes tuning slow and results difficult to reproduce between runs.

This thesis addresses both. It develops the firmware required for autonomous driving on the new baseline, and extends the existing #gls("ota") link with telemetry output and adjustable parameters, so that behavior can be observed and changed while the car is running. This makes the AI-MotionLab usable for reproducible tuning and evaluation.


== Goals <sec:goals>

The goals of this thesis are:

- Implement and integrate drivers for the platform's sensor and actuator peripherals,
  including #gls("tof") distance sensors, an inertial
  measurement unit, an external #gls("adc"), a Hall-effect speed sensor,
  as well as the motor and steering actuation hardware.
- Provide a flag-based event mechanism in the firmware's state machine, so
  that conditions such as a crash, a low battery, or a stuck car can be detected and handled
  without polling every sensor from every
  state.
- Develop an application firmware for the new CrazyCar hardware baseline
  (STM32H533RE) that drives the car autonomously around a track.
- Add the telemetry and parameter interfaces required by the automated
  test and tuning platform, so that the testsuite can observe
  and tune the car over the existing communication and OTA
  update infrastructure.
- Evaluate the resulting platform and report the findings, including the #gls("pcb")
  design oversights identified during evaluation.

== Non-Goals <sec:non-goals>

The following are explicitly out of scope for this thesis:

- #gls("pcb") design for the CrazyCar platform. The main #gls("pcb") was
  designed for this hardware generation by Andreas Läßer
  @LaesserXRayLegacy2023, as @sec:main-pcb describes. This thesis brings
  that board up, tests it, and documents the design oversights that
  surfaced in the process, reported in @sec:pcb-impact-summary, but does
  not redesign it.
- Modifications to the AI-MotionLab itself, including its OptiTrack setup
  and the PySide testsuite.

== Thesis Structure <sec:thesis-structure>

@ch:hardware describes the underlying hardware baseline from the chassis and the main #gls("pcb") to the STM32H533RE microcontroller, the sensor suite, and the motor drivers. @ch:firmware-sensors describes the structure of the application, the sensor drivers, and actuator control. @ch:firmware-state-machine describes the driving state machine, its flag-based event mechanism, and the turn detection algorithm.
@ch:integration investigates the connection between firmware and the AI-MotionLab testsuite using the existing communication infrastructure, and which telemetry and parameter interfaces are used. The testsuite itself is covered only with respect to that context.
@ch:evaluation reports on the
platform's sensor performance, state machine and turn detection behavior,
as well as the usability of the tuning workflow, including the impact of the
#gls("pcb") oversights detected during testing.
These results are interpreted in @ch:discussion, together with the limitations of the current implementation and the lessons drawn from it. @ch:conclusion summarizes the contributions of this work.
