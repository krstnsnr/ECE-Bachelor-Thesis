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
// ads7128, bno055, tof_sensor addressing

=== ADC Channel Handling <sec:adc-handling>
// ads7128

== Actuator Control <sec:actuator-control>
// motor_control, servo_steering, pid, control_loop
// cite @Skogestad2003 where you justify the PID tuning method used

// Extended Logging (distance sensor data, actual vs. set speed, IMU data)
// mention here if implemented as part of control_loop / telemetry_fields
