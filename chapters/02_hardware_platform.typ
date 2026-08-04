#import "@preview/glossarium:0.5.10": gls, glspl

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
platform's #gls("pcb") (@sec:main-pcb) fill. Being a widely sold competition kit
also means worn or crashed parts are easy to source and replace, which
matters when a fleet of these cars is driven by students.

#figure(
  image("/assets/pictures/XRAY_M18_Pro_LiPo.jpg", width: 40%),
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

This thesis's firmware runs on a Nucleo-H533RE board, ST's Nucleo-64
development board carrying an STM32H533RET6 microcontroller
@UM3121_2025. That microcontroller choice came with the #gls("pcb")
(@sec:main-pcb). What follows is why it turned out
to be a good fit for the firmware built on top of it.

#figure(
  image("/assets/pictures/NUCLEO_Board_Top_and_Bottom_view.png", width: 70%),
  caption: [STM32H5 Nucleo-64 board (MB1814), top and bottom layout],
) <fig:nucleo-board>
#align(center, text(size: 9pt, style: "italic")[Image source: @UM3121_2025])

The STM32H533RE is built around an Arm Cortex-M33 core with #gls("trustzone")
and a hardware #gls("fpu"), clocked at up to 250 MHz @STM32H533xx2026. 
It has 512 Kbytes of dual-bank flash and
272 Kbytes of #gls("sram"). That is more of both than this project's
sensor drivers, control loop, state machine, and telemetry stack need on
their own, which leaves
headroom for the firmware to grow over the course of the thesis instead
of running into a memory wall.

In the 64-pin #gls("lqfp") package used on this board, the STM32H533RE
exposes three #gls("i2c") interfaces, four #gls("spi") interfaces, six
#gls("usart") and #gls("uart") instances, two 12-bit #glspl("adc"), and a
wide set of general-purpose and #gls("pwm")-capable timers
@STM32H533xx2026. That peripheral count fits this platform directly. The
#gls("i2c") buses are enough to host the ADS7128 #gls("adc"), the BNO055
#gls("imu"), and the VL53L1X distance sensors (@sec:i2c-stack), a
#gls("usart") carries the ESP8266 WiFi bridge traffic, and the
#gls("pwm") timers drive the motor and steering actuators
(@sec:actuator-control).

The Nucleo-64 board wraps that microcontroller with everything needed to
start developing right away. An on-board STLINK-V3EC debugger and
programmer removes the need for a separate probe. Arduino Uno V3 and ST
morpho headers expose all of the STM32's I/O for breakout wiring during
bring-up. ST's free STM32CubeMX and STM32CubeIDE toolchain generates
peripheral initialization code straight from a pin and clock
configuration @STM32CubeMX2026. A capable microcontroller on a
development board built for fast iteration follows the same
sensor-plus-actuator-plus-microcontroller architecture already
established for embedded robotics platforms @Braunl2008. This particular
pairing also leaves enough headroom for this thesis's tuning and
telemetry workflow.

One STM32H5 feature matters beyond raw specs. The series includes a
#gls("rom") system memory bootloader that this thesis's over-the-air update path
uses to reflash the car over WiFi, without setting aside any of the
512 Kbytes of flash for a bootloader of its own (@ch:integration).

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

The bare VL53L1X is a fully integrated LGA12 package measuring
4.9 x 2.5 x 1.56mm. On this platform each of the three sensors sits on
a Pimoroni breakout board (@fig:tof-sensor), which brings the module's
pins out to a row of solder pads. The breakout is still small enough
to mount on the chassis. It
communicates over #gls("i2c") at up to 400kHz. It also exposes an
active-low XSHUT pin for hardware shutdown and a GPIO1 interrupt
output. This platform's firmware uses XSHUT to sequence startup when
more than one sensor shares the bus (@sec:i2c-stack).

