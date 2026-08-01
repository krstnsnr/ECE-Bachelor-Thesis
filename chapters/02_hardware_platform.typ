= Hardware Platform <ch:hardware>

== Chassis: XRAY M18 Pro LiPo 4WD <sec:chassis>

The chassis this thesis's hardware baseline builds on is the XRAY M18 Pro
LiPo, a 1/18-scale, four-wheel-drive shaft-drive touring car kit from XRAY
@MichaelsRCXRAYM18Pro2026. It measures 220mm long on a 150mm wheelbase and
weighs about 165g standalone. The main chassis plate is CNC-machined
from 1.6mm carbon fiber, thin enough to flex a little on a low-grip
surface but stiff enough to hold its line at speed. XRAY's Multi-Flex
Technology top deck lets that flex be tuned separately at the front and
rear axle, a feature carried over from XRAY's 1/10-scale touring cars.

Two things about the M18 Pro matter for how CrazyCar uses it. First, its
drivetrain and suspension are fully adjustable, with composite ball
differentials at both axles, a 1:2.5 drive ratio with swappable 36T and
42T spur gears and assorted pinions, and coil-over shocks with adjustable
camber, caster, and toe. That range covers everything from a fast,
predictable setup on a smooth indoor track to a looser one that tolerates
a rougher surface. Second, the kit ships bare. Radio, servo, ESC, motor,
and battery are not included. The electronics have to be built up from
scratch, which is exactly the gap this thesis's firmware and this
platform's PCB (@sec:main-pcb) fill. Being a widely sold competition kit
also means worn or crashed parts are easy to source and replace, which
matters when a fleet of these cars is driven by students.

#figure(
  image("/assets/pictures/XRAY_M18_Pro_LiPo.jpg", width: 45%),
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
