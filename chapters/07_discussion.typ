#import "/helpers/gls.typ": gls, glspl

= Discussion <ch:discussion>

== Interpretation of Results <sec:interpretation>

The results in @ch:evaluation address the three-part definition of
modernizing the platform from @sec:motivation. The autonomous loop drove the
car around the track and through both corner types targeted by the exit grid
in @sec:completion-criteria. The first part, driving autonomously, was
therefore reached. The GET/SET protocol from @sec:pid-tuning allowed the
telemetry and parameter fields to be read and written at runtime, which meets
the second part. @sec:usability reports that runtime tuning reduced the
iteration loop from a wired reflash cycle to a live gain change, which meets
the third.

@sec:sensor-performance shows that the sensor suite was sufficient to support
that loop. The usable range of the front ToF sensor plateaued at 2.9 m. That
plateau follows from the mounting height of the sensor rather than from its
timing budget or #gls("roi") settings, so the sensor itself performed as its
datasheet describes. The limit is a property of the mounting position on the
car rather than of how the firmware drives the sensor. The side ToF sensors,
the IMU, and the ADC operated reliably throughout. The turn detector and
state machine could therefore rely on that data without filtering beyond the
measures already described in @sec:turn-rate-threshold and
@sec:turn-preconditions.

Reliable detection of both the 90° corners and the 180° hairpins in
@sec:turn-performance validates the distance-normalized slope approach from
@sec:turn-rate-threshold. Keying the detector on distance traveled rather
than on elapsed time meant that one threshold worked at both speeds the
detector runs under. @sec:states-transitions describes these as the full
speed of `CAR_FULL_THROTTLE` and the moderate speed of `CAR_STRAIGHT`. A
separate threshold for either was therefore unnecessary.

`CAR_RECOVER` is the one autonomous-loop state that fell short of that
reliability, since it needed several attempts in some cases. The tuning
workflow repositions a car through `CAR_POINT_FOLLOW` after a failed lap
rather than relying on recovery, so this shortfall did not limit the
evaluation.

The usability comparison in @sec:usability is the clearest evidence that the
second and third parts of the definition in @sec:motivation were reached
together rather than separately. A telemetry table that was only readable
would have allowed the testsuite to observe the car without allowing an
operator to act on those observations. A tuning path with its own protocol
per parameter would not have scaled beyond the two PID controllers tuned in
this project. The same named-field GET/SET mechanism from
@sec:telemetry-display and @sec:pid-tuning serves both purposes, which is
what allowed a gain change to take effect on the next control step.

== Limitations of the Current Implementation <sec:limitations>

The evaluation itself carries a limitation. @sec:eval-methodology judged
sensor readings, turn detection, and recovery behavior by inspecting logged
telemetry and observing repeated runs, rather than through a statistically
designed measurement campaign. The findings in @ch:evaluation therefore
describe what was observed across those runs, not a quantified error rate or
a confidence interval. Lap timing is the exception, and it measures the
repeatability of a completed lap rather than the detection rate of an
individual corner.

Two behaviors observed during the evaluation remain current limitations
rather than solved problems. @sec:turn-performance and
@sec:operator-mode-performance report them. `CAR_RECOVER` sometimes needs two or three
attempts to free a stuck car. The repositioning through `CAR_POINT_FOLLOW`
covered this case during the evaluation, but the state itself would benefit
from further tuning. The dead-reckoned pose of `CAR_POINT_FOLLOW` also drifts
slightly on the straight following a corner. The Hall sensor from @sec:hall is
mounted on a single rear wheel, so the follower cannot account for the inner
and outer wheels turning at different rates through that corner. Reading both
rear wheels would remove this limitation, but the current wiring of the
platform reaches only one.

The PCB oversights from @sec:pcb-impact-summary are hardware limitations that
the firmware works around rather than eliminates. Charging still takes place
off the car with an external charger, since the onboard circuit was built for
the original NiMH pack of the platform and does not match the Li-Ion pack now
in use. The SDA and SCL lines of the BNO055 still need the solder bridge
described in @sec:pcb-sda-scl on every board built from this PCB revision,
until a future revision corrects the swap in layout. The ESP8266 module is
wired into the headers of the Nucleo board rather than fitted to the main
PCB, the workaround @sec:pcb-esp8266 describes, because the current board was
laid out before wireless communication was foreseen.

The 2.9 m range ceiling of the front ToF sensor from @sec:sensor-performance
follows from the mounting position of the sensor on the car rather than from
a firmware setting. A longer timing budget and a wider #gls("roi") both left
it unchanged.

