= Evaluation <ch:evaluation>

== Evaluation Methodology <sec:eval-methodology>

The firmware was evaluated through on-track runs in the AI-MotionLab, driving
the autonomous loop over the manually defined circuit described in
@sec:testsuite-architecture. Each run streamed telemetry back through the
GET/SET protocol, and the testsuite's session logs captured that telemetry
alongside the car's tracked position for later review.

The evaluation is qualitative. Sensor readings were judged by inspecting the
logged telemetry for stable, plausible values, so @sec:sensor-performance
reports behavior observed in these logs. Turn detection and state machine
behavior were assessed the same way, by watching repeated runs and noting
where a corner was missed or falsely triggered. The tuning workflow's
usability is judged against the wired-debugger reflash workflow that this
project used before the GET/SET protocol was in place, the same baseline
@ch:integration and @sec:workflow describe.

== Sensor Performance <sec:sensor-performance>

The front ToF sensor, running at about 30Hz with its narrow 4x4 ROI, reached a
maximum usable range of 2.9m on the track. Within that range its readings
were accurate and reliable throughout testing. The car sits low to the
ground, and even the minimum 15 degree FoV that the 4x4 ROI gives it still
catches ground reflections at longer range. Neither a longer timing budget
nor a wider ROI changed this, so the limit comes from the sensor's mounting
height rather than from its timing or ROI settings.

The side ToF sensors never have to range that far, and they performed well
throughout testing. Their 10x10 ROI, the same short-mode setting @sec:tof
describes and well short of the sensor's full 16x16 SPAD array, kept the
corner-slope detection from @sec:turn-rate-threshold stable, and no further
issues came up with either sensor.

The IMU held a stable heading and yaw rate across all runs. The one drift that
showed up was a small negative offset on the linear acceleration Z axis,
resembling leftover gravity that the fusion algorithm's own accelerometer,
gyroscope, and magnetometer inputs should already rule out. The X and Y
linear acceleration axes stayed stable with no such offset, and the firmware
never reads the Z axis, so the offset had no effect on driving.

The ADC readings, battery voltage and motor current alike, were accurate and
stable for the whole evaluation.

== State Machine / Turn Detection Performance <sec:turn-performance>

Corner detection was reliable across the evaluation runs, catching both the
90 degree corners and the 180 degree hairpins the exit grid in
@sec:completion-criteria targets. The side ToF ROI changes described in
@sec:sensor-performance shifted the sensors' readings enough that the slope
threshold from @sec:turn-rate-threshold needed retuning alongside them, and
once retuned, every corner on the track was detected cleanly.

`CAR_RECOVER`, introduced in @sec:flag-events, is the least refined of the
driving states. Freeing a stuck car sometimes took two or three attempts
rather than one, though the car worked itself free in most cases. Refining
recovery further took a lower priority in this project, since the tuning
workflow already repositions a car that fails a lap through
`CAR_POINT_FOLLOW`, covered next, rather than depending on recovery to
finish the lap itself.

The two operator-driven modes from @sec:operator-modes both performed well.
`CAR_REMOTE_CONTROL` worked without issue, since it only passes the
operator's steering and speed setpoints straight through. `CAR_POINT_FOLLOW`
also tracked its path well, with a small drift on the straight following a
corner. The wheel-speed sensor from @sec:hall sits on a single rear wheel,
so the dead-reckoned pose behind the pure-pursuit follower does not see the
inner and outer rear wheels turning at different rates through a corner.
Calibration removed most of this drift, but a small amount remained
noticeable.

== Usability of the Tuning Platform <sec:usability>

Tuning against the wired-debugger reflash baseline from @sec:eval-methodology
showed a clear qualitative improvement. Changing a PID gain no longer meant
editing code, rebuilding, and reflashing over a wired connection between
attempts. With the GET/SET workflow from @sec:pid-tuning, a gain change took
effect on the next control step while the car kept driving, so its effect on
the current lap was visible immediately. Chained across a session as
@sec:workflow describes, this let a gain be adjusted, driven, and judged
several times over in the time a single reflash cycle used to take, and the
workflow held up without friction throughout the evaluation.

