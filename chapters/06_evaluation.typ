#import "/helpers/lib.typ": fhjtable

= Evaluation <ch:evaluation>

== Evaluation Methodology <sec:eval-methodology>

The firmware was evaluated in on-track runs in the AI-MotionLab. Each run
drove the autonomous loop over the manually defined circuit described in
@sec:ai-motionlab-role. Telemetry streamed back through the GET/SET protocol
during every run. The session logs of the testsuite captured it for later
review, alongside the position of the car as measured by the OptiTrack system
of the laboratory. That position is independent of the dead reckoning that the
firmware computes on board.

The recorded material comes from the complete-laps logs described in
@sec:session-logging and holds 137 laps recorded between July and August 2026.
One of these logs, kept over one week of testing, contributes 70 laps. That is
the largest set driven, so it provides the path and timing
results in @sec:turn-performance. Within those 70 laps, 59 share one speed
setting and support the timing comparison.
The remaining laps come from shorter runs at other speed settings
and enter only the lap completion count. All 137 laps were driven on the same
circuit.

The evaluation is largely qualitative. Sensor readings were judged by inspecting the
logged telemetry for stable and plausible values. @sec:sensor-performance
reports the behavior observed in these logs. Turn detection and state machine
behavior were assessed in the same way, by observing repeated runs and noting
where a corner was missed or falsely triggered. The usability of the tuning
workflow was judged against the wired-debugger reflash cycle that this project
used before the GET/SET protocol was in place. @sec:workflow describes the
workflow that replaced it. Lap timing and lap validity recorded by the
testsuite provide the quantitative measures. @sec:turn-performance reports them.

== Sensor Performance <sec:sensor-performance>

The front ToF sensor, running at 33 Hz with its narrow 4 × 4 ROI, reached a
maximum usable range of 2.9 m on the track. Within that range
its readings were stable and plausible throughout testing. The car has a low
ride height, and even the minimum 15° FoV of the 4 × 4 ROI still receives
ground reflections at longer range. A longer timing budget and a wider ROI
both left this limit unchanged, so it follows from the mounting height of the
sensor rather than from its timing or ROI settings.

The side ToF sensors range over much shorter distances and performed well
throughout testing. Their ROI was settled during the evaluation rather than
fixed beforehand. It was first narrowed from the full 16 × 16 SPAD array to
8 × 8, and then widened to the 10 × 10 of the short mode described in
@sec:tof. The wider window keeps enough of the field of view on the wall
beside the car. The corner-slope detection from @sec:turn-rate-threshold
remained stable on the final readings, and neither sensor showed issues.

The IMU held a stable heading and yaw rate across all runs. The only deviation
observed was a small negative offset on the linear acceleration Z axis. It
resembles a residual gravity component, which the accelerometer, gyroscope,
and magnetometer inputs of the fusion algorithm should already remove. The X
and Y linear acceleration axes remained stable and showed no such offset. The
firmware does not read the Z axis, so the offset had no effect on driving.

The ADC readings for battery voltage and motor current were stable and
plausible throughout the evaluation. The battery voltage was additionally
compared against a multimeter, which confirmed the divider conversion
described in @sec:adc-handling.

== State Machine and Turn Detection Performance <sec:turn-performance>

Corner detection was reliable across the evaluation runs. Both the 90° corners
and the 180° hairpins targeted by the exit grid in @sec:completion-criteria
were detected. The side ToF ROI changes reported in @sec:sensor-performance
shifted the readings of the sensors. The slope threshold from
@sec:turn-rate-threshold had to be retuned with them, and every corner on the
track was detected after that retuning.

@fig:lap-overlay overlays the tracked path of those 70 laps on the manually
defined circuit from @sec:ai-motionlab-role. They were driven across several
sessions and at different tuning states. Through every 90° corner and
both hairpins the paths form a narrow bundle, so detection and the exit
behavior that follows it repeated consistently.

#figure(
  image("/assets/graphics/selfdrawn/lap_path_overlay.svg", width: 100%),
  caption: [Path of 70 laps measured by the OptiTrack system, overlaid on the circuit outline],
) <fig:lap-overlay>

