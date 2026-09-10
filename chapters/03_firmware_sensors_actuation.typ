#import "/helpers/gls.typ": gls, glspl

= Firmware Design: Sensors and Actuation <ch:firmware-sensors>

== Application Structure Overview <sec:app-structure>

The entry point of the firmware executes a fixed initialization
sequence once and then enters an infinite loop that runs for the
remaining runtime of the car. Initialization covers the STM32
peripherals first, namely clocks, DMA, I2C, timers, and USART. The
application modules follow in a fixed order, starting with the ESP8266
link and the OTA protocol, then the servo and motor outputs, the
display, the ToF sensors, the start/stop button, the ADC, the Hall
sensor, and the IMU last.

Timing in the main loop comes from a hardware timer rather than from a
blocking delay. On every pass the loop toggles a debug pin, processes
pending OTA traffic, and passes the start and stop button state to the
state machine. A 100 Hz timer interrupt sets a pending flag on every
tick, and the control step of the loop executes when that flag is set.
OTA handling and button response therefore run on every pass,
independently of the control step, while the control step keeps a
fixed 100 Hz rate.

#figure(
  image("/assets/graphics/selfdrawn/system_diagram.svg", width: 100%),
  caption: [Application architecture: sensor inputs, telemetry globals, state machine, and actuator outputs],
) <fig:system-diagram>

@fig:system-diagram shows the structure of a single control step. The
ToF sensors, the IMU, the Hall speed sensor, and the ADC write into
one shared set of telemetry globals, together with the start/stop
button and the wireless bridge. Each signal is sampled at its own
rate. The IMU and the Hall sensor are read on every 100 Hz tick, the
front ToF sensor at 33 Hz, and the side ToF sensors at
50 Hz. The ADC uses two rates, 2 Hz for the battery voltage and 50 Hz
for the motor current.

The motor current is read from one driver at a time. The channel of
the active driver is sampled at 50 Hz for as long as the commanded
direction stays the same. The idle driver is skipped, since its
current-sense output is valid only while it drives.
@sec:motor-drivers describes this behavior.

The state machine reads the same telemetry on every 100 Hz tick and
drives two PID controllers, one for motor speed and one for steering.
These set the #gls("esc") and servo outputs.
@sec:actuator-control describes the actuation path.

This structure follows the sensor, controller, and actuator layering
common to embedded robotics platforms @Braunl2008. Each sensor driver,
described in @sec:sensor-drivers, addresses only its own device. The
telemetry globals hold plain data, readable and writable by name, so
the OTA link exposes them to the AI-MotionLab testsuite without
protocol code in every module. The state machine operates on that
shared data alone and accesses no driver or actuator directly.

== Sensor Drivers and Data Acquisition <sec:sensor-drivers>
=== I2C Sensor Stack Integration and Address Assignment at Startup <sec:i2c-stack>

Five I2C devices, namely the three ToF sensors, the ADC, and the IMU,
share the single I2C1 bus of the STM32 introduced in @sec:mcu. Each
device must be reachable at its own address before its driver can be
used. @fig:i2c-startup shows the startup order and the address
assigned to each device.

#figure(
  image("/assets/graphics/selfdrawn/i2c_startup_sequence.svg", width: 85%),
  caption: [I2C1 startup sequence and address assignment],
) <fig:i2c-startup>

The three ToF sensors make this sequence necessary. As noted in
@sec:tof, every VL53L1X starts up at the same fixed address. The
firmware therefore holds all three in hardware standby and activates
them one at a time. Each sensor is reassigned to its own 8-bit
address, 0x30, 0x32, and 0x34, before the next one is released.
Ranging starts only after all three have a unique address.

The ADC and the IMU require no such sequence. The address of the
ADS7128 is set in hardware by a resistor on its ADDR pin, as @sec:adc
describes, and is tied on this platform to 0x20. The address of the
BNO055 follows from the level on its COM3 pin, described in @sec:imu.
Both addresses are unique before the initialization functions run, so
each function only verifies that the device responds at the expected
address.

=== ADC Channel Handling <sec:adc-handling>

All register access uses a two-byte command, an operation code
followed by a register address. The driver of this platform uses two
of the opcodes defined in the datasheet @ADS71282020, one for a single
register write and one for a single register read. A completed 12-bit
conversion result is read back #gls("msb")-justified across two bytes,
the upper eight bits followed by the lower four bits padded with
zeros. The driver reassembles them into a single 12-bit value by
shifting and combining the two bytes.

