= Hardware Platform <ch:hardware>

== Chassis: XRAY M18 Pro LiPo 4WD <sec:chassis>
// starting point / rationale for choice

#figure(
  image("/assets/pictures/XRAY_M18_Pro_LiPo.jpg", width: 70%),
  caption: [XRAY M18 Pro LiPo 4WD chassis],
) <fig:chassis>
#align(center, text(size: 9pt, style: "italic")[Image source: @MKRacingXRAYM18Pro2026])

== Main PCB (Pre-Existing Design) <sec:main-pcb>
// functional overview
// cite @LaesserXRayLegacy2023 for the PCB schematics/layout (XRay Legacy V1)
// designed by A. Lasser specifically for this STM32 generation, but never
// built up or tested before this thesis; frame the bring-up as this
// thesis's own work, not something inherited/carried over from a prior gen

== Microcontroller: STM32H533RE (Nucleo-H533RE) <sec:mcu>
// core features relevant to the project
// cite @Braunl2008 for the sensor/MCU/actuator architecture rationale
// cite @STM32CubeMX2026 where you mention peripheral init / code generation
// cite @UM3121_2025 for board/pin/clock details specific to the Nucleo-H533RE

== Sensor Suite <sec:sensors>

=== Time-of-Flight Distance Sensors (VL53L1X) <sec:tof>
// I2C addressing scheme
// cite @VL53L1X2024 for sensor specs, I2C protocol, and ranging performance

=== IMU (BNO055) <sec:imu>
// 9-axis orientation sensing
// cite @BNO0552021 for sensor fusion modes, register map, and calibration procedure

=== ADC (ADS7128) <sec:adc>
// analog channel acquisition
// cite @ADS71282020 for channel config, I2C protocol, and register details

=== Hall-Effect Speed Sensor (TLE4946-2L) <sec:hall>
// limitations (no direction detection)
// cite @TLE49462L2020 for switching thresholds and output characteristics

== Actuation: Motor Drivers (BTN9970LV) <sec:motor-drivers>
// half-bridge driving, current sensing
// cite @BTN9970LV2021 for half-bridge specs, protection functions, and current sense

== Wireless Bridge: ESP8266 (D1 mini) <sec:esp-bridge>

== PCB Design Evaluation <sec:pcb-evaluation>

=== Findings <sec:pcb-findings>
- Battery charging circuit unsuitable for LiIon/LiPo
- SDA/SCL swap needed for BNO055
- Missing ESP8266-12F on-board
- STM32 pin layout issue
- Missing pulldown on ESC INH pin

=== Recommendations for the Next PCB Revision <sec:pcb-recommendations>
