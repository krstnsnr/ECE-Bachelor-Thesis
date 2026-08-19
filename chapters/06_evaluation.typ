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

The front ToF sensor, running at about 33Hz with its narrow 4x4 ROI, reached a
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
// time-to-tune, workflow improvements vs. previous approach

== Summary of PCB Oversight Impact on Testing <sec:pcb-impact-summary>

=== Findings <sec:pcb-findings>
- Battery charging circuit unsuitable for LiIon/LiPo
- SDA/SCL swap needed for BNO055
- Missing ESP8266-12F on-board
- STM32 pin layout issue
- Missing pulldown on ESC INH pin

=== Recommendations for the Next PCB Revision <sec:pcb-recommendations>