The device powers up in manual mode, which this platform retains
instead of the auto-sequence or autonomous modes. In manual mode the
host selects a channel through a register write rather than by
toggling the multiplexer directly. The driver therefore writes the
required channel to the channel-select register of the device before
every conversion. It also enables 32× oversampling, the built-in
averaging filter of the ADS7128, which adds settling time and reduces
noise @ADS71282020. After a channel change the driver reads the channel twice and
discards the first conversion, so that only a settled sample is used.

This platform uses three of the eight channels. One channel reads the
battery voltage through a 10 kΩ/18 kΩ divider. The other two read the negative and
positive-side current-sense outputs of the BTN9970LV half-bridge motor
drivers described in @sec:motor-drivers. Each driver mirrors its load
current to the IS pin, reduced by the differential current sense ratio of
the device. The datasheet gives that ratio as typically 40 × 10³
@BTN9970LV2021. A 2 kΩ sense resistor turns the resulting sense current
into a voltage for the ADC channel. The firmware reverses this chain. It
divides the measured voltage by the sense resistor, subtracts the typical
offset current of 160 µA, and multiplies by 40 × 10³ to obtain the load
current @BTN9970LV2021.

The rest of the firmware works with physical units only. Above the
channel-select and read functions, the driver exposes two getters,
`ADS7128_GetBatteryVoltage()` and `ADS7128_GetCurrent()`. Each of them
reads its channel, waits for a settled sample, and converts the result
into a physical unit, volts for the battery and amperes for the motor
current, using the relations given above. `control_loop.c` calls the getter for
the channel it requires, at the rates shown in @fig:system-diagram,
and writes the returned value into the matching telemetry global.

== Actuator Control <sec:actuator-control>

@sec:app-structure introduces the two PID controllers that the state
machine drives on every 100 Hz tick, one for steering and one for
speed. Both share a single implementation. A `PID_t` instance holds
its own gains, an accumulated integral term, and the previous error,
together with the output limits.

Each call first computes the error as setpoint minus measurement. The
proportional term follows from that error. The integral term
accumulates over time and is clamped to a fixed fraction of the output
range before it is scaled by the integral gain. The derivative term
follows from the change in error since the last call. The three terms
are summed, and the result is clamped to the output range of the
controller before it is returned.

This is a standard parallel-form PID controller @Braunl2008. The
clamped integral prevents windup while the output is saturated, and
the final output clamp restricts the result to the range the actuator
can accept.

The starting gains for both controllers came from Skogestad's SIMC
tuning rules @Skogestad2003, applied to step-response data captured on
the platform. The resulting gains are stored as writable telemetry
fields. `state_machine.c` reloads them into its PID instances at the
start of every tick. A gain written from the AI-MotionLab testsuite
over the OTA link therefore takes effect on the next control step,
without a rebuild or a reflash. The gains in the current firmware
result from this live tuning, starting from the SIMC values.

The output of the speed PID drives the motor through
`Motor_SetSpeed()`. Two BTN9970LV half-bridges form the H-bridge of
the drive motor, as @sec:motor-drivers describes. Each one takes an IN
pin, which selects the conducting side, and an INH pin, which enables
the device or sets it to high impedance.

This platform holds the IN pin of each IC at a fixed level for the
duration of a direction, IN1 high for forward and IN2 high for
reverse. The two ICs always receive opposite levels, so one motor
terminal is pulled high while the other is pulled low. A single shared
PWM signal drives the INH pins of both ICs together, and its duty
cycle follows from the magnitude of the PID output. Each cycle enables
both halves of the bridge for the high part of the duty cycle and sets
both to high impedance for the remainder. The motor therefore coasts
during every off interval rather than being actively braked. Setting
both IN pins to the same level, or holding the shared INH low, stops
the motor.

The output of the steering PID passes through a calibration step
rather than a direct mapping. `Set_Steering()` takes a command in the
range from -100 to 100 and clamps it to that range. It then
interpolates linearly between three measured pulse widths, 1200 µs at
full left, 1480 µs at center, and 1800 µs at full right, which
accounts for the asymmetry of the servo range around center. The
result is clamped a second time to the wider hardware safety range
from 500 µs to 2500 µs, immediately before it is written to the timer
register that drives the steering servo.
