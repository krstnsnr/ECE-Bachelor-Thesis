= Firmware Design: State Machine and Turn Detection (STM32) <ch:firmware-state-machine>

== State Machine Design <sec:state-machine>

=== Overview of States and Transitions <sec:states-transitions>
// CAR_STOP, CAR_START, CAR_STRAIGHT, CAR_TURN_LEFT/RIGHT, CAR_FULL_THROTTLE,
// CAR_RECOVER, CAR_REMOTE_CONTROL (state_machine.h)

=== Flag-Based Event Mechanism <sec:flag-events>
// design and motivation; event_detection.c: EVENT_BATTERY_LOW, EVENT_CRASH, EVENT_STUCK
// already implemented -- describe as current functionality, not future work

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

// Remaining open item from the old "Future Work" chapter:
// remote-control state (CAR_REMOTE_CONTROL) already implemented -- describe
// its transition conditions here rather than as an outlook item