Lap timing from the same runs quantifies that consistency. Of the 70 laps, 59
were driven at one speed setting. Four of those contain short gaps in the
tracking data, where the car moved further than the recorded positions
account for, so @tbl:lap-consistency covers the remaining 55.
Lap time averaged 10.54~s with a standard deviation of 0.09 s, about one
percent of the mean. The driven distance averaged 15.31 m with a standard
deviation of 0.12 m. The remaining 11 laps were driven at several lower
settings. They covered the same distance at average speeds from 0.72 m/s to
1.05 m/s, against 1.45 m/s at the higher setting. All 11 were valid, and the
detection threshold from @sec:turn-rate-threshold was unchanged throughout.
Corner detection therefore held on a single threshold across speeds that differ
by a factor of two.

#figure(
  fhjtable(
    tabledata: (
      ("Measure", "Mean", "Standard deviation", "Range"),
      ("Lap time", "10.54 s", "0.09 s", "10.34 to 10.78 s"),
      ("Driven distance", "15.31 m", "0.12 m", "15.04 to 15.59 m"),
      ("Average speed", "1.45 m/s", "0.01 m/s", "1.43 to 1.48 m/s"),
    ),
    columns: 4,
  ),
  kind: table,
  caption: [Lap consistency across the 55 gap-free laps driven at one speed setting],
) <tbl:lap-consistency>

Lap validity provides a completion measure across every recorded session.
Across all 137 laps, the lap timing of the testsuite marked 134 as
valid. A lap is valid only when the car crosses every sector boundary in order,
without reversing or skipping one. Of the three invalid laps, two cover well
beyond the usual lap distance and one ends after the first sector.

`CAR_RECOVER`, introduced in @sec:flag-events, was the least refined of the
driving states. Freeing a stuck car sometimes took two or three attempts,
although the car freed itself in most cases. Refining recovery further was
given a lower priority, because the tuning workflow already repositions a car
through `CAR_POINT_FOLLOW` when a lap fails, rather than relying on recovery
to complete the lap.

== Operator Mode Performance <sec:operator-mode-performance>

The two operator-driven modes from @sec:operator-modes both performed well.
`CAR_REMOTE_CONTROL` operated without issue, since it passes the steering and
speed setpoints of the operator through unchanged.

`CAR_POINT_FOLLOW` tracked its path well. @fig:point-follow shows a run in
which the car reached a commanded goal pose over a path with two direction
changes. The driven trajectory stays close to the planned path, with a small
drift on the straight following a corner. The wheel-speed sensor from @sec:hall
is mounted on a single rear wheel, so the dead-reckoned pose behind the
pure-pursuit follower cannot account for the inner and outer rear wheels
turning at different rates through a corner. Calibration removed most of this
drift, but a small amount remained.

#figure(
  image("/assets/pictures/drive_to_pose.png", width: 100%),
  caption: [Planned and driven path of a point-follow run in the AI-MotionLab],
) <fig:point-follow>

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

=== Missing Footprint for the WiFi Bridge <sec:pcb-esp8266>

The main PCB was laid out before wireless communication with the car was
foreseen, so it provides no footprint for the WiFi bridge from
@sec:esp-bridge. The need for such a bridge became clear once both this
thesis and Benedikt Polivka's thesis @PolivkaTestsuite2026 required one. This
thesis needed it for OTA updates and telemetry, and the testsuite needed it
for its live link to the car. The D1 mini board was therefore added
afterward. It is wired directly into the Arduino-style headers of the Nucleo
board rather than fitted to a dedicated footprint on the main PCB.

=== STM32 Pin Layout <sec:pcb-pin-layout>

The Arduino-style headers of the main PCB were laid out for an Arduino UNO R4
pin arrangement, while the Nucleo-H533RE board from @sec:mcu is oriented in
the opposite direction. The Nucleo board therefore has to be seated upside
down. In that position its built-in Reset and User buttons press against the
main PCB, so both buttons had to be trimmed for the board to sit flush.

=== Missing Pulldown on the ESC INH Pin <sec:pcb-esc-pulldown>

The main PCB has no pulldown resistor on D6, the Nucleo header pin that
drives the shared INH input of the two BTN9970LV half-bridge drivers from
@sec:motor-drivers. The pin therefore floats until the GPIO initialization of
the firmware runs and drives it to a known level. This became visible during
debugging. Flashing over the wired debugger in VS Code halts the STM32 at
reset by default, before `HAL_Init()` runs. D6 floats during that pause, so
the motor driver reads it as enabled and the motor starts turning before any
firmware controls it.