Ranging behavior is controlled through three parameters. Distance mode
selects between short, medium, and long range. It trades maximum
distance against immunity to ambient light. In long mode the sensor
reaches up to 3.6m in the dark, but only about 0.73m under strong
ambient light. Short mode is largely unaffected by ambient light and
tops out around 1.35m to 1.36m either way. Timing budget sets how long
each measurement takes, from 20ms up to 1000ms. A longer budget extends
maximum range and reduces the repeatability error of a reading, at the
cost of a lower ranging rate. #gls("roi") lets the host restrict the
active area of the sensor's 16x16 #glspl("spad") array down to as
little as 4x4 #glspl("spad"). That narrows the sensor's diagonal
#gls("fov") from a full 27 degrees to as little as 15 degrees.

Every VL53L1X boots with the same fixed I2C address, 0x52 in the
datasheet's 8-bit write convention. That is not a problem for a single
sensor, but it conflicts as soon as more than one shares a bus. This
platform puts three sensors, front, left, and right, on the same I2C
bus, so all three would otherwise answer to that address at once. The
datasheet's XSHUT pin resolves this. Holding it low puts a module into
hardware standby with no I2C activity, so each sensor can be woken and
assigned a unique address in turn while the others stay held down. This
platform's firmware wires its own XSHUT line to each sensor and steps
through them one at a time at startup, reassigning each to its own
address before the next is released (@sec:i2c-stack).

The three sensors are not configured identically. The front sensor runs
in long distance mode with a 33ms timing budget, the fastest budget the
datasheet specifies as usable across every distance mode, including
long. Its #gls("roi") is narrowed to 4x4 #glspl("spad"), keeping its
#gls("fov") tight on whatever is ahead of the car. The left and right
sensors run in short distance mode at the datasheet's fastest possible
20ms timing budget. Their #gls("roi") is widened to 10x10
#glspl("spad"), suited to picking up a wall or barrier close to the
side of the car. Inter-measurement time is set equal to each sensor's
timing budget, so every sensor starts its next measurement as soon as
the previous one finishes.

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
so the device needs no clock from the host. It sits on the same I2C
bus as the rest of the sensor stack (@sec:i2c-stack), giving the
firmware extra analog channels without using any of the STM32's own
ADC pins.

#figure(
  image("/assets/pictures/ads7128.png", width: 50%),
  caption: [ADS7128, WQFN-16 package],
) <fig:ads7128>
#align(center, text(size: 9pt, style: "italic")[Image source: @TIADS7128ProductPage2026])

The ADS7128 answers to one of eight I2C addresses, selected by two
external resistors on its ADDR pin rather than a single logic-level
pin. This platform ties one of those resistors to 100kOhm and leaves
the other unpopulated. The datasheet's address table maps that
combination to 0x10. All register access goes through a two-byte
command, an opcode followed by a register address. This platform's
driver uses only two of the opcodes the datasheet defines, 0x08 for a
single register write and 0x10 for a single register read. A finished
12-bit conversion result is read back MSB-justified across two bytes,
the upper eight bits followed by the lower four bits padded with
zeros. The driver reassembles the two bytes into a single 12-bit value
with a shift and a combine.

The device powers up in manual mode, and this platform leaves it
there instead of switching to auto-sequence or autonomous mode. In
manual mode the host selects a channel with a register write, instead
of toggling the multiplexer directly. This platform's driver writes
the desired channel to the CHANNEL_SEL register before every
conversion, and enables 32x oversampling through the OSR_CFG register,
the datasheet's built-in averaging filter, for extra settling time and
noise reduction. After switching to a new channel, the driver reads it
twice and discards the first conversion. That way a stale sample left
over from the previous channel is never mistaken for a valid reading.

This platform uses three of the eight channels. One reads the
battery voltage through a 10kOhm/18kOhm divider. The other two read
the negative and positive-side current-sense outputs of the
BTN9970LV half-bridge motor drivers (@sec:motor-drivers). Routing
these three signals through the ADS7128 keeps them on the same I2C
bus as the rest of the sensor stack, instead of requiring dedicated
analog routing back to the STM32's own ADC inputs.

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
- Missing pulldown on #gls("esc") INH pin

=== Recommendations for the Next PCB Revision <sec:pcb-recommendations>
