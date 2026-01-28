# 📡 UART Controller – RTL Design (Verilog HDL)

## 📌 Project Overview
This repository contains a **fully functional UART (Universal Asynchronous Receiver Transmitter)** implemented in **Verilog HDL**. The design includes a **baud rate generator, UART transmitter, UART receiver, top-level integration, and a self-checking testbench**.

The UART supports **8-bit asynchronous serial communication** using a standard frame format and is verified through **TX–RX loopback simulation**. The receiver uses **16× oversampling** to ensure accurate and reliable bit detection.

---

## 🎯 Design Objectives
- Implement UART communication at **RTL level** using Verilog HDL  
- Design a **baud rate generator** for transmitter and receiver  
- Implement **FSM-based UART TX and RX**  
- Use **16× oversampling** in the receiver for robust sampling  
- Verify functionality using a **directed testbench**  

---

## 📡 UART Configuration (As Implemented)
- **Communication Type:** Asynchronous Serial  
- **Data Bits:** 8  
- **Start Bit:** 1 (logic `0`)  
- **Stop Bit:** 1 (logic `1`)  
- **Parity:** Not implemented  
- **Bit Order:** LSB first  
- **Receiver Sampling:** 16× oversampling  
- **System Clock:** 100 MHz  
- **Baud Rate:** Parameterized  
  - `9600` (default in baud generator)  
  - `115200` used in `uart_top` for faster simulation  

---

## 🏗️ Architecture Overview
The UART design is composed of the following RTL blocks:

---

### 🔹 Baud Rate Generator (`baud_rate_generator.v`)
- Generates **clock enable pulses** for TX and RX  
- **TX clock enable (`tx_clk_en`)**:  
  - One pulse per baud period  
- **RX clock enable (`rx_clk_en`)**:  
  - 16 pulses per baud period (16× oversampling)  
- Uses counters derived from:
  - `CLK_FREQ / BAUD_RATE`
  - `CLK_FREQ / (BAUD_RATE × 16)`

**Parameters:**
- `CLK_FREQ = 100_000_000` (100 MHz)
- `BAUD_RATE` configurable

---

### 🔹 UART Transmitter (`uart_transmitter.v`)
- FSM-based design with four states:
  - `IDLE`  – TX line held high, waiting for `tx_start`
  - `START` – Transmits start bit (`0`)
  - `DATA`  – Transmits 8 data bits (LSB first)
  - `STOP`  – Transmits stop bit (`1`)
- Uses `tx_clk_en` for precise bit timing
- Loads transmit data into a shift register at start
- Provides `tx_busy` flag when transmission is active

---

### 🔹 UART Receiver (`uart_receiver.v`)
- Uses **16× oversampling** via `rx_clk_en`
- FSM states:
  - `IDLE`  – Waits for start bit (RX line goes low)
  - `START` – Aligns sampling to data bit center
  - `DATA`  – Samples each bit at mid-point (`sample_count == 8`)
  - `STOP`  – Waits for stop bit and completes reception
- Captures serial data into a shift register
- Asserts `rx_ready` when a full byte is received
- `rx_ready_clr` clears the ready flag after data is read

---

### 🔹 UART Top Module (`uart_top.v`)
- Integrates:
  - Baud rate generator
  - UART transmitter
  - UART receiver
- Implements **internal loopback**:
  - TX output connected directly to RX input
- Simplifies verification without external UART hardware

---

## 🧪 Simulation & Verification
- **Testbench:** `uart_tb.v`
- **Clock Frequency:** 100 MHz (10 ns period)
- **Verification Method:** Directed TX–RX loopback testing

### ✔️ Test Cases Executed
| Test | Transmitted Data | Received Data | Result |
|----|------------------|---------------|--------|
| 1  | `8'h41`          | `8'h41`       | PASS   |
| 2  | `8'h55`          | `8'h55`       | PASS   |
| 3  | `8'hAA`          | `8'hAA`       | PASS   |

- Testbench waits for `rx_ready`
- Clears ready flag using `rx_ready_clr`
- Includes a **timeout watchdog** to detect deadlocks

---

## 📁 RTL File Structure
