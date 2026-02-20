# 📡 UART Controller – RTL Design & Verification (Verilog HDL + SystemVerilog)

## 📌 Overview
This repository contains a **fully functional UART (Universal Asynchronous Receiver Transmitter)** implemented in **Verilog HDL**. The design includes a **baud rate generator, UART transmitter, UART receiver, top-level integration, a directed Verilog testbench, and a structured SystemVerilog OOP-based testbench**.

The UART supports **8-bit asynchronous serial communication** using a standard frame format and is verified through **TX–RX loopback simulation**. The receiver uses **16× oversampling** to ensure accurate and reliable bit detection.

---

## 🎯 Design Objectives
- Implement UART communication at **RTL level** using Verilog HDL  
- Design a **baud rate generator** for transmitter and receiver  
- Implement **FSM-based UART TX and RX**  
- Use **16× oversampling** in the receiver for robust sampling  
- Verify functionality using a **directed Verilog testbench**  
- Verify functionality using a **structured SystemVerilog OOP testbench**

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

## 📂 File Structure

```
uart_project/
├── rtl/                          # RTL Design Sources
│   ├── baud_rate_generator.v     # Baud rate clock enable generator
│   ├── uart_receiver.v           # UART Receiver (16× oversampling FSM)
│   ├── uart_top.v                # Top-level integration (TX–RX loopback)
│   └── uart_transmitter.v        # UART Transmitter (FSM-based)
│
├── tb_systemverilog_oop/         # SystemVerilog OOP Testbench
│   └── uart_sv_tb.sv             # Generator, Driver, Monitor, Scoreboard, Env, TB Top
│
├── tb_verilog_basic/             # Basic Verilog Testbench (directed)
│   └── uart_tb.v                 # Simple directed testbench
│
└── README.md                     # Project documentation
```

---

## 🏗️ Architecture Overview
The UART design is composed of the following RTL blocks:
<img width="1083" height="696" alt="image" src="https://github.com/user-attachments/assets/ba3ee4fc-74fa-4a5d-8fe1-7a4d906916b9" />

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

### ✅ Testbench 1 – Basic Verilog (`tb_verilog_basic/uart_tb.v`)
- **Clock Frequency:** 100 MHz (10 ns period)
- **Verification Method:** Directed TX–RX loopback testing

#### ✔️ Test Cases Executed
| Test | Transmitted Data | Received Data | Result |
|----|------------------|---------------|--------|
| 1  | `8'h41`          | `8'h41`       | PASS   |
| 2  | `8'h55`          | `8'h55`       | PASS   |
| 3  | `8'hAA`          | `8'hAA`       | PASS   |

- Testbench waits for `rx_ready`
- Clears ready flag using `rx_ready_clr`
- Includes a **timeout watchdog** to detect deadlocks

---

### ✅ Testbench 2 – SystemVerilog OOP (`tb_systemverilog_oop/uart_sv_tb.sv`)
- **Verification Method:** Randomized TX–RX loopback with self-checking scoreboard
- **Transactions:** 20 randomized 8-bit data values
- **Clock Frequency:** 100 MHz

--

### 🔹 Configurable Transaction Count

The SystemVerilog testbench allows easy control of the number of randomized transactions from the top level:

```systemverilog
initial begin
  env = new(vif);
  env.gen.count = 20;   // Set number of transactions
  env.run();
end
```

By modifying `env.gen.count`, the test can be quickly scaled for:
- Quick functional testing
- Extended randomized stress testing

This ensures a **flexible and reusable** verification environment.

---
#### 🔧 Component Descriptions

| Component | Description |
|---|---|
| `uart_if` | Interface bundling all DUT signals (clk, rst, tx_start, tx_data, rx_ready_clr, tx_busy, rx_ready, rx_data) |
| `uart_transaction` | Data object holding randomized `din` and received `dout`; includes `copy()` function |
| `uart_generator` | Generates `count` randomized transactions; waits on `sconext` event for pacing; triggers `done` on completion |
| `uart_driver` | Performs reset; drives `tx_data` and `tx_start`; waits for `rx_ready`; clears flag via `rx_ready_clr` |
| `uart_monitor` | Detects `rx_ready` assertion; captures `rx_data`; forwards to scoreboard |
| `uart_scoreboard` | Compares driven vs. received data; prints PASS/FAIL per transaction; generates final report |
| `uart_env` | Instantiates and connects all components; runs them in parallel via `fork...join_none` |

#### ✔️ Simulation Results

<img width="851" height="692" alt="image" src="https://github.com/user-attachments/assets/fcd30221-d8ee-47a3-b98a-c1946cda2a35" />
---

## 🚀 Future Enhancement – UVM 1.2 Testbench

The next planned upgrade is to migrate the SystemVerilog OOP testbench to a full **UVM 1.2 (Universal Verification Methodology)** environment.

| Current (SV OOP) | Planned (UVM 1.2) |
|---|---|
| Manual `class` components | `uvm_component` based classes |
| Mailbox communication | TLM ports & FIFOs |
| Custom `uart_transaction` | `uvm_sequence_item` |
| Manual generator loop | `uvm_sequence` + `uvm_sequencer` |
| Custom driver task | `uvm_driver` |
| Custom monitor task | `uvm_monitor` |
| Custom scoreboard | `uvm_scoreboard` + `uvm_analysis_port` |
| Manual `uart_env` | `uvm_env` |
| `initial` block test | `uvm_test` |
| Manual report | `uvm_report_server` |

**Planned UVM features:**
- Constrained-random sequences with coverage-driven verification
- Functional coverage using `covergroup` and `coverpoint`
- Factory overrides for reusable, scalable testbench
- Register model (UVM RAL) if control registers are added

---

## 📘 Learning Outcomes
- Strong understanding of **UART protocol**
- FSM-based RTL design in Verilog HDL
- Baud-rate timing and oversampling concepts
- Serial-to-parallel and parallel-to-serial conversion
- OOP-based testbench design in SystemVerilog
- Layered verification: Generator → Driver → Monitor → Scoreboard
- End-to-end **RTL simulation and verification**

---

## 👤 Author  
**Meiyarasan R**  
B.E. Electronics and Communication Engineering  
Interest: Digital VLSI | Verification | RISC-V | Embedded Systems

---

⭐ If you find this project useful, feel free to star the repository!
