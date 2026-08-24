CrazyCar is a small autonomous racing car used for teaching and research on
embedded systems at FH JOANNEUM. This thesis develops the application firmware
for a new hardware generation of that platform, built around an STM32H533RE
microcontroller, and connects it to the AI-MotionLab, a motion-capture facility
that serves as a shared test environment.

The firmware brings up the platform's sensors and actuators. On the input side
it drives a set of time-of-flight distance sensors, an inertial measurement
unit, an external ADC, and a Hall-effect wheel-speed sensor. On the output side
it controls the drive motor and the steering. On top of these, a finite state
machine drives the car autonomously around a track. It detects corners from the
rate of change of the side distance sensors, steers through them, and reacts to
a crash, a stuck car, or a low battery through a flag-based event mechanism.

To make the car testable and tunable, the firmware exposes its telemetry and
control parameters as named fields that can be read and written at runtime, and
it can be reflashed over the air. This lets the AI-MotionLab testsuite observe
the car and adjust its PID gains while it drives, so a change takes effect on
the next control step without a rebuild or a wired connection. Bringing up the
previously untested hardware also surfaced several design oversights on the main
board, which are documented as part of the evaluation.

The result is a CrazyCar platform that drives autonomously and supports a fast,
reproducible test and tuning workflow, replacing the slow edit, compile, and
reflash cycle of the earlier generation.