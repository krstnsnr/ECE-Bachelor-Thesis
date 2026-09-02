#import "/helpers/gls.typ": gls, glspl
#import "/helpers/lib.typ": imgsrc

= Hardware Platform <ch:hardware>

== Chassis: XRAY M18 Pro LiPo 4WD <sec:chassis>

The hardware of this thesis builds on is the XRAY M18 Pro
LiPo, a 1/18-scale, four-wheel-drive shaft-drive touring car kit from XRAY
@MichaelsRCXRAYM18Pro2026. It measures 220mm in length with a wheelbase of 150mm and
a weight of approximately 165g. The main chassis plate is #gls("cnc")-machined
from 1.6mm carbon fiber, thin enough to flex a little on a low-grip
surface but stiff enough to hold its line at higher speeds. XRAY's Multi-Flex
top deck enables that flex to be tuned separately at the front and
rear axle, a feature carried over from XRAY's 1/10-scale touring cars.

Two characteristics of the M18 Pro are relevant to its use in CrazyCar. First, the
drivetrain and suspension are fully adjustable. The setup additionally offers composite ball
differentials at both axles, a 1:2.5 drive ratio with changeable 36T and
42T spur gears and a range of pinions, and coil-over shocks with adjustable
camber, caster, and toe. That range covers setups from fast and predictable on smooth indoor surfaces to more compliant configurations for rougher tracks. Second, the kit is available standalone. That bare state leaves room to build a
fully custom electronics platform, exactly what this project set out to do.


#figure(
  image("/assets/pictures/XRAY_M18_Pro_LiPo.jpg", width: 40%),
  caption: [XRAY M18 Pro LiPo 4WD chassis #imgsrc(<MKRacingXRAYM18Pro2026>)],
) <fig:chassis>

== Main PCB (XRay Legacy V1) <sec:main-pcb>

The components described in this chapter are mounted on a custom PCB, designed in-house by A. Läßer for this STM32-based generation of CrazyCar @LaesserXRayLegacy2023. 
 The board carries the #gls("i2c") sensor stack, the motor and steering drivers, the ADC, and the ESP8266 WiFi bridge, together with the Nucleo board holding the STM32H533RE, which acts as the central platform.
This thesis is the first work to put this very version of the board into operation and to evaluate it under load. The design oversights identified in the process are reported in @sec:pcb-impact-summary.

#figure(
  image("/assets/pictures/XRayLegacy_PCB_TopView.png", width: 70%),
  caption: [XRay Legacy V1 PCB, top view #imgsrc(<LaesserXRayLegacy2023>)],
) <fig:main-pcb>

== Microcontroller: STM32H533RE (Nucleo-H533RE) <sec:mcu>

The firmware runs on a Nucleo-H533RE board, ST's Nucleo-64
development board carrying an STM32H533RET6 microcontroller
@UM3121_2025. The choice of the microcontroller was determined according to the course "Embedded Systems" at it's  orientation of the future lab classes. It proved well suited to the requirements of the firmware as well.

#figure(
  image("/assets/pictures/NUCLEO_Board_Top_and_Bottom_view.png", width: 70%),
  caption: [STM32H5 Nucleo-64 board (MB1814), top and bottom layout #imgsrc(<UM3121_2025>)],
) <fig:nucleo-board>

The STM32H533RE is based on an Arm Cortex-M33 core with a hardware floating-point unit, clocked at up to 250 MHz @STM32H533xx2026. It provides 512 KB of flash and 272 KB of #gls("sram"). This exceeds the requirements of the sensor drivers, control loop, state machine, and telemetry stack implemented here, leaving headroom for future extensions.
The #gls("i2c") buses connect the ADS7128 ADC, the BNO055 IMU, and the VL53L1X distance sensors. A #gls("usart") carries the traffic of the ESP8266 WiFi bridge, and the #gls("pwm") timers drive the motor and steering actuators. The corresponding firmware implementation is described in @sec:i2c-stack and @sec:actuator-control.

The Nucleo-64 board provides the infrastructure required for development, including an on-board STLINK-V3EC debugger and programmer, headers exposing the I/O of the STM32 for test wiring, and support for the STM32CubeMX and STM32CubeIDE toolchain used to generate the peripheral initialisation code @STM32CubeMX2026.

One feature of theSTM32H5 series is relevant beyond these specifications. The series includes a
#gls("rom") system memory bootloader, which the over-the-air update mechanism of this thesis uses to reflash the vehicle over WiFi.

== Sensor Suite <sec:sensors>

=== Time-of-Flight Distance Sensors (VL53L1X) <sec:tof>

