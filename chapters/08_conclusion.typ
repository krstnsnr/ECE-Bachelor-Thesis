#import "/helpers/gls.typ": gls, glspl

= Conclusion <ch:conclusion>

== Summary of Contributions <sec:contributions>

This thesis provided the first application firmware for the STM32-based
CrazyCar hardware baseline from @sec:crazycar-history, brought up the main
#gls("pcb"), and made that firmware observable and tunable through the
AI-MotionLab integration that Benedikt Polivka built alongside it
@PolivkaTestsuite2026. Against the goals set out in @sec:goals, the work
delivered the following results:

- Sensor and actuator drivers for the full peripheral set of the platform,
  described in @ch:hardware and @ch:firmware-sensors, namely the three
  VL53L1X #gls("tof") sensors, the BNO055 #gls("imu"), the ADS7128
  #gls("adc"), the TLE4966L wheel-speed sensor, and the BTN9970LV motor
  drivers together with the steering servo.
- A flag-based event mechanism, described in @sec:flag-events, that detects
  a low battery, a crash, or a stuck car and removes the need for each state
  to poll every sensor.
- A finite state machine, described in @ch:firmware-state-machine, that
  drives the car autonomously around the track. It includes a
  distance-normalized turn detector for both the 90° corners and the 180°
  hairpins from which the track is built, and two operator-driven modes for
  manual and path-following control.
- Telemetry and parameter fields for the sensors, the driving state, and the
  #gls("pid") gains of the platform, described in @ch:integration. They are
  exposed through the GET/SET protocol and over-the-air update path that
  Benedikt Polivka built alongside this firmware @PolivkaTestsuite2026, and
  they let the AI-MotionLab testsuite observe and tune the car over WiFi
  rather than over a wired debugger connection.
- An evaluation of the resulting platform, reported in @ch:evaluation, that
  covers sensor and state machine performance, the usability of the tuning
  workflow, and the #gls("pcb") oversights found while bringing the board
  up. Across 137 recorded laps, 134 were valid, and at one speed setting the
  lap time averaged 10.54 s with a standard deviation of 0.09 s.

Together these results close the gap identified by the problem statement in
@sec:problem-statement. The CrazyCar hardware baseline now has firmware that
drives it autonomously. That firmware exposes its sensor data, state, and
#gls("pid") gains as telemetry and parameter fields that the protocol reads
and writes at runtime @PolivkaTestsuite2026. The AI-MotionLab infrastructure
built around it can therefore evaluate and tune the platform without the slow
wired iteration loop of the earlier MSP430-based platform in @sec:motivation.

== Final Remarks <sec:final-remarks>

The CrazyCar lineage introduced in @sec:crazycar-history began as a teaching
lab exercise on the MSP430F5335, tuned by hand over a wired debugger session.
This thesis carries that lineage onto research-grade hardware and connects
its firmware to a matching test and tuning workflow. The sensor, actuator,
and state machine architecture remains the one that a student on the original
course would recognize.

The evaluation in @ch:evaluation and the discussion in @ch:discussion also
mark out the next steps. @sec:pcb-recommendations lists the main #gls("pcb")
changes for the next revision, from a charging circuit matched to the current
Li-Ion pack of the platform to a four-pin wheel-speed connector that would
let `CAR_POINT_FOLLOW` account for both rear wheels. `CAR_RECOVER` remains
the least refined driving state and would benefit from further tuning. The
evaluation also covered only the one circuit that the testsuite has mapped,
so running the platform on other track layouts remains an open task.

This thesis leaves a CrazyCar that can be driven, observed, and tuned
entirely from a laptop at the side of the track. The main #gls("pcb") it runs
on has been brought up and documented for the first time. Together these make
the platform ongoing research infrastructure rather than a single bring-up
exercise, ready for the next student, thesis, or CrazyCar competition team
to build on.
