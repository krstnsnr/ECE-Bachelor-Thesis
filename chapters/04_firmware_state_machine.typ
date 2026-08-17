= Firmware Design: State Machine and Turn Detection (STM32) <ch:firmware-state-machine>

== State Machine Design <sec:state-machine>

=== Overview of States and Transitions <sec:states-transitions>

The driving logic is organized as a finite state machine, run once per
control-loop tick at 100Hz. Each tick first executes the action of the current
state and then evaluates the transition conditions for the next tick. The
current state is mirrored into a telemetry global, so the PC side testsuite can
follow the car's behavior live. Nine states are defined.

- `CAR_STOP` centers the steering and holds the motor at neutral. It is the
  power-on state and the fallback whenever driving must end.
- `CAR_START` is a short launch state that resets the controllers before the
  car moves.
- `CAR_FULL_THROTTLE` and `CAR_STRAIGHT` both follow the walls, the former at
  full pace on an open stretch and the latter at a moderate pace after a turn.
- `CAR_TURN_LEFT` and `CAR_TURN_RIGHT` steer through a corner once an opening
  is detected on that side.
- `CAR_RECOVER` reverses briefly to free the car after a crash or when it gets
  stuck.
- `CAR_REMOTE_CONTROL` and `CAR_POINT_FOLLOW` are operator-driven modes, in
  which the PC side either steers directly or hands the car a path to follow.

@fig:state-machine shows the core autonomous loop. A start command moves the
car from `CAR_STOP` through `CAR_START` into `CAR_FULL_THROTTLE`. A detected
opening branches into the matching turn state, which settles back into
`CAR_STRAIGHT` once complete, and a long enough open stretch escalates
`CAR_STRAIGHT` back to `CAR_FULL_THROTTLE`.

#figure(
  image("/assets/graphics/selfdrawn/state_machine.svg", width: 100%),
  caption: [Core autonomous driving states and their transitions],
) <fig:state-machine>

The remaining states sit outside this loop. `CAR_RECOVER` is entered from any
driving state on a crash or stuck event and returns to `CAR_STRAIGHT` when the
reverse maneuver finishes, while a latching low-battery cutoff forces the car
back to `CAR_STOP` from anywhere (see @sec:flag-events). `CAR_REMOTE_CONTROL`
and `CAR_POINT_FOLLOW` are entered on an operator command and released back to
`CAR_STOP`.

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