The platform uses three ST VL53L1X, a
#gls("tof") laser-ranging modules from the FlightSense family
@VL53L1X2024. 
Unlike conventional infrared proximity sensors, which derive distance from the intensity of the reflected light, the VL53L1X measures the time a 940 nm laser pulse requires to travel to the target and back. The returning photons are detected by a #gls("spad") receiving array sensitive enough to register individual photons.
That timing-based principle makes the reported
distance largely independent of the target's color or reflectance, which
matters on a track where the car measures its distance to wooden barriers..

#figure(
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    align: horizon,
    image("/assets/pictures/VL53L1X_Pimoroni_Breakout.jpg", width: 60%),
    image("/assets/pictures/VL53L1X_Pimoroni_Breakout_Back.jpg", width: 60%),
  ),
  caption: [VL53L1X distance sensor, Pimoroni breakout board, front and back #imgsrc(<PimoroniVL53L1XBreakout2026>)],
) <fig:tof-sensor>

Each of the three sensors is mounted on a Pimoroni breakout board, shown in @fig:tof-sensor, and communicates over #gls("i2c") at up to 400 kHz. All VL53L1X devices start up with the same fixed address, so the three sensors cannot share a single bus without further measures. Each sensor provides an active-low XSHUT pin that holds it in standby. The firmware uses these pins to activate the sensors individually at startup and assign a separate address to each. @sec:i2c-stack describes this sequence.

Ranging is tuned through three settings. The distance mode trades range against
immunity to ambient light, reaching up to 3.6m in the dark in long mode but
around 1.35m in short mode regardless of lighting conditions. The timing budget defines the 
duration of a measurement, trading range and repeatability against the ranging rate.
The #gls("roi") restricts the active part of the 16x16 #gls("spad") array,
which narrows the diagonal #gls("fov") from 27° down to as little as 15°.
The front sensor operates in long mode
with a narrow 4x4 #gls("roi") to keep its #gls("fov") tight on the track ahead,
while the left and right sensors operate in short mode with a wider 10x10
#gls("roi") to pick up a nearby wall.

=== IMU (BNO055) <sec:imu>

The #gls("imu") of the platform is a Bosch Sensortec BNO055. The device combines a triaxial 14-bit accelerometer, a triaxial 16-bit gyroscope rated up to 2000 °/s, a triaxial magnetometer, and a 32-bit Cortex-M0+ microcontroller running the sensor fusion firmware provided by Bosch @BNO0552021.
Rather than transmitting raw accelerometer, gyroscope,
and magnetometer samples to the host, the BNO055 fuses them on-chip and
reports ready-to-use orientation data over #gls("i2c"). That sets the
STM32 free to run its control loop and state machine instead of a
fusion filter of its own.

#figure(
  image("/assets/pictures/BNO055.png", width: 40%),
  caption: [BNO055, 28-pin LGA package #imgsrc(<MouserBNO0552026>)],
) <fig:bno055>

The BNO055 exposes both non-fusion modes, where individual sensors can
be read raw, and fusion modes, where the on-chip algorithm combines
them. This platform runs it in NDOF mode, the fusion mode that uses all
nine degrees of freedom (accelerometer, gyroscope, and magnetometer
together) to compute absolute orientation referenced to magnetic north.
NDOF also keeps fast magnetometer calibration turned on, which brings
the magnetometer to a usable calibration state more quickly than the
alternative NDOF_FMC_OFF mode. In this mode the fusion algorithm
separates the accelerometer's raw signal into a gravity vector and a
linear acceleration term, and reports orientation as both quaternion
and Euler-angle data.

On the #gls("i2c") side the BNO055 answers to one of two fixed addresses,
selected by the level of its COM3 pin, 0x29 when COM3 is high and 0x28
when it is low. This platform's firmware talks to it at 0x28, so COM3
is wired low on the #gls("pcb"). At startup the firmware checks the
chip's fixed identification value before doing anything else. It only
issues a hardware reset if that check fails. A reset costs on the
order of a second, while an already-booted sensor answers immediately.

This platform's driver does not read the BNO055's Euler-angle heading
register directly. Instead it reads the quaternion output, where the
register map fixes 16384 #glspl("lsb") to one unitless quaternion
component, and computes yaw from the resulting w, x, y, z values with
an arctangent. Reading the quaternion this way avoids the
discontinuities and gimbal-lock artifacts that Euler-angle output is
prone to. Yaw rate is read straight from the gyroscope's Z-axis
register, where 16 #glspl("lsb") correspond to one degree per second,
and linear acceleration, with gravity already removed by the fusion
algorithm, is read where 100 #glspl("lsb") correspond to one meter per
second squared.

Because the fusion algorithm calibrates continuously in the
background, the BNO055 also reports a live calibration status. One
field covers the system as a whole, and one covers each of the three
physical sensors. Each field packs two bits, with 3 meaning fully
calibrated and 0 meaning uncalibrated. Until the magnetometer field in
particular reaches a full calibration, the fused heading can drift.
That is why this platform's firmware surfaces calibration status
alongside heading, yaw rate, and acceleration, instead of trusting the
fused output unconditionally.

