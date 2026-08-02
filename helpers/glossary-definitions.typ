// * Add list of terms

#let gls-entries = (
    (
      key: "svg", short: "SVG", long: "Scalable Vector Graphics", description: [A vector image format.],
    ),
    (
      key: "csv", short: "CSV", long: "Comma-separated Values ", description: [A human readable, plain text file format using commas to separate the values.],
    ),
    (
      key: "esp", short: "ESP", long: "ESP32/ESP8266", description: [ESP32 and ESP8266 are popular microcontrollers used in IoT and smart home projects.],
    ),
    (
      key: "ota", short: "OTA", long: "Over the Air Updates", description: [Over the Air Updates allow firmware to be updated wirelessly, without needing physical access to the device.],
    ),
    (
      key: "pcb", short: "PCB", long: "Printed Circuit Board", description: [A board that mechanically supports and electrically connects components using conductive tracks etched into flat material.],
    ),
    (
      key: "hal", short: "HAL", long: "Hardware Abstraction Layer", description: [The lowest layer of a layered firmware stack, giving direct access to microcontroller registers.],
    ),
    (
      key: "dl", short: "DL", long: "Driver Layer", description: [The middle layer of a layered firmware stack, controlling and initializing individual hardware components on top of the HAL.],
    ),
    (
      key: "al", short: "AL", long: "Application Layer", description: [The top layer of a layered firmware stack, containing application logic such as state machines and control algorithms.],
    ),
    (
      key: "gpio", short: "GPIO", long: "General-Purpose Input/Output", description: [A microcontroller pin whose function (digital input or output) can be configured in software.],
    ),
    (
      key: "pwm", short: "PWM", long: "Pulse-Width Modulation", description: [A technique for encoding an analog signal level as the duty cycle of a fixed-frequency digital pulse train, commonly used to control motor speed or servo position.],
    ),
    (
      key: "spi", short: "SPI", long: "Serial Peripheral Interface", description: [A synchronous serial bus using separate clock and data lines to connect a microcontroller to peripherals such as displays or sensors.],
    ),
    (
      key: "i2c", short: "I2C", long: "Inter-Integrated Circuit", description: [A synchronous serial bus using two shared lines (clock and data) that lets a microcontroller address multiple peripherals over the same wires.],
    ),
    (
      key: "usart", short: "USART", long: "Universal Synchronous/Asynchronous Receiver-Transmitter", description: [A serial communication peripheral that can operate either synchronously (with a shared clock) or asynchronously.],
    ),
    (
      key: "uart", short: "UART", long: "Universal Asynchronous Receiver-Transmitter", description: [A serial communication peripheral that sends and receives data without a shared clock signal.],
    ),
    (
      key: "pid", short: "PID", long: "Proportional-Integral-Derivative", description: [A feedback control algorithm that combines a term proportional to the current error, one proportional to its accumulated (integral) value, and one proportional to its rate of change (derivative) to compute a correction.],
    ),
    (
      key: "adc", short: "ADC", long: "Analog-to-Digital Converter", description: [A circuit that converts a continuous analog voltage into a discrete digital value.],
    ),
    (
      key: "imu", short: "IMU", long: "Inertial Measurement Unit", description: [A sensor module combining accelerometers, gyroscopes, and often a magnetometer to measure orientation and motion.],
    ),
    (
      key: "fpu", short: "FPU", long: "Floating-Point Unit", description: [A hardware unit that performs floating-point arithmetic directly in silicon instead of emulating it in software.],
    ),
    (
      key: "dmips", short: "DMIPS", long: "Dhrystone Million Instructions Per Second", description: [A CPU performance metric based on the Dhrystone benchmark, used to compare processor throughput.],
    ),
    (
      key: "trustzone", short: "TrustZone", long: "Arm TrustZone", description: [An Arm security extension that isolates trusted and untrusted code and data on the same processor core.],
    ),
    (
      key: "sram", short: "SRAM", long: "Static Random-Access Memory", description: [Volatile memory that retains data as long as power is applied, without needing periodic refresh.],
    ),
    (
      key: "lqfp", short: "LQFP", long: "Low-profile Quad Flat Package", description: [A thin surface-mount IC package with leads on all four sides.],
    ),
    (
      key: "cnc", short: "CNC", long: "Computer Numerical Control", description: [Computer-controlled machining, used here to cut the carbon fiber chassis and PCB parts to precise shapes.],
    ),
    (
      key: "esc", short: "ESC", long: "Electronic Speed Control", description: [A circuit that regulates a motor's speed by switching the current delivered to it, typically from a brushless motor driver.],
    ),
    (
      key: "rom", short: "ROM", long: "Read-Only Memory", description: [Non-volatile memory that is not intended to be rewritten during normal operation, here used to hold the microcontroller's factory bootloader.],
    ),
    (
      key: "tof", short: "ToF", long: "Time-of-Flight", description: [A distance-measurement principle that derives range from the time a signal, here an infrared laser pulse, takes to travel to a target and back.],
    ),
    (
      key: "spad", short: "SPAD", long: "Single Photon Avalanche Diode", description: [A photodetector sensitive enough to register individual returning photons, used to time the round trip of reflected laser light.],
    ),
    (
      key: "roi", short: "ROI", long: "Region of Interest", description: [A configurable subset of a sensor's receiving array used for a measurement, letting the effective field of view be narrowed without changing the physical sensor.],
    ),
    (
      key: "fov", short: "FoV", long: "Field of View", description: [The angular extent of the scene a sensor can observe.],
    ),
    (
      key: "lsb", short: "LSB", long: "Least Significant Bit", description: [The smallest increment a digital register can represent, used as the unit for how a raw sensor reading scales to a physical quantity.],
    ),
)

// Hints:
// * Usage within text will then be #gls("key") or plurals #glspl("key")
//   (a plain string matching the key field above, not a Typst label; the
//   glossarium package panics on a label argument)
