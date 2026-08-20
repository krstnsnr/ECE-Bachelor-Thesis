#import "/helpers/gls.typ": gls, glspl

= Discussion <ch:discussion>

== Interpretation of Results <sec:interpretation>

The results in @ch:evaluation speak to the three-part definition of
modernizing the platform from @sec:motivation. The autonomous loop drove the
car around the track and through both corner types the exit grid in
@sec:completion-criteria targets, so the first part, driving autonomously,
was reached. The GET/SET protocol from @sec:pid-tuning let telemetry and
parameters be read and written at runtime, meeting the second part. And
@sec:usability shows that runtime tuning cut the iteration loop from a wired
reflash cycle down to a live gain change, meeting the third.

@sec:sensor-performance shows the sensor suite held up well enough to
support that loop. The front ToF sensor's usable range plateaued at 2.9m,
but tracing that plateau to the sensor's mounting height rather than its
timing budget or #gls("roi") settings means the sensor itself performed as
its datasheet describes. The limit is a property of where the sensor sits
on the car, not of how the firmware drives it. The side ToF sensors, the
IMU, and the ADC all held up without exception, which is why the turn
detector and state machine in @sec:turn-performance could rely on that data
without extra filtering beyond what @sec:turn-rate-threshold and
@sec:turn-preconditions already do.

Reliable detection of both the 90 degree corners and the 180 degree
hairpins in @sec:turn-performance validates the distance-normalized slope
approach from @sec:turn-rate-threshold. Keying the detector on distance
traveled rather than elapsed time meant the same threshold worked whether
the car was moving at the full pace of `CAR_FULL_THROTTLE` or the moderate
pace of `CAR_STRAIGHT`, the two states @sec:states-transitions describes it
running under, without needing a separate threshold for either.
`CAR_RECOVER` needing several attempts in some cases is the one
autonomous-loop state that fell short of that reliability, though the
tuning workflow's own reliance on `CAR_POINT_FOLLOW` to reposition a car
after a failed lap, rather than on recovery finishing the job, kept that
shortfall from limiting the evaluation itself.

The usability comparison in @sec:usability is the clearest evidence that
the second and third parts of the definition in @sec:motivation were
reached together, not separately. A telemetry and parameter table that was
only readable would have let the testsuite observe the car without letting
an operator act on what they saw, and a tuning path that needed its own
protocol per parameter would not have scaled past the two PID controllers
this project actually tuned. Building both around the same named-field
GET/SET mechanism from @sec:telemetry-display and @sec:pid-tuning is what
let a gain change take effect on the next control step, the improvement
@sec:usability reports.

== Limitations of the Current Implementation <sec:limitations>

The evaluation itself has a limitation worth stating plainly.
@sec:eval-methodology judged sensor readings, turn detection, and recovery
behavior by inspecting logged telemetry and watching repeated runs, not by
a statistically designed measurement campaign. The findings in
@ch:evaluation describe what was observed across those runs rather than a
quantified error rate or a confidence interval, so they speak to whether
the platform works reliably in practice, not to how reliably by some fixed
number.

Two behaviors identified in @sec:turn-performance remain current
limitations rather than solved problems. `CAR_RECOVER` sometimes needs two
or three attempts to free a stuck car, and while `CAR_POINT_FOLLOW`'s own
repositioning kept this from blocking the evaluation, the state itself
would benefit from further tuning. `CAR_POINT_FOLLOW`'s dead-reckoned pose
also drifts slightly on the straight following a corner, traced in
@sec:turn-performance to the Hall sensor from @sec:hall sitting on a single
rear wheel, so the follower cannot see the inner and outer wheels turning
at different rates through that corner. Reading both rear wheels would
remove that blind spot, but the platform's current wiring only reaches one.

The PCB oversights @sec:pcb-impact-summary reports are hardware limitations
the firmware works around rather than ones it eliminates. Charging still
has to happen off the car with an external charger, since the onboard
circuit was built for the platform's original NiMH pack and cannot charge
the Li-Ion pack it now runs. The BNO055's SDA and SCL lines still need the
bodge wire described in @sec:pcb-sda-scl on every board built from this PCB
revision, until a future revision fixes the swap in layout. And the ESP8266
module sits wired into the Nucleo board's headers rather than fitted to the
main PCB, exactly the workaround @sec:pcb-esp8266 describes, since the
current board was laid out before wireless communication was part of the
plan.

The front ToF sensor's 2.9m range ceiling from @sec:sensor-performance is a
limitation of where the sensor sits on the car, not one firmware settings
can tune away. As @sec:sensor-performance reports, neither a longer timing
budget nor a wider #gls("roi") changed it. And the evaluation ran entirely
on the one original CrazyCar circuit the AI-MotionLab testsuite currently has mapped,
described in @sec:ai-motionlab-role as a hand-authored track geometry, so
the results in @ch:evaluation say how the platform performs on that layout
rather than across corner geometries or track surfaces the platform has not
yet been driven on.

== Lessons Learned <sec:lessons-learned>

Bringing up the main PCB firsthand, described in @sec:crazycar-history and
@sec:main-pcb as the first time this board generation had been tested,
showed that some problems only surface once real firmware drives real
hardware end to end. The missing pulldown on the ESC INH pin from
@sec:pcb-esc-pulldown is the clearest example. It only showed itself when
the wired debugger halted the STM32 at reset and left the pin floating, a
sequence no amount of reading the schematic on its own would have caught.
The lesson carries beyond this one board. A new PCB revision needs time
budgeted for exactly this kind of hands-on bring-up, not just for the
firmware that will eventually run on it.

Building the telemetry and parameter tables in @sec:telemetry-display as
generic named fields, rather than a bespoke protocol message for each
sensor or gain, turned out to matter more than it seemed to at the time the
architecture was chosen. Every sensor added in @ch:hardware and every PID
gain introduced in @sec:actuator-control became visible to the testsuite
for free, through the same `GET`/`SET` command handler from
@sec:pid-tuning, with no new protocol code needed on either side. Choosing
that generic structure early, before it was clear exactly which fields
tuning would eventually need, is what made the fast tuning loop in
@sec:workflow possible later.

Runtime tuning also changed how much weight the initial PID gains needed to
carry. The SIMC-derived starting gains from @sec:actuator-control only had
to be good enough to keep the car on the track, because @sec:pid-tuning's
live GET/SET tuning could close the remaining gap afterward, on the track,
faster than deriving a more exact analytical gain set up front would have.
Investing further in the tuning workflow paid off more directly than
investing further in gain derivation would have.

The turn detector's distance-normalized slope from @sec:turn-rate-threshold
is a broader lesson about designing a detector around what stays constant
in the physical situation, rather than around a raw sensor's time series.
Keying the threshold on distance traveled instead of elapsed time meant one
threshold worked at every speed the car reached, rather than needing a
separate one tuned per speed. The same theme, treating a single sample as
provisional until confirmed rather than trusted immediately, reappears
elsewhere in the firmware. The two-tick confirmation in
@sec:turn-rate-threshold, the half-second debounce on the crash and stuck
events in @sec:flag-events, and the discarded IMU glitch step in
@sec:heading-delta all reject a single noisy reading the same way, before
it can act on its own.

Developing this firmware while a colleague built the AI-MotionLab testsuite
in parallel, as @sec:ai-motionlab-role describes, meant the GET/SET
protocol and the telemetry field names had to work as a stable interface
between two projects moving at once, not as an afterthought added once one
side was finished. Settling that protocol early, and keeping both the
field table and the command set to a small, name-based design, let each
side keep changing its own code without breaking the other's.