=== ADC (ADS7128) <sec:adc>

The platform's external ADC is a Texas Instruments ADS7128, an
8-channel, 12-bit, multiplexed #gls("sar") ADC in a 3mm x 3mm, 16-pin
WQFN package @ADS71282020. Each of its eight channels can be
independently configured as an analog input, a digital input, or a
GPIO output, and an internal oscillator drives the conversion process,
so the device needs no clock from the host. As noted in @sec:mcu, the
STM32H533RE has only two internal ADCs of its
own, while the ADS7128 sits on the same I2C bus as the
rest of the sensor stack and adds eight more channels
without using any of the microcontroller's own ADC pins, more
headroom than this platform ends up needing.

#figure(
  image("/assets/pictures/ads7128.png", width: 50%),
  caption: [ADS7128, WQFN-16 package #imgsrc(<TIADS7128ProductPage2026>)],
) <fig:ads7128>

The ADS7128 answers to one of eight I2C addresses, selected by a pair
of external resistors on its ADDR pin rather than a single
logic-level pin, letting more than one ADS7128 share a bus if a
design ever needs it. How this platform's firmware drives the device
and which of its eight channels it actually uses is covered in
@sec:adc-handling.

=== Wheel-speed Sensor (TLE4966L) <sec:hall>

Wheel speed is measured with an Infineon TLE4966L, a dual Hall-effect
IC in a four-lead PG-SSO-4-1 package @TLE4966L2020. It sits next to a
ring of alternating magnetic poles on the wheel and outputs one speed
pulse per pole pair as the wheel turns.

#figure(
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    align: horizon,
    image("/assets/pictures/TLE4966L.png", width: 55%),
    image("/assets/pictures/RPM_Sensor_V2.0_Board.png", width: 65%),
  ),
  caption: [TLE4966L, PG-SSO-4-1 package, and this platform's RPM sensor board carrying it #imgsrc(<InfineonTLE4966LProductPage2026>, <KrennRPMSensor2026>)],
) <fig:tle4966l>

What sets the TLE4966L apart from a plain Hall switch is a second
output pin that reports rotation direction alongside the speed pulse.
A plain switch can only say how fast a wheel is turning, not which
way. This platform uses the TLE4966L for that second signal, because
telling forward from reverse matters for the speed controller.

== Motor Drivers (BTN9970LV) <sec:motor-drivers>

The drive motor is switched by two Infineon BTN9970LV half-bridge
drivers from Infineon's NovalithIC+ family @BTN9970LV2021. Each
integrates a high-side and a low-side MOSFET with a driver IC
in one automotive-qualified package.

#figure(
  image("/assets/pictures/btn9970lv.jpg", width: 45%),
  caption: [BTN9970LV, PG-HSOF-7 package #imgsrc(<Rutronik24BTN9970LV2026>)],
) <fig:btn9970lv>

Each driver takes two digital inputs. IN selects which side of the
half-bridge conducts, fast enough to be driven straight from a #gls("pwm")
signal, and INH enables the device or tristates both sides. The datasheet
notes that two of them form an H-bridge, and this platform wires exactly
that, one IC on each motor terminal, so a direction and a speed can be set
from the pair. How the firmware drives them is covered in @sec:actuator-control.

Each driver also reports its high-side load current on an IS pin, which this
platform reads per motor terminal on one #gls("adc") channel each, as
@sec:adc-handling describes. Overcurrent, overtemperature, and undervoltage
protection are built into the driver and latch it off until the fault clears,
with no firmware support needed.

== WiFi Bridge (ESP8266) <sec:esp-bridge>

The platform's only wireless link is an AZ-Delivery D1 mini, a small
board built around an ESP8266MOD-12F WiFi module, with 4MB of flash
and a micro-USB connector used for both power and programming
@AZDeliveryD1MiniManual2019. It follows the same D1 mini form factor
and pinout as the original WeMos design, but this platform uses
AZ-Delivery's own board, not a genuine WeMos part. On this platform it
does one job. It sits on the USART described in @sec:mcu, between the
STM32 and the AI-MotionLab testsuite, moving telemetry and #gls("ota")
update traffic over WiFi that would otherwise need a wired connection
to the car.

#figure(
  image("/assets/pictures/D1_Mini_TopDown.jpg", width: 30%),
  caption: [AZ-Delivery D1 mini, top-down view #imgsrc(<AZDeliveryD1Mini2026>)],
) <fig:d1-mini>

This platform's firmware treats that link as a plain byte pipe. It
writes bytes to the USART and reads bytes back over #gls("dma"), with
no awareness of what the ESP8266 does with them beyond that. The
ESP8266's own firmware, which handles the WiFi connection and frame
routing, is not part of this thesis.
