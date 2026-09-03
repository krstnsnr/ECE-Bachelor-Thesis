= Evaluation <ch:evaluation>

== Evaluation Methodology <sec:eval-methodology>

The firmware was evaluated in on-track runs in the AI-MotionLab. Each run
drove the autonomous loop over the manually defined circuit described in
@sec:ai-motionlab-role. Telemetry streamed back through the GET/SET protocol
during every run, and the session logs of the testsuite captured it alongside
the tracked position of the car for later review.

The evaluation is qualitative. Sensor readings were judged by inspecting the
logged telemetry for stable and plausible values. @sec:sensor-performance
reports the behavior observed in these logs. Turn detection and state machine
behavior were assessed in the same way, by observing repeated runs and noting
where a corner was missed or falsely triggered. The usability of the tuning
workflow was judged against the wired-debugger reflash cycle that this project
used before the GET/SET protocol was in place. @sec:workflow describes the
workflow that replaced it.

== Sensor Performance <sec:sensor-performance>

The front ToF sensor, running at 33 Hz with its narrow 4 × 4 ROI, reached a
maximum usable range of 2.9 m on the track. Within that range
its readings were accurate and reliable throughout testing. The car has a low
ride height, and even the minimum 15° FoV of the 4 × 4 ROI still receives
ground reflections at longer range. A longer timing budget and a wider ROI
both left this limit unchanged, so it follows from the mounting height of the
sensor rather than from its timing or ROI settings.

The side ToF sensors range over much shorter distances and performed well
throughout testing. They use the 10 × 10 ROI of the short mode described in
@sec:tof, which reads a subset of the full 16 × 16 SPAD array. The
corner-slope detection from @sec:turn-rate-threshold remained stable on these
readings, and neither sensor showed further issues.

The IMU held a stable heading and yaw rate across all runs. The only deviation
observed was a small negative offset on the linear acceleration Z axis. It
resembles a residual gravity component, which the accelerometer, gyroscope,
and magnetometer inputs of the fusion algorithm should already remove. The X
and Y linear acceleration axes remained stable and showed no such offset. The
firmware does not read the Z axis, so the offset had no effect on driving.

The ADC readings for battery voltage and motor current were accurate and
stable throughout the evaluation.

== State Machine / Turn Detection Performance <sec:turn-performance>

Corner detection was reliable across the evaluation runs. Both the 90° corners
and the 180° hairpins targeted by the exit grid in @sec:completion-criteria
were detected. The side ToF ROI changes reported in @sec:sensor-performance
shifted the readings of the sensors. The slope threshold from
@sec:turn-rate-threshold had to be retuned with them, and every corner on the
track was detected after that retuning.

`CAR_RECOVER`, introduced in @sec:flag-events, was the least refined of the
driving states. Freeing a stuck car sometimes took two or three attempts,
although the car freed itself in most cases. Refining recovery further was
given a lower priority, because the tuning workflow already repositions a car
through `CAR_POINT_FOLLOW` when a lap fails, rather than relying on recovery
to complete the lap.

The two operator-driven modes from @sec:operator-modes both performed well.
`CAR_REMOTE_CONTROL` operated without issue, since it passes the steering and
speed setpoints of the operator through unchanged. `CAR_POINT_FOLLOW` also
tracked its path well, with a small drift on the straight following a corner.
The wheel-speed sensor from @sec:hall is mounted on a single rear wheel, so
the dead-reckoned pose behind the pure-pursuit follower cannot account for the
inner and outer rear wheels turning at different rates through a corner.
Calibration removed most of this drift, but a small amount remained.

== Usability of the Tuning Platform <sec:usability>

Compared with the wired-debugger reflash baseline from @sec:eval-methodology,
the tuning workflow showed a clear qualitative improvement. With the GET/SET
workflow from @sec:pid-tuning, a gain change took effect on the next control
step while the car kept driving, so its effect on the current lap was visible
immediately. Repeated across a session, this allowed a gain to be adjusted,
tested on track, and judged several times within the time that a single
reflash cycle required. The workflow was used without difficulty throughout
the evaluation.

Changes to the state machine itself still require a rebuild and a flash, but
even that step was faster over WiFi than in the wired-debugger baseline. A
wired reflash meant removing the cover of the car, connecting the debugger,
closing the cover, and placing the car back on the track before the next run
could start. Sending the same build over the air, as @sec:workflow describes,
removed these steps, so even a firmware-logic iteration reached the track
markedly faster.

== Summary of PCB Oversight Impact on Testing <sec:pcb-impact-summary>

=== Battery Charging Circuit <sec:pcb-battery-charging>

The main PCB from @sec:main-pcb carries an onboard charging circuit that is
fed through a USB-C connector. The circuit was built for the six-cell NiMH
battery pack that was standard on the platform when the board was designed.
Partway through this project the platform moved to a self-built two-cell
18650 Li-Ion pack. It offers a higher capacity and a longer run time, and its
shape fits the battery compartment of the chassis far better than the
six-cell NiMH pack. NiMH and Li-Ion cells require different charge voltages
and currents, so the onboard circuit charges only the original NiMH pack. The
Li-Ion pack that the platform now runs on is charged off the car with an
external charger.

=== SDA/SCL Swap for the BNO055 <sec:pcb-sda-scl>

On the main PCB, the SDA and SCL lines of the BNO055 to the shared I2C1 bus
from @sec:i2c-stack are swapped, with each wired to the pin of the other
signal. Bringing up the sensor on the prototype board therefore required
cutting both traces and bridging them across with a short length of solder
wire. This restored SDA and SCL to their correct pins, so the IMU from
@sec:imu joined the bus in the same way as the other I2C1 devices.

=== Missing ESP8266-12F <sec:pcb-esp8266>

The main PCB was laid out before wireless communication with the car was
foreseen, so it provides no footprint for the WiFi bridge from
@sec:esp-bridge. The need for such a bridge became clear once both this
thesis and Benedikt Polivka's thesis @PolivkaTestsuite2026 required one. This
thesis needed it for OTA updates and telemetry, and the testsuite needed it
for its live link to the car. The D1 mini board was therefore added
afterwards. It is wired directly into the Arduino-style headers of the Nucleo
board rather than fitted to a dedicated footprint on the main PCB.

=== STM32 Pin Layout <sec:pcb-pin-layout>

The main PCB's Arduino-style headers were laid out for an Arduino Uno R4 pin
arrangement, while the Nucleo-H533RE board from @sec:mcu mounts the other
way round. Fitting the Nucleo board to the main PCB therefore means seating
it upside down rather than right side up. Mounted that way, the Nucleo's
built-in Reset and User buttons land where the main PCB gets in the way, so
both buttons had to be trimmed down to make the board fit.

=== Missing Pulldown on the ESC INH Pin <sec:pcb-esc-pulldown>

The main PCB has no pulldown resistor on D6, the Nucleo header pin that
drives the shared INH input of the two BTN9970LV half-bridge drivers from
@sec:motor-drivers. Without one, the pin floats until the firmware's GPIO
initialization runs and drives it to a known level. This showed up directly
during debugging. Flashing over the wired debugger in VS Code halts the STM32
at reset by default, before `HAL_Init()` runs, and D6 floats in that pause,
so the motor driver reads it as enabled and the motor starts turning with no
code yet in control of it.
