= Evaluation <ch:evaluation>

== Evaluation Methodology <sec:eval-methodology>
// what was tested, and how

== Sensor Performance <sec:sensor-performance>
// range/accuracy of ToF, IMU stability, ADC readings

== State Machine / Turn Detection Performance <sec:turn-performance>
// success rate over test runs

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
