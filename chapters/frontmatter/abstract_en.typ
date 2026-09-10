CrazyCar is a small autonomous racing car used for teaching and research on
embedded systems at FH JOANNEUM. This thesis develops the application firmware
for a new hardware generation of that platform, built around an STM32H533RE
microcontroller, and connects it to the AI-MotionLab, a motion-capture facility
that serves as a shared test environment.

The firmware brings up the sensors and actuators of the platform. On the input
side it reads three time-of-flight distance sensors, an inertial measurement
unit, an external ADC, and a Hall-effect wheel-speed sensor. On the output side
it controls the drive motor and the steering. Above these drivers, a finite
state machine drives the car autonomously around a track. It detects corners
from the distance-normalized rate of change of the side distance readings and
steers through them. A flag-based event mechanism handles a crash, a stuck car,
or a low battery.

To make the car testable and tunable, the firmware exposes its telemetry and
control parameters as named fields that can be read and written at runtime, and
it can be reflashed over the air. The AI-MotionLab testsuite can therefore
observe the car and adjust its PID gains while the car drives, so that a change
takes effect on the next control step without a rebuild or a wired connection.
The bring-up of the previously untested hardware also revealed several design
oversights on the main board, which are documented as part of the evaluation.

The result is a CrazyCar platform that drives autonomously and supports a fast,
reproducible test and tuning workflow, replacing the slow edit, compile, and
reflash cycle of the earlier generation. Across the recorded runs, 134 of 137
laps were valid. At one speed setting the lap time averaged 10.55 s with a
standard deviation of 0.10 s.