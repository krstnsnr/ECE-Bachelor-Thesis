// * Add list of terms

#let gls-entries = (
    (
      key: "svg", short: "SVG", long: "Scalable Vector Graphics", description: [Vector image format.],
    ),
    (
      key: "csv", short: "CSV", long: "Comma-separated Values", description: [Plain-text data separated by commas.],
    ),
    (
      key: "esp", short: "ESP", long: "ESP32/ESP8266", description: [IoT microcontroller family.],
    ),
    (
      key: "ota", short: "OTA", long: "Over the Air", description: [Wireless firmware update.],
    ),
    (
      key: "pcb", short: "PCB", long: "Printed Circuit Board", description: [Board wiring components via etched tracks.],
    ),
    (
      key: "hal", short: "HAL", long: "Hardware Abstraction Layer", description: [Lowest firmware layer, direct register access.],
    ),
    (
      key: "dl", short: "DL", long: "Driver Layer", description: [Middle firmware layer above the HAL.],
    ),
    (
      key: "al", short: "AL", long: "Application Layer", description: [Top firmware layer, application logic.],
    ),
    (
      key: "gpio", short: "GPIO", long: "General-Purpose Input/Output", description: [Software-configurable digital I/O pin.],
    ),
    (
      key: "pwm", short: "PWM", long: "Pulse-Width Modulation", description: [Level encoded as a pulse duty cycle.],
    ),
    (
      key: "spi", short: "SPI", long: "Serial Peripheral Interface", description: [Synchronous serial bus, separate clock and data.],
    ),
    (
      key: "i2c", short: "I2C", long: "Inter-Integrated Circuit", description: [Two-wire multi-device serial bus.],
    ),
    (
      key: "usart", short: "USART", long: "Universal Synchronous/Asynchronous Receiver-Transmitter", description: [Synchronous or asynchronous serial peripheral.],
    ),
    (
      key: "uart", short: "UART", long: "Universal Asynchronous Receiver-Transmitter", description: [Serial peripheral without a shared clock.],
    ),
    (
      key: "pid", short: "PID", long: "Proportional-Integral-Derivative", description: [Error, integral, and derivative feedback control.],
    ),
    (
      key: "adc", short: "ADC", long: "Analog-to-Digital Converter", description: [Analog voltage to digital value.],
    ),
    (
      key: "imu", short: "IMU", long: "Inertial Measurement Unit", description: [Sensor for orientation and motion.],
    ),
    (
      key: "fpu", short: "FPU", long: "Floating-Point Unit", description: [Hardware for floating-point arithmetic.],
    ),
    (
      key: "dmips", short: "DMIPS", long: "Dhrystone Million Instructions Per Second", description: [Dhrystone-based CPU throughput metric.],
    ),
    (
      key: "trustzone", short: "TrustZone", long: "Arm TrustZone", description: [Arm trusted/untrusted code isolation.],
    ),
    (
      key: "sram", short: "SRAM", long: "Static Random-Access Memory", description: [Volatile memory needing no refresh.],
    ),
    (
      key: "lqfp", short: "LQFP", long: "Low-profile Quad Flat Package", description: [Thin package, leads on four sides.],
    ),
    (
      key: "cnc", short: "CNC", long: "Computer Numerical Control", description: [Computer-controlled machining.],
    ),
    (
      key: "esc", short: "ESC", long: "Electronic Speed Control", description: [Circuit regulating motor speed.],
    ),
    (
      key: "rom", short: "ROM", long: "Read-Only Memory", description: [Non-volatile memory, here the bootloader.],
    ),
    (
      key: "tof", short: "ToF", long: "Time-of-Flight", description: [Range from signal round-trip time.],
    ),
    (
      key: "spad", short: "SPAD", long: "Single Photon Avalanche Diode", description: [Detects individual returning photons.],
    ),
    (
      key: "roi", short: "ROI", long: "Region of Interest", description: [Configurable subset of a sensor's array.],
    ),
    (
      key: "fov", short: "FoV", long: "Field of View", description: [Angular extent a sensor can observe.],
    ),
    (
      key: "lsb", short: "LSB", long: "Least Significant Bit", description: [Smallest increment a register represents.],
    ),
    (
      key: "msb", short: "MSB", long: "Most Significant Bit", description: [Highest-weight bit of a value.],
    ),
    (
      key: "sar", short: "SAR", long: "Successive Approximation Register", description: [ADC resolving one bit per step.],
    ),
    (
      key: "mosfet", short: "MOSFET", long: "Metal-Oxide-Semiconductor Field-Effect Transistor", description: [Voltage-controlled transistor switch.],
    ),
    (
      key: "dma", short: "DMA", long: "Direct Memory Access", description: [Moves data without CPU copying.],
    ),
)

// Hints:
// * Usage within text will then be #gls("key") or plurals #glspl("key")
//   (a plain string matching the key field above, not a Typst label; the
//   glossarium package panics on a label argument)
