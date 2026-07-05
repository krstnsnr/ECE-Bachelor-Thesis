= System Architecture <ch:architecture>

== High-Level System / Data-Flow Diagram <sec:data-flow>
// PC -> ESP8266 -> STM32

== Design Rationale <sec:design-rationale>
// why a frame-router bridge instead of a transparent UART pipe

== Wire Protocol Specification <sec:wire-protocol>

=== Frame Format <sec:frame-format>
// [CMD][LEN][PAYLOAD][CRC32]

=== CRC32 Implementation Consistency <sec:crc32>
// across PC/ESP/STM32

== Command Set <sec:command-set>

=== MSG Frames (0x30) <sec:msg-frames>
// text command relay

=== FIRMWARE Frames (0x20) <sec:firmware-frames>
// OTA update sequence

== OTA Firmware Update Mechanism <sec:ota-mechanism>

=== Staging to LittleFS and Image Verification <sec:ota-staging>

=== Entering the STM32 ROM Bootloader <sec:ota-bootloader>
// BOOT0/NRST, AN2606/AN3155

=== Flashing over USART <sec:ota-flashing>
// 8E1, 512 KB flat image

=== Failure Handling / ACK-NACK Semantics <sec:ota-failure-handling>

=== Bootstrap Limitation <sec:ota-bootstrap>
// first flash must be via ST-Link

== Text Command Interface <sec:text-command-interface>

=== PING/PONG <sec:ping-pong>

=== GET/SET and the Telemetry Field System <sec:get-set>
// writable g_params vs. read-only g_sensors

=== On-Device Input Validation <sec:input-validation>
// strtof, range/isfinite checks, and why not sscanf

== Multi-Car Addressing <sec:multi-car-addressing>
// CAR_ID, mDNS car_XX.local
