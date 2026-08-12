#import "@preview/glossarium:0.5.10": gls, glspl

= Firmware Design: Sensors and Actuation (STM32) <ch:firmware-sensors>

== Application Structure Overview <sec:app-structure>

The firmware's entry point does two things. It runs a fixed
initialization sequence once, then drops into an infinite loop for
the rest of the car's runtime. Initialization first brings up the
STM32's own peripherals (clocks, DMA, I2C, timers, USART), then each
application module in turn, the ESP8266 link, OTA protocol, servo and
motor outputs, the display, the ToF sensors, the start/stop button,
the ADC, the Hall sensor, and the IMU last. 

The main loop itself is lean and does not pace itself with a blocking
delay. Every pass it toggles a debug pin, processes any pending OTA
traffic, and lets the state machine check whether the start or stop
button has just been pressed. Actual timing comes from a hardware
timer instead. A 100Hz timer interrupt sets a pending flag on every
tick, and the loop's control step only does its work when that flag
is set. That keeps OTA handling and button response running every
pass, uninterrupted by whatever the control step is doing, while
still giving the control step itself a fixed 100Hz rate.

#figure(
  image("/assets/graphics/selfdrawn/system_diagram.svg", width: 100%),
  caption: [Application architecture: sensor inputs, telemetry globals, state machine, and actuator outputs],
) <fig:system-diagram>

@fig:system-diagram shows how a single control step is
structured. Every ToF sensor, the IMU, the Hall speed sensor, and the
ADC all write into one shared set of telemetry globals, alongside the
start/stop button. Reads happen at different rates depending on the
signal. The IMU and Hall sensor are read every 100Hz tick, the front
ToF sensor at about 30Hz and the side sensors at 50Hz, and the ADC
itself splits across two rates, battery voltage at 2Hz and motor
current at a faster 50Hz. That current reading only ever comes from
whichever motor driver is currently doing the driving. Its channel
is read every 50Hz sample for as long as the commanded direction
stays the same, while the idle side is not sampled at all, since its
current-sense output is not a valid reading while it is
not driving (@sec:motor-drivers). The state machine reads that same
telemetry each 100Hz tick and drives two
PID controllers, one for motor speed and one for steering,
which in turn set the ESC and servo outputs (@sec:actuator-control).

Splitting the firmware this way keeps each module narrow. Sensor
drivers only know how to talk to their own chip (@sec:sensor-drivers).
The telemetry globals are just data, readable and writable by name so
the OTA link can expose them to the AI-MotionLab testsuite without
every module needing its own protocol code. The state machine only
reads and writes that shared data, never talking to a driver or an
actuator directly.

== Sensor Drivers and Data Acquisition <sec:sensor-drivers>
=== I2C Sensor Stack Integration and Address Assignment at Startup <sec:i2c-stack>

Five I2C devices, three ToF sensors, the ADC, and the IMU, share the
STM32's single I2C1 bus (@sec:mcu). Each has to be reachable at its
own address before its driver can be used. @fig:i2c-startup shows the
order this happens in during boot and the address each device ends up
at.

#figure(
  image("/assets/graphics/selfdrawn/i2c_startup_sequence.svg", width: 75%),
  caption: [I2C1 startup sequence and address assignment],
) <fig:i2c-startup>

The three ToF sensors are the reason this has to be a sequence at
all. Every VL53L1X boots at the same fixed address (@sec:tof), so
this platform's firmware holds all three in hardware standby and
brings them up one at a time, each getting reassigned to its own 8-bit
address (0x30, 0x32, 0x34) before the next is released. Only once all
three have a unique address does ranging start on any of them.

The ADC and IMU need no such dance. The ADS7128's address is set in
hardware by a resistor on its ADDR pin (@sec:adc), tied on this
platform to give address 0x20, and the BNO055's by the level on its
COM3 pin (@sec:imu). Both are already unique by the time their init
functions run, so each just confirms the device answers where it is
expected to.

=== ADC Channel Handling <sec:adc-handling>

All register access goes through a two-byte command, an operation code
followed by a register address. This platform's driver uses only two
of the opcodes the datasheet defines, one for a single register write
and one for a single register read. A finished 12-bit conversion
result is read back MSB-justified across two bytes, the upper eight
bits followed by the lower four bits padded with zeros, and the
driver reassembles the two into a single 12-bit value with a shift
and a combine.

The device powers up in manual mode, and this platform leaves it
there instead of switching to auto-sequence or autonomous mode. In
manual mode the host selects a channel with a register write instead
of toggling the multiplexer directly, so this platform's driver
writes the desired channel to the device's channel-select register
before every conversion. It also enables 32x oversampling, the
datasheet's built-in averaging filter, for extra settling time and
noise reduction. After switching to a new channel, the driver reads
it twice and discards the first conversion, so a stale sample left
over from the previous channel is never mistaken for a valid one.

This platform uses three of the eight channels. One reads the
battery voltage through a 10kOhm/18kOhm divider. The other two read
the negative and positive-side current-sense outputs of the
BTN9970LV half-bridge motor drivers (@sec:motor-drivers), each
converted from the driver's IS pin current to a voltage across a
2kOhm sense resistor before the ADC channel sees it.

None of that raw handling reaches the rest of the firmware. On top
of the channel-select and read functions, the driver exposes two
purpose-built getters, `ADS7128_GetBatteryVoltage()` and
`ADS7128_GetCurrent()`, each of which reads its channel, waits for a
settled sample, and converts the result into a physical unit itself,
volts for the battery and amps for motor current, using the divider
and current-sense math already covered in @sec:motor-drivers.
`control_loop.c` never touches a raw ADC code. It just calls the
getter for whichever channel it needs, at the rates already shown in
@fig:system-diagram, and writes the returned value straight into the
matching telemetry global.

== Actuator Control <sec:actuator-control>
// motor_control, servo_steering, pid, control_loop
// cite @Skogestad2003 where you justify the PID tuning method used

// Extended Logging (distance sensor data, actual vs. set speed, IMU data)
// mention here if implemented as part of control_loop / telemetry_fields
