= Firmware Design (STM32) <ch:firmware>

== Application Structure Overview <sec:app-structure>

== Sensor Drivers and Data Acquisition <sec:sensor-drivers>

=== I2C Sensor Stack Integration and Address Assignment at Startup <sec:i2c-stack>

=== ADC Channel Handling <sec:adc-handling>

== Actuator Control <sec:actuator-control>
// motor driver interfacing

== State Machine Design <sec:state-machine>

=== Overview of States and Transitions <sec:states-transitions>

=== Flag-Based Event Mechanism <sec:flag-events>
// design and motivation

== Turn Detection Algorithm <sec:turn-detection>

=== Rate-of-Change Threshold on Side ToF Sensors <sec:turn-rate-threshold>
// distance-normalized

=== Alignment and Wall-Ahead Preconditions <sec:turn-preconditions>

== Turn Completion Logic <sec:turn-completion>

=== Heading-Delta Tracking per Tick <sec:heading-delta>

=== Completion Criteria <sec:completion-criteria>
// 90 deg +/- 10 deg, front distance > 1.2 m

=== Failsafe Exit Condition <sec:failsafe-exit>
// 180 deg timeout