Changes to the state machine itself still need a rebuild and a flash, but
even that step was faster over WiFi than the wired-debugger baseline. A wired
reflash meant taking the car's cover off, connecting the debugger, closing
the cover back up, and putting the car back on the track before the next run
could start. Sending the same build over the air, as @sec:workflow describes,
skipped that whole routine, so even a firmware-logic iteration reached the
track markedly faster than before.

== Summary of PCB Oversight Impact on Testing <sec:pcb-impact-summary>

=== Battery Charging Circuit <sec:pcb-battery-charging>

The main PCB from @sec:main-pcb carries an onboard charging circuit, fed
through a USB-C connector, built for the six-cell NiMH battery pack that was
standard on the platform when the board was designed. Partway through this
project the platform moved to a self-built two-cell 18650 Li-Ion pack
instead, for its higher capacity and longer run time and because its shape
fits the chassis's battery compartment far better than the six-cell NiMH pack
did. NiMH and Li-Ion cells need different charge voltages and currents, so
the onboard circuit built for the old NiMH pack cannot charge the Li-Ion pack
the platform now runs on, and charging has to happen off the car with an
external charger instead.

=== SDA/SCL Swap for the BNO055 <sec:pcb-sda-scl>

On the main PCB, the BNO055's SDA and SCL lines to the shared I2C1 bus from
@sec:i2c-stack are swapped, with each wired to the other signal's pin.
Bringing up the sensor on the prototype board meant cutting both traces and
bridging them back across with a short length of solder wire, restoring SDA
and SCL to their correct pins so the IMU from @sec:imu could join the bus
like the other I2C1 devices.

=== Missing ESP8266-12F <sec:pcb-esp8266>

The main PCB was laid out before wireless communication with the car was
part of the plan, so it has no place for the WiFi bridge from
@sec:esp-bridge. The need for one became clear once this thesis and
Benedikt Polivka's thesis @PolivkaTestsuite2026 both called for it, this thesis for OTA
updates and telemetry, his for the AI-MotionLab testsuite's live link to the
car. The D1 mini board was added afterwards, wired directly into the Nucleo
board's Arduino-style headers rather than fitted to a dedicated footprint on
the main PCB.

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

=== Recommendations for the Next PCB Revision <sec:pcb-recommendations>

The charging circuit from @sec:pcb-battery-charging should be redesigned
around the 2S 18650 Li-Ion pack the platform now runs on, with a charge
voltage and current profile that matches Li-Ion cells instead of the
original six-cell NiMH pack.

The SDA/SCL swap from @sec:pcb-sda-scl is a straightforward layout fix. The
next revision only needs to route those two traces to their correct pins on
the BNO055, so the sensor comes up correctly without a bodge wire.

The next PCB revision should give the ESP8266 module a proper on-board
place, still behind a jumper that can disconnect the STM32-ESP8266 bus
entirely, since the Crazy Car race rules forbid wireless communication
during the race itself and the link is meant for testing and tuning, not for
the car's competition runs.

A pulldown resistor on D6 belongs on the next revision too, so the INH input
from @sec:pcb-esc-pulldown starts low and keeps the motor disabled until the
firmware itself enables it.

The pin layout deserves a broader revisit too. Mounting the Nucleo board
right side up would let it sit better under the car's cover. The main PCB
currently exposes only the Arduino Uno R4 header set, and the Nucleo board's
ST Morpho headers, which break out the STM32's remaining pins, should be
connected as well. The Hall sensor connector carries four pins, but
only three of them reach the STM32, and the wheel-speed sensor from
@sec:hall is a four-pin part that also reports direction, so the connector
should break out all four. The ESP8266 link should also stay off the pins
outside that Arduino header footprint, since routing it there gives up
access to those extra pins on the Nucleo board without any benefit.
