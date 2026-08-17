#import "/helpers/gls.typ": gls, glspl

= Hardware Platform <ch:hardware>

== Chassis: XRAY M18 Pro LiPo 4WD <sec:chassis>

The chassis this thesis's hardware baseline builds on is the XRAY M18 Pro
LiPo, a 1/18-scale, four-wheel-drive shaft-drive touring car kit from XRAY
@MichaelsRCXRAYM18Pro2026. It measures 220mm long on a 150mm wheelbase and
weighs about 165g standalone. The main chassis plate is #gls("cnc")-machined
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
a rougher surface. Second, the kit ships bare. Radio, servo, #gls("esc"),
motor, and battery are not included. The electronics have to be built up from
scratch, which is exactly the gap this thesis's firmware and this
platform's #gls("pcb"), covered in @sec:main-pcb, fill. Being a widely sold competition kit
also means worn or crashed parts are easy to source and replace, which
matters when a fleet of these cars is driven by students.

#figure(
  image("/assets/pictures/XRAY_M18_Pro_LiPo.jpg", width: 40%),
  caption: [XRAY M18 Pro LiPo 4WD chassis],
) <fig:chassis>
#align(center, text(size: 9pt, style: "italic")[Image source: @MKRacingXRAYM18Pro2026])

== Main PCB (XRay Legacy V1) <sec:main-pcb>

Everything in this chapter bolts onto one custom #gls("pcb"), designed
in-house by A. Läßer specifically for this STM32-based generation of
CrazyCar @LaesserXRayLegacy2023. It is the board that ties the rest of
the platform together. The #gls("i2c") sensor stack, the motor and
steering drivers, the ADC, and the ESP8266 WiFi bridge all mount
to it, alongside the Nucleo board carrying the STM32H533RE itself.
This thesis's firmware runs on that PCB, and this thesis is also the
first to bring the board up and evaluate it. @sec:pcb-impact-summary
reports the oversights that surfaced during that evaluation.

#figure(
  image("/assets/pictures/XRayLegacy_PCB_TopView.png", width: 70%),
  caption: [XRay Legacy V1 PCB, top view],
) <fig:main-pcb>
#align(center, text(size: 9pt, style: "italic")[Image source: @LaesserXRayLegacy2023])

== Microcontroller: STM32H533RE (Nucleo-H533RE) <sec:mcu>

This thesis's firmware runs on a Nucleo-H533RE board, ST's Nucleo-64
development board carrying an STM32H533RET6 microcontroller
@UM3121_2025. That microcontroller choice came with the #gls("pcb")
introduced in @sec:main-pcb, and it turned out to be a good fit for the
firmware built on top of it.

#figure(
  image("/assets/pictures/NUCLEO_Board_Top_and_Bottom_view.png", width: 70%),
  caption: [STM32H5 Nucleo-64 board (MB1814), top and bottom layout],
) <fig:nucleo-board>
#align(center, text(size: 9pt, style: "italic")[Image source: @UM3121_2025])

The STM32H533RE is built around an Arm Cortex-M33 core with a hardware
#gls("fpu"), clocked at up to 250 MHz @STM32H533xx2026. It has 512 Kbytes of
flash and 272 Kbytes of #gls("sram"), more than this project's sensor drivers,
control loop, state machine, and telemetry stack need, which leaves headroom
for the firmware to grow. Its peripheral set fits the platform directly. The
I2C buses host the ADS7128 #gls("adc"), the BNO055 #gls("imu"), and the
VL53L1X distance sensors, a #gls("usart") carries the ESP8266 WiFi bridge
traffic, and the #gls("pwm") timers drive the motor and steering actuators.
The firmware side of both is covered in @sec:i2c-stack and
@sec:actuator-control.

The Nucleo-64 board adds what is needed to develop right away, an on-board
STLINK-V3EC debugger and programmer, headers that expose the STM32's I/O for
bring-up wiring, and ST's STM32CubeMX and STM32CubeIDE toolchain for generating
peripheral initialization code @STM32CubeMX2026.

One STM32H5 feature matters beyond raw specs. The series includes a
#gls("rom") system memory bootloader that this thesis's over-the-air update path
uses to reflash the car over WiFi, without setting aside any of the
512 Kbytes of flash for a bootloader of its own, as @ch:integration details.

== Sensor Suite <sec:sensors>

=== Time-of-Flight Distance Sensors (VL53L1X) <sec:tof>

