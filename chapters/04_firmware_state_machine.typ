= Firmware Design: State Machine and Turn Detection <ch:firmware-state-machine>

== State Machine Design <sec:state-machine>

=== Overview of States and Transitions <sec:states-transitions>

The driving logic is implemented as a finite state machine. It runs once per
control-loop tick at 100 Hz. Each tick first executes the action of the current
state and then evaluates the transition conditions for the next tick. The
current state is mirrored into a telemetry global, so that the PC side
testsuite can observe the behavior of the car in real time. Nine states are
defined.

- `CAR_STOP` centers the steering and holds the motor at neutral. It is the
  power-on state and the fallback for every condition that ends driving.
- `CAR_START` resets the controllers in a short launch phase before the car
  moves.
- `CAR_FULL_THROTTLE` and `CAR_STRAIGHT` follow the walls, the former at full
  speed on an open stretch and the latter at a moderate speed after a turn.
- `CAR_TURN_LEFT` and `CAR_TURN_RIGHT` steer through a corner once an opening
  is detected on the corresponding side.
- `CAR_RECOVER` reverses briefly to free the car after a crash or a stuck
  condition.
- `CAR_REMOTE_CONTROL` and `CAR_POINT_FOLLOW` accept operator commands, where
  the PC side either steers the car directly or supplies a path for it to
  follow.

@fig:state-machine shows the core autonomous loop. A start command moves the
car from `CAR_STOP` through `CAR_START` into `CAR_FULL_THROTTLE`. A detected
opening branches into the matching turn state, which returns to `CAR_STRAIGHT`
once the turn is complete. A sufficiently long open stretch raises
`CAR_STRAIGHT` back to `CAR_FULL_THROTTLE`.

#figure(
  image("/assets/graphics/selfdrawn/state_machine.svg", width: 70%),
  caption: [Core autonomous driving states and their transitions],
) <fig:state-machine>

The remaining states lie outside this loop. `CAR_RECOVER` is entered from any
driving state on a crash or stuck event and returns to `CAR_STRAIGHT` once the
reverse maneuver finishes. A latching low-battery cutoff forces the car back to
`CAR_STOP` from any state. @sec:flag-events describes the event mechanism
behind both. `CAR_REMOTE_CONTROL` and `CAR_POINT_FOLLOW` are entered on an
operator command and released back to `CAR_STOP`.

=== Flag-Based Event Mechanism <sec:flag-events>

Some conditions have to override the normal state flow regardless of the
current state. An event module running alongside the state machine handles
them and reports its results as flags. The module covers three events, namely
a low battery, a crash, and a stuck car. The most severe active event is
mirrored into a telemetry global, so that the PC side testsuite can display
it.

The state machine checks these flags at the start of every tick, before it
runs any state action. A low battery has the highest priority. Once the
measured pack voltage stays below its threshold for half a second, the module
latches a cutoff. The cutoff forces the car to `CAR_STOP` and holds it there
until the next start command clears the latch. A crash is detected from a
spike in horizontal acceleration read from the IMU. A stuck car is detected
from a distance sensor that stays blocked too close for half a second. Either
event moves the car into `CAR_RECOVER` while it is driving. Leaving the
recovery state clears the event.

Each detector debounces its trigger over several ticks, so that a single noisy
sample cannot cause a transition. The use of flags rather than direct
transitions separates the detection from the driving logic. The state machine
reads the flags and reacts to them, which allows both parts to be developed
and tested independently.

=== Remote Control and Point Follow <sec:operator-modes>

Beyond the autonomous loop, the state machine provides two modes that the
operator controls from the PC side over the OTA link. A single command field
selects between off, remote control, and point follow, and the sync step checks
that field for a change on every pass of the main loop. A change to remote
control enters `CAR_REMOTE_CONTROL` from any state. In this mode the PC sends
the steering and speed setpoints directly. The firmware applies the steering
setpoint unchanged, while the speed PID holds the commanded speed.

The second mode, `CAR_POINT_FOLLOW`, is entered in the same way, but the PC
supplies a path that the car drives autonomously instead of steering it live.
The path is a list of points, each with a position and a direction flag that
marks it as forward or reverse. When the mode starts, the firmware validates
the path before it accepts it. The path must contain at least two points, every
direction flag must be valid, and consecutive points must lie within a maximum
spacing. The firmware also splits the path into segments wherever the direction
changes, so that a forward stretch and a following reverse stretch become
separate segments. If any check fails, the request is refused and the car
remains stationary.

With a valid path latched, the follower runs once per tick. It estimates its
own pose by dead reckoning, since no external position reference is available
while driving. The IMU heading and the wheel speed are combined into an updated
position on every tick, and that pose is published as telemetry.

Steering uses pure pursuit. The follower selects the path point at a fixed
lookahead distance along the current segment and computes the steering angle
that guides the car onto that point. A reverse segment is handled with an
inverted heading and steering sign, so the same geometry drives the car
backwards. The speed is a fixed forward or reverse value that is reduced as the
car approaches the end of a segment. At the end of a segment the follower
pauses briefly before it continues with the next one, which allows the car to
settle before it reverses direction. The follower aborts the mode if the path
is lost, meaning that the next point lies too far away, or if it commands
motion while the wheels do not turn for an extended period.

