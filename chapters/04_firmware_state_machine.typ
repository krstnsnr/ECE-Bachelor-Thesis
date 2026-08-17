= Firmware Design: State Machine and Turn Detection <ch:firmware-state-machine>

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
back to `CAR_STOP` from anywhere. @sec:flag-events describes the event
mechanism behind both. `CAR_REMOTE_CONTROL`
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

=== Remote Control and Point Follow <sec:operator-modes>

Beyond the autonomous loop, the state machine has two modes the operator drives
from the PC side over the OTA link. A single command field selects between off,
remote control, and point follow, and the sync step watches that field for a
change on every main-loop spin. A change into remote control enters
`CAR_REMOTE_CONTROL` from whatever state the car was in. There the PC sends the
steering and speed setpoints directly, and the firmware applies the steering as
given while the speed PID still holds the commanded speed.

The second mode, `CAR_POINT_FOLLOW`, is entered the same way, but instead of
live steering the PC hands the car a path to drive on its own. The path is a
list of points, each with a position and a direction flag that marks it as
forward or reverse. When the mode starts, the firmware checks the path before
accepting it. It must have at least two points, every direction flag must be
valid, and consecutive points must be close enough together. It also splits the
path into segments wherever the direction flips, so a forward stretch and a
following reverse stretch become separate segments. If any check fails the
request is refused and the car stays put.

With a valid path latched, the follower runs once per tick. It has no outside
position fix while driving, so it dead-reckons its own pose, turning the IMU
heading and the wheel speed into an updated position each tick, and publishes
that pose as telemetry. To steer, it uses pure pursuit. It looks a fixed
distance ahead along the current segment, takes the path point at that
lookahead, and computes the steering angle that curves the car onto it. A
reverse segment is handled by aiming with a flipped heading and steering sign,
so the same geometry drives the car backwards. Speed is a fixed forward or
reverse pace that ramps down to a crawl as the car nears the end of a segment.
At a segment end the follower pauses briefly, then picks up the next segment,
which lets the car settle before it reverses direction. It gives the mode up if
the path is lost, meaning the next point drifts too far away, or if it commands
motion but the wheels do not turn for too long.

Either mode is left when the command field returns to off, which stops the
motor and drops the car back to `CAR_STOP`. Engaging a mode also clears the
low-battery latch, since it counts as a fresh start. While either mode is
active it overrides the autonomous loop, so the turn detector and the open-road
escalation do not run.

== Turn Detection Algorithm <sec:turn-detection>

=== Rate-of-Change Threshold on Side ToF Sensors <sec:turn-rate-threshold>

The car recognizes a corner from its two side ToF sensors. Along a straight
the side distances stay roughly constant, but at an opening the distance on
that side jumps up as the wall falls away. The detector keys on that jump.

What matters is not how fast the distance grows in time, but how fast it grows
relative to how far the car has driven. A slow car and a fast car pass the
same opening and should both see the same corner. Each side keeps a short ring
buffer of its last four samples. The slope is the change across that buffer
divided by the distance traveled over the same span, obtained from the wheel
speed and the tick period. The result is a distance-normalized rate of change,
in millimeters of side clearance gained per millimeter of forward travel, and
it does not depend on speed.

An opening is flagged when that slope exceeds a fixed threshold for two consecutive ticks. 
The two-tick confirmation rejects a single noisy
sample. A distance reading below 20mm is treated as invalid and held at the last good
value, so a sensor dropout does not look like a jump.

=== Alignment and Wall-Ahead Preconditions <sec:turn-preconditions>

The slope test would also fire when the car drifts or turns fast on straights, since its own
rotation moves the side readings. Four preconditions gate it, so it runs only
when the car is tracking a straight and closing on a corner. @fig:turn-preconditions
shows the two that give this section its name.

The firmware keeps a slowly tracked estimate of the corridor heading, the
direction of the lane the car is driving down. A low-pass filter follows the
heading while the car runs straight and reseeds it after a prolonged rotation.
The slope test is allowed only while the current heading stays within 20
degrees of that corridor heading. A car that is already cornering or drifting
then does not read its own rotation as an opening.

#figure(
  image("/assets/graphics/selfdrawn/turn_preconditions.svg", width: 65%),
  caption: [Alignment and wall-ahead preconditions for the turn detector],
) <fig:turn-preconditions>

A second gate requires a wall ahead. The front distance must be under 2
metres, so only a real corner counts, where the track also closes off ahead. Two further gates
require a minimum forward speed, below which the distance-normalized slope is
meaningless, and a yaw rate under a fixed limit, so a fast spin never passes.
Only when all four hold is the side slope compared against its threshold.

== Turn Completion Logic <sec:turn-completion>

=== Heading-Delta Tracking per Tick <sec:heading-delta>

A turn ends when the car has rotated far enough, so the firmware needs to know
how much it has turned since the corner began. On entering a turn state it
records the current heading as a baseline and clears a signed accumulator.

Every tick the car adds how far it has rotated since the previous tick to that
accumulator. The step is the shortest signed difference between the current
and previous heading, wrapped into the range from -180 to 180 degrees, which
keeps each step correct across the point where the heading rolls over. A step
larger than 30 degrees is discarded as an IMU glitch rather than added.
Summing these small per-tick steps, instead of comparing against the start
heading directly, lets the total pass beyond a half turn without the heading
wrap corrupting it. The running total feeds the completion criteria in
@sec:completion-criteria.

=== Completion Criteria <sec:completion-criteria>

The accumulated turn angle is checked against an exit grid, a small set of
target angles a corner is expected to land on. The grid has two entries,
90 degrees for a normal corner and 180 degrees for a hairpin, each with a
tolerance of 10 degrees. A normal corner usually exits a little short of a square 90
degrees, which lets the wall follower take over and finish straightening the
car.

A turn completes when two things hold together. The accumulated angle sits
within tolerance of a grid target, and the front distance has opened past 1.2
metres, so the car now looks down clear track rather than still facing the
corner. For a normal corner this means the car has swung around by roughly 90
degrees and the way ahead is open, as sketched in the completion figure. To
reject a brief flicker, both conditions must hold for two consecutive ticks
before the car leaves the turn state and returns to straight driving.

#figure(
  image("/assets/graphics/selfdrawn/turn_completion.svg", width: 60%),
  caption: [Turn completion for a 90° corner, with the accumulated angle near its exit target and the track ahead now clear],
) <fig:turn-completion>

=== Failsafe Exit Condition <sec:failsafe-exit>

The CrazyCar competition track is built only from 90-degree corners
and 180-degree hairpins, and the exit grid mirrors this with one target near
each. A 90-degree corner
completes near its target once the front opens. A turn that does not complete
as a 90-degree corner can only be a hairpin, so the car exits once it has
turned a full 180 degrees, whether or not the front has opened by then. This
bounds every turn at half a rotation and guarantees the turn state always ends.