Each of the three distance sensors on the platform is an ST VL53L1X, a
#gls("tof") laser-ranging module from ST's FlightSense family
@VL53L1X2024. A conventional IR proximity sensor infers distance from the
intensity of reflected infrared light. The VL53L1X instead times how long
a 940nm laser pulse takes to travel to a target and back, using a
#gls("spad") receiving array sensitive enough to register individual
returning photons. That timing-based principle makes the reported
distance largely independent of the target's color or reflectance, which
matters on a track where the car has to range off wood barriers reliably.

#figure(
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    align: horizon,
    image("/assets/pictures/VL53L1X_Pimoroni_Breakout.jpg", width: 60%),
    image("/assets/pictures/VL53L1X_Pimoroni_Breakout_Back.jpg", width: 60%),
  ),
  caption: [VL53L1X distance sensor, Pimoroni breakout board, front and back.],
) <fig:tof-sensor>
#align(center, text(size: 9pt, style: "italic")[Image source: @PimoroniVL53L1XBreakout2026])

Each of the three sensors sits on a Pimoroni breakout board, shown in
@fig:tof-sensor, and talks over #gls("i2c") at up to 400kHz. Every VL53L1X
boots at the same fixed address, so the three cannot simply share one bus. Each sensor
also has an active-low XSHUT pin that forces it into standby, and the firmware
uses those pins to bring the sensors up one at a time and give each its own
address at startup, a sequence @sec:i2c-stack walks through.

Ranging is tuned through three settings. The distance mode trades range against
immunity to ambient light, reaching up to 3.6m in the dark in long mode but
around 1.35m in short mode regardless of lighting. The timing budget sets how
long a measurement takes, trading range and repeatability against ranging rate.
The #gls("roi") restricts the active part of the 16x16 #gls("spad") array,
which narrows the diagonal #gls("fov") from 27 degrees down to as little as 15.
The three sensors use these differently. The front sensor runs in long mode
with a narrow 4x4 #gls("roi") to keep its #gls("fov") tight on the track ahead,
while the left and right sensors run in short mode with a wider 10x10
#gls("roi") to pick up a nearby wall.

=== IMU (BNO055) <sec:imu>

The platform's #gls("imu") is a Bosch Sensortec BNO055, a single package
that combines a triaxial 14-bit accelerometer, a triaxial 16-bit
gyroscope rated to 2000 degrees per second, a triaxial magnetometer, and
a 32-bit Cortex-M0+ microcontroller running Bosch's own sensor fusion
firmware @BNO0552021. Rather than handing raw accelerometer, gyroscope,
and magnetometer samples to the host, the BNO055 fuses them on-chip and
reports ready-to-use orientation data over #gls("i2c"). That leaves the
STM32 free to run its control loop and state machine instead of a
fusion filter of its own.

#figure(
  image("/assets/pictures/BNO055.png", width: 40%),
  caption: [BNO055, 28-pin LGA package],
) <fig:bno055>
#align(center, text(size: 9pt, style: "italic")[Image source: @MouserBNO0552026])

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
  caption: [ADS7128, WQFN-16 package],
) <fig:ads7128>
#align(center, text(size: 9pt, style: "italic")[Image source: @TIADS7128ProductPage2026])

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
  caption: [TLE4966L, PG-SSO-4-1 package, and this platform's RPM sensor board carrying it],
) <fig:tle4966l>
#align(center, text(size: 9pt, style: "italic")[Image sources: TLE4966L photo, @InfineonTLE4966LProductPage2026; RPM sensor board, @KrennRPMSensor2026])

What sets the TLE4966L apart from a plain Hall switch is a second
output pin that reports rotation direction alongside the speed pulse.
A plain switch can only say how fast a wheel is turning, not which
way. This platform uses the TLE4966L for that second signal, because
telling forward from reverse matters for the speed controller.

== Motor Drivers (BTN9970LV) <sec:motor-drivers>

The drive motor is switched by two Infineon BTN9970LV half-bridge
drivers from Infineon's NovalithIC+ family @BTN9970LV2021. Each
integrates a high-side and a low-side #gls("mosfet") with a driver IC
in one automotive-qualified package.

#figure(
  image("/assets/pictures/btn9970lv.jpg", width: 45%),
  caption: [BTN9970LV, PG-HSOF-7 package],
) <fig:btn9970lv>
#align(center, text(size: 9pt, style: "italic")[Image source: @Rutronik24BTN9970LV2026])

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
  caption: [AZ-Delivery D1 mini, top-down view],
) <fig:d1-mini>
#align(center, text(size: 9pt, style: "italic")[Image source: @AZDeliveryD1Mini2026])

This platform's firmware treats that link as a plain byte pipe. It
writes bytes to the USART and reads bytes back over #gls("dma"), with
no awareness of what the ESP8266 does with them beyond that. The
ESP8266's own firmware, which handles the WiFi connection and frame
routing, is not part of this thesis.
