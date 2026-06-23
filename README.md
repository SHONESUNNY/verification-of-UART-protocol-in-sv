#  UART Transceiver & OOP SystemVerilog Testbench

A complete, synthesizable UART (Universal Asynchronous Receiver-Transmitter) hardware module paired with a robust, Object-Oriented SystemVerilog verification environment. 

This project demonstrates both hardware RTL design (FSMs, Shift Registers, Clock Dividers) and modern hardware verification techniques using custom OOP classes, Mailboxes, and Events.

##  Overview
This repository contains two main domains:
1. **The Hardware (RTL):** A synthesizable UART Transmitter (`uart_tx`) and Receiver (`uart_rx`) written in SystemVerilog. It converts parallel data into serial bits and perfectly reconstructs them on the other side using mid-bit sampling.
2. **The Verification Environment:** A custom, UVM-style testbench that generates randomized data, drives it into the hardware, monitors the physical serial wire, and automatically grades the results using a Scoreboard.

**Specifications:**
* **Baud Rate:** 9600 bps (Configurable)
* **System Clock:** 100 MHz (Configurable)
* **Data Width:** 8 bits
* **Parity:** None
* **Stop Bits:** 1

---

##  Architecture

### 1. Hardware RTL (Design Under Test)
* **`uart_tx` (Transmitter):** Acts as a parallel-to-serial converter. When `tx_start` is asserted, it loads an 8-bit payload into a 10-bit shift register (appending Start and Stop bits) and shifts them onto the `tx` wire at precisely the calculated baud rate.
* **`uart_rx` (Receiver):** Acts as a serial-to-parallel converter. It utilizes an internal oversampling counter to detect the falling edge of the Start Bit. It then shifts its internal metronome by half a bit period `(CLKS_PER_BIT / 2)` to guarantee that all subsequent data bits are sampled in the exact, stable center of the waveform. It utilizes a **Double Buffering** architecture to prevent outputting corrupted data while the byte is being built.

### 2. The Verification Environment
The testbench is built using dynamic SystemVerilog classes, entirely divorcing the software test sequence from the physical hardware timing.

* **`transaction`:** The data object holding the randomized 8-bit payload.
* **`uart_generator`:** Randomizes transactions and places them into Mailboxes. Uses an `event` flag to signal when all packets are generated.
* **`uart_driver`:** Fetches transactions from the Mailbox and manages the physical handshake with the DUT, including waiting for the `tx_busy` flag to clear before sending the next byte.
* **`uart_monitor`:** An independent, passive software FSM that stares directly at the serial `tx` wire. It decodes the Start/Stop bits and reconstructs the byte strictly by tracking baud rate timing, repackaging it into a transaction object.
* **`uart_scoreboard`:** The automated grader. It pulls the expected data from the Generator and the reconstructed data from the Monitor, comparing them and throwing errors if the hardware corrupted the signal.

---

## 🛠️Key Engineering Problems Solved

* **Race Conditions:** Resolved driver-to-hardware race conditions by enforcing a 1-clock-cycle delay after dropping `tx_start`. This allows the slow physical silicon time to assert the `tx_busy` flag before the software loops back to check it.
* **Asynchronous Sampling:** Implemented center-sampling in the Receiver FSM to avoid reading unstable voltage transitions on the physical wire edges. 
* **Zero-Time Simulation Hangs:** Utilized `fork...join_none` and SystemVerilog `events` (`-> ended`) to allow the 0-nanosecond Generator to finish its loop without prematurely terminating the simulation before the physical hardware had time to toggle its pins.

---

##  File Structure

```text
├── rtl/
│   ├── uart_tx.sv        # Hardware Transmitter FSM & Shift Register
│   └── uart_rx.sv        # Hardware Receiver FSM & Oversampler
├── tb/
│   ├── uart_if.sv        # Physical wire interface
│   ├── gen_driv.sv       # Classes: Transaction, Generator, Driver
│   ├── mon_scb.sv        # Classes: Monitor, Scoreboard
│   ├── uart_env.sv       # Environment wrapper & Mailbox routing
│   └── uart_tb.sv        # Top-level module: Clock gen and Loopback wiring
└── README.md
