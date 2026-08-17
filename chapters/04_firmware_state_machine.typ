= Firmware Design: State Machine and Turn Detection (STM32) <ch:firmware-state-machine>

== State Machine Design <sec:state-machine>

=== Overview of States and Transitions <sec:states-transitions>

The driving logic is organized as a finite state machine. It runs once per
control-loop tick at 100Hz. Each tick does two things in order. It executes
the action of the current state, and it then evaluates the transition
conditions to decide which state runs on the next tick. The current state is
mirrored into a telemetry global on every change, so the PC side testsuite can
follow the car's behavior live.

Nine states are defined, listed here in the order the car normally moves
through them.

- `CAR_STOP` holds the motor at neutral and the steering centered. It is the
  power-on state and the state the car falls back to whenever driving must
  end.
- `CAR_START` is a short launch state that resets the steering and speed
  controllers before the car begins to move.
- `CAR_FULL_THROTTLE` follows the walls on an open stretch and scales its
  speed with the distance to the wall ahead.
- `CAR_STRAIGHT` follows the walls at a more moderate pace, used after a turn
  until the track opens up again.
- `CAR_TURN_LEFT` and `CAR_TURN_RIGHT` steer the car through a corner once an
  opening has been detected on that side.
- `CAR_RECOVER` reverses the car briefly to free it after a crash or when it
  gets stuck against an obstacle.
- `CAR_REMOTE_CONTROL` and `CAR_POINT_FOLLOW` are operator-driven modes, in
  which the PC side either steers the car directly or hands it a path to
  follow.

@fig:state-machine shows the core autonomous driving loop. From `CAR_STOP` a
start command moves the car into `CAR_START`, which launches straight into
`CAR_FULL_THROTTLE`. While driving on an open stretch, the car watches its
side sensors for an opening. A detected opening to the left or right sends it
into the matching turn state. When the turn is complete the car settles into
`CAR_STRAIGHT`, and once the track ahead has stayed open long enough it
escalates back to `CAR_FULL_THROTTLE`. This loop between straight driving and
turning is what carries the car around the track.

#figure(
  image("/assets/graphics/selfdrawn/state_machine.svg", width: 100%),
  caption: [Core autonomous driving states and their transitions],
) <fig:state-machine>

Three states sit outside this main loop. `CAR_RECOVER` is entered from any
driving state when the event mechanism reports a crash or a stuck car, and it
returns to `CAR_STRAIGHT` after the reverse maneuver finishes. A latching
low-battery cutoff forces the car back to `CAR_STOP` from anywhere and keeps
it there. The event mechanism behind both is described in @sec:flag-events.
`CAR_REMOTE_CONTROL` and `CAR_POINT_FOLLOW` are entered on an operator command
from the PC side and released back to `CAR_STOP`, independent of the
autonomous loop.

=== Flag-Based Event Mechanism <sec:flag-events>

Some conditions have to override the normal state flow no matter which state
the car is in. These are handled by a small event module that runs alongside
the state machine and reports its findings as flags. Three events are
detected. A low battery, a crash, and a stuck car. The most severe active
event is mirrored into a telemetry global so the PC side testsuite can display
it.

The state machine checks these flags at the top of every tick, before running
any state action. A low battery has the highest priority. Once the measured
pack voltage stays below its threshold for half a second, the module latches a
cutoff that forces the car to `CAR_STOP` and holds it there until the next
start command clears the latch. A crash is detected from a spike in horizontal
acceleration read from the IMU, and a stuck car from a distance sensor that
stays blocked too close for half a second. Either one, while the car is
driving, sends it into `CAR_RECOVER`. Leaving the recovery state clears the event.

Each detector debounces its trigger over several ticks, so a single noisy
sample cannot flip a state. Using flags rather than direct transitions keeps
the detection separate from the driving logic. The state machine only reads
the flags and reacts, which makes both parts easier to reason about and test.

== Turn Detection Algorithm <sec:turn-detection>

=== Rate-of-Change Threshold on Side ToF Sensors <sec:turn-rate-threshold>
// distance-normalized

=== Alignment and Wall-Ahead Preconditions <sec:turn-preconditions>

== Turn Completion Logic <sec:turn-completion>

=== Heading-Delta Tracking per Tick <sec:heading-delta>

=== Completion Criteria <sec:completion-criteria>
// 90 deg +/- 10 deg, front distance > 1.2 m

=== Failsafe Exit Condition <sec:failsafe-exit>
// 180 deg timeout

// Remaining open item from the old "Future Work" chapter:
// remote-control state (CAR_REMOTE_CONTROL) already implemented -- describe
// its transition conditions here rather than as an outlook item