The evaluation also ran entirely on the one original CrazyCar circuit that
the AI-MotionLab testsuite currently has mapped. @sec:ai-motionlab-role
describes that circuit as a hand-authored track geometry. The results in
@ch:evaluation therefore state how the platform performs on that layout, not
across other corner geometries or track surfaces.

== Recommendations for the Next PCB Revision <sec:pcb-recommendations>

The oversights reported in @sec:pcb-impact-summary translate into the
following changes for the next revision of the main PCB.

The charging circuit from @sec:pcb-battery-charging should be redesigned
around the two-cell 18650 Li-Ion pack that the platform now runs on. Its
charge voltage and current profile must match Li-Ion cells rather than the
original six-cell NiMH pack.

The SDA/SCL swap from @sec:pcb-sda-scl is a straightforward layout fix. The
next revision only needs to route those two traces to their correct pins on
the BNO055, so that the sensor starts up correctly without a solder bridge.

The ESP8266 module from @sec:pcb-esp8266 should receive a dedicated on-board
footprint. A jumper should still be able to disconnect the STM32-ESP8266 bus
entirely, because the CrazyCar race rules forbid wireless communication
during a race. The link serves testing and tuning rather than competition
runs.

The floating INH input from @sec:pcb-esc-pulldown needs a pulldown resistor
on D6, so that the input starts low and holds the motor disabled until the
firmware enables it.

The pin layout from @sec:pcb-pin-layout requires a broader revision. The
Nucleo board should be mounted right side up, which would let it fit better
under the cover of the car. The main PCB currently exposes only the Arduino
UNO R4 header set. The ST Morpho headers of the Nucleo board carry the
remaining pins of the STM32 and should be connected as well.

Two further details belong in the same revision. The Hall sensor connector
carries four pins, but only three of them reach the STM32. The wheel-speed sensor
from @sec:hall is a four-pin part that also reports direction, so the
connector should break out all four. The ESP8266 link should stay off the
pins outside the Arduino header footprint, since routing it there forfeits
access to the extra pins of the Nucleo board.

== Lessons Learned <sec:lessons-learned>

The main PCB was brought up firsthand for the first time in this project, as
@sec:main-pcb describes. That bring-up showed that some problems appear only
once real firmware drives real hardware end to end. The missing pulldown on
the ESC INH pin from @sec:pcb-esc-pulldown is the clearest example. It became
visible only when the wired debugger halted the STM32 at reset and left the
pin floating, a sequence that reading the schematic alone would not have
revealed. Hands-on bring-up therefore takes time that a schematic review
cannot replace.

Benedikt Polivka built the telemetry and parameter tables in
@sec:telemetry-display as generic named fields rather than as a separate
protocol message for each sensor or gain @PolivkaTestsuite2026. That decision
proved central to this work. Every sensor from @ch:hardware and every PID
gain from @sec:actuator-control became visible to the testsuite through the
same `GET`/`SET` command handler, without additional protocol code on either
side. The generic structure was in place before it was clear which fields
tuning would eventually need, so the firmware modules connected to the tuning
loop in @sec:workflow without changes to the protocol itself.

Runtime tuning also reduced how much the initial PID gains had to achieve.
The SIMC-derived starting gains from @sec:actuator-control only had to keep
the car on the track. The live GET/SET tuning in @sec:pid-tuning then closed
the remaining gap on the track, faster than deriving a more exact analytical
gain set in advance would have. Further effort spent on the tuning workflow
returned more than the same effort spent on gain derivation.

The distance-normalized slope of the turn detector in
@sec:turn-rate-threshold is a broader lesson about designing a detector
around what stays constant in the physical situation rather than around the
raw time series of a sensor. One threshold then covers every speed the car
reaches.

The same principle, treating a single sample as provisional until it is
confirmed, reappears elsewhere in the firmware. The two-tick confirmation of
the slope test, the half-second debounce on the crash and stuck events in
@sec:flag-events, and the discarded implausible IMU sample in
@sec:heading-delta all reject a single noisy reading in the same way.

This firmware and the AI-MotionLab testsuite were developed in parallel, as
@sec:ai-motionlab-role describes. The GET/SET protocol and the telemetry
field names therefore had to serve as a stable interface between two projects
that were both still changing @PolivkaTestsuite2026. The protocol was settled
early, and the field table and the command set were kept to a compact
name-based design. Each side could therefore change its own code
independently.
