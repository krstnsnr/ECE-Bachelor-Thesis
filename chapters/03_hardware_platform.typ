= Hardware Platform <ch:hardware>

== Chassis: XRAY M18 Pro LiPo 4WD <sec:chassis>
// starting point / rationale for choice

== Main PCB (Inherited Design) <sec:main-pcb>
// functional overview

== Microcontroller: STM32H533RE (Nucleo-H533RE) <sec:mcu>
// core features relevant to the project

== Sensor Suite <sec:sensors>

=== Time-of-Flight Distance Sensors (VL53L1X) <sec:tof>
// I2C addressing scheme

=== IMU (BNO055) <sec:imu>
// 9-axis orientation sensing

=== ADC (ADS7128) <sec:adc>
// analog channel acquisition

=== Hall-Effect Speed Sensor (TLE4946-2L) <sec:hall>
// limitations (no direction detection)

== Actuation: Motor Drivers (BTN9970LV) <sec:motor-drivers>
// half-bridge driving, current sensing

== Wireless Bridge: ESP8266 (D1 mini) <sec:esp-bridge>

== PCB Design Evaluation <sec:pcb-evaluation>

=== Method Used to Identify Oversights <sec:pcb-method>

=== Findings <sec:pcb-findings>
- Battery charging circuit unsuitable for LiIon/LiPo
- SDA/SCL swap needed for BNO055
- Missing ESP8266-12F on-board
- STM32 pin layout issue
- Missing pulldown on ESC INH pin

=== Recommendations for the Next PCB Revision <sec:pcb-recommendations>
