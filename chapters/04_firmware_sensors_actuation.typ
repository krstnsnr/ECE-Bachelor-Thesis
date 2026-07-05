= Firmware Design: Sensors and Actuation (STM32) <ch:firmware-sensors>

== Application Structure Overview <sec:app-structure>
// main.c / App structure, module overview (drivers, control loop, state machine)

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