Either mode is left when the command field returns to off, which stops the
motor and returns the car to `CAR_STOP`. Entering a mode also clears the
low-battery latch, because it is treated as a new start. An active mode
overrides the autonomous loop, so that the turn detector and the open-road
escalation do not run.

== Turn Detection Algorithm <sec:turn-detection>

=== Rate-of-Change Threshold on Side ToF Sensors <sec:turn-rate-threshold>

The car recognizes a corner from its two side ToF sensors. Along a straight
the side distances stay approximately constant. At an opening the distance on
that side increases as the wall recedes.

The detector relates that increase to the distance the car has traveled
rather than to elapsed time. A slow car and a fast car pass the same opening,
and both have to detect the same corner. @fig:turn-rate-of-change shows the
two quantities on a 90° left corner. The side distance is short while the
wall runs alongside the car. One sample later the beam reaches past the end
of the wall, and the side distance is much longer. The distance the car has
traveled between the two positions is marked below them.

#figure(
  image("/assets/graphics/selfdrawn/turn_rate_of_change.svg", width: 70%),
  caption: [Side distance and traveled distance at a 90° left corner, with the
  side beam reaching past the end of the wall at the second position],
) <fig:turn-rate-of-change>

Each side holds a ring buffer of its last four samples. The slope is the
change across that buffer divided by the distance traveled over the same span.
That distance follows from the wheel speed and the tick period. The result is
a distance-normalized rate of change, expressed in millimeters of side
distance per millimeter of forward travel, and is therefore independent of
the speed.

An opening is flagged when that slope exceeds a fixed threshold for two
consecutive ticks. The two-tick confirmation rejects a single noisy sample. A
distance reading below 20 mm is treated as invalid and held at the last valid
value, so that a sensor dropout is not interpreted as an opening.

=== Alignment and Wall-Ahead Preconditions <sec:turn-preconditions>

The slope test would also trigger when the car drifts or turns quickly on a
straight, since its own rotation moves the side readings. Four preconditions
gate the test, so that it runs only while the car tracks a straight and
approaches a corner. @fig:turn-preconditions shows three of them, namely the
heading against the corridor axis, the front distance, and the yaw rate.

The firmware maintains a slowly tracked estimate of the corridor heading, the
direction of the lane the car is following. A low-pass filter follows the
heading while the car runs straight and reseeds it after a prolonged rotation.
The slope test is allowed only while the current heading stays within 20° of
that corridor heading. This prevents a car that is already cornering or
drifting from interpreting its own rotation as an opening.

#figure(
  image("/assets/graphics/selfdrawn/turn_preconditions.svg", width: 65%),
  caption: [Turn detector preconditions],
) <fig:turn-preconditions>

A second gate requires a wall ahead. The front distance must be below 2 m, so
that the test responds only where the track also closes off in front of the
car. A third gate requires a minimum forward speed, below which the
distance-normalized slope is meaningless. A fourth gate requires the yaw rate
to stay under a fixed limit, which excludes a fast spin. The side slope is
compared against its threshold only when all four conditions hold.

== Turn Completion Logic <sec:turn-completion>

=== Heading-Delta Tracking per Tick <sec:heading-delta>

A turn ends once the car has rotated by a sufficient angle, so the firmware
tracks the rotation covered since the corner began. On entering a turn state,
the firmware records the current heading as a baseline and clears a signed
accumulator.

On every tick the firmware adds the rotation since the previous tick to that
accumulator. The step is the shortest signed difference between the current
and the previous heading, wrapped into the range from -180° to 180°. The
wrapping keeps each step correct where the heading passes its wrap-around
point. A step larger than 30° is discarded as an implausible IMU sample.

The firmware sums these per-tick steps rather than comparing the current
heading against the baseline directly. The total therefore extends beyond a
half turn, where a direct comparison would be corrupted by the heading wrap.
@sec:completion-criteria describes how that running total is evaluated.

=== Completion Criteria <sec:completion-criteria>

The accumulated heading delta from @sec:heading-delta is checked against an
exit grid, a set of target angles at which a corner is expected to end. The
grid has two entries, 90° for a normal corner and 180° for a hairpin, each
with a tolerance of 10°. A normal corner usually ends slightly short of a
full 90°, so the wall follower takes over and completes the straightening of
the car.

A turn completes when two conditions hold at the same time. The heading delta
lies within tolerance of a grid target, and the front distance has opened
beyond 1.2 m, so that the car faces clear track rather than the corner. Both
conditions must hold for two consecutive ticks, which rejects a brief
fluctuation, before the car leaves the turn state and returns to straight
driving.

@fig:turn-completion shows both conditions at the end of a normal corner. The
heading delta has reached its 90° target, and the front distance measures
clear track along the new corridor.

#figure(
  image("/assets/graphics/selfdrawn/turn_completion.svg", width: 60%),
  caption: [Turn completion for a 90° corner, with the heading delta near its
  exit target and the track ahead now clear],
) <fig:turn-completion>

=== Failsafe Exit Condition <sec:failsafe-exit>

The CrazyCar competition track is built only from 90° corners and 180°
hairpins, and the exit grid holds one target for each. A 90° corner completes
near its target once the front distance opens. A turn that continues past the
90° target can therefore only be a hairpin. The car leaves the turn state
once it has turned a full 180°, regardless of the front distance. This bounds
every turn at half a rotation and guarantees that the turn state always ends.
