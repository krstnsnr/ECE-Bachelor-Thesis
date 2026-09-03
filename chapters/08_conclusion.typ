#import "/helpers/gls.typ": gls, glspl

= Conclusion <ch:conclusion>

== Summary of Contributions <sec:contributions>

This thesis gave the STM32-based CrazyCar hardware baseline from
@sec:crazycar-history its first application firmware, brought the main
#gls("pcb") up, and made that firmware observable and tunable through the
AI-MotionLab integration Benedikt Polivka built alongside it
@PolivkaTestsuite2026. Against the goals set out in @sec:goals, the work
delivered:

- Sensor and actuator drivers for the platform's full peripheral set,
  covered in @ch:hardware and @ch:firmware-sensors, namely the three VL53L1X
  #gls("tof") sensors, the BNO055 #gls("imu"), the ADS7128 #gls("adc"), the
  TLE4966L wheel-speed sensor, and the BTN9970LV motor drivers together with
  the steering servo.
- A flag-based event mechanism, described in @sec:flag-events, that detects
  a low battery, a crash, or a stuck car without every state polling every
  sensor itself.
- A finite state machine, covered in @ch:firmware-state-machine, that drives
  the car autonomously around the track, including a distance-normalized
  turn detector that finds both the 90° corners and 180°
  hairpins the track is built from, and two operator-driven modes for
  manual and path-following control.
- Telemetry and parameter fields for the platform's sensors, driving state,
  and #gls("pid") gains, exposed through the GET/SET protocol and
  over-the-air update path Polivka built alongside this firmware
  (@ch:integration) @PolivkaTestsuite2026, that let the AI-MotionLab
  testsuite observe and tune the car over WiFi instead of over a wired
  debugger connection.
- An evaluation of the resulting platform, reported in @ch:evaluation, that
  covers sensor and state machine performance, the tuning workflow's
  usability, and the #gls("pcb") oversights this thesis found while bringing
  the board up.

Together these close the gap the problem statement in @sec:problem-statement
identified. The CrazyCar hardware baseline now has firmware that drives it
autonomously, and that firmware exposes its sensor data, state, and
#gls("pid") gains as telemetry and parameter fields Polivka's protocol
reads and writes at runtime @PolivkaTestsuite2026, so the AI-MotionLab
infrastructure built around it can evaluate and tune the platform without
the slow, wired iteration loop the earlier MSP430-based platform in
@sec:motivation was limited to.

== Final Remarks <sec:final-remarks>

The CrazyCar lineage introduced in @sec:crazycar-history began as a
teaching lab exercise on the MSP430F5335, tuned by hand over a wired
debugger session. This thesis carries that lineage onto research-grade
hardware, and its firmware plugs into a test and tuning workflow to match,
without changing the sensor, actuator, and state machine architecture a
student on the original course would still recognize.

The evaluation in @ch:evaluation and the discussion in @ch:discussion also
leave a clear path for what comes next. @sec:pcb-recommendations lists the
main #gls("pcb") changes the next revision should carry, from a charging
circuit built for the platform's current Li-Ion pack to a four-pin
wheel-speed connector that would let `CAR_POINT_FOLLOW` see both rear
wheels instead of one. `CAR_RECOVER` remains the least refined driving
state and would benefit from further tuning, and the testsuite has so far
only driven the car on the one circuit it has mapped, so evaluating the
platform on other track layouts is an open task for whoever continues this
work.

What this thesis leaves behind is a CrazyCar that can be driven, observed,
and tuned entirely from a laptop on the side of the track, with the main
#gls("pcb") it runs on brought up and documented for the first time. That
combination is what turns the platform from a one-off bring-up exercise
into ongoing research infrastructure the next student, thesis, or
Crazy Car competition team can build on directly.
