# Simple UART in Verilog

This repository contains a simple UART (Universal Asynchronous Receiver/Transmitter) implementation in Verilog, including a transmitter, receiver, baud rate generator, top-level integration, and a self-checking loopback testbench.

## Features

- 8‑bit data frame: 1 start bit, 8 data bits, 1 stop bit (8N1).
- Separate transmitter and receiver modules.
- 16× oversampling in the receiver for robust bit detection.
- Parameterizable baud rate generator (e.g., 115200 baud at 100 MHz clock).
- Loopback top module (`uart_top`) that connects TX to RX for easy testing.
- Simple testbench (`uart_tb`) that automatically sends and verifies multiple bytes. 

## Project Structure

- `uart_transmitter.v`  
  UART transmitter: sends 8‑bit data frames as `START + 8 DATA + STOP` on `tx_line`.

- `uart_receiver.v`  
  UART receiver: samples the incoming `rx_line` using 16× oversampling, reconstructs the 8‑bit word, and asserts `rx_ready` when a byte is available.
  
- `baud_rate_generator.v`  
  Baud rate generator: generates enable pulses `tx_clk_en` and `rx_clk_en` from the system clock for transmitter and receiver timing. 

- `uart_top.v`  
  Top-level UART integration: instantiates the baud rate generator, transmitter, and receiver, and connects `tx_line` to the receiver’s `rx_line` for loopback testing.

- `uart_tb.v`  
  Testbench for simulation: creates a 100 MHz clock, applies reset, sends a sequence of bytes, and prints received values to the console. 

## Module Overview

### `uart_transmitter`

- Inputs: `clk`, `rst`, `tx_start`, `tx_clk_en`, `tx_data[7:0]`
- Outputs: `tx_line`, `tx_busy`
- State machine with states: `IDLE`, `START`, `DATA`, `STOP`.
- `tx_busy` is high whenever the transmitter is not in the `IDLE` state. 

### `uart_receiver`

- Inputs: `clk`, `rst`, `rx_line`, `rx_clk_en`, `rx_ready_clr`
- Outputs: `rx_ready`, `rx_data[7:0]`
- State machine with states: `IDLE`, `START`, `DATA`, `STOP`.
- Uses a 4‑bit `sample_count` to count 16 oversampled ticks per bit period.
- Samples in the middle of the bit period (`sample_count == 8`) and shifts bits into `rx_shift_reg`. 

### `uart_top`

- Connects:
  - `tx_line` from `uart_transmitter` to `rx_line` of `uart_receiver` (loopback).
  - `tx_clk_en` and `rx_clk_en` from the baud rate generator.
- Provides a simple UART interface:
  - Inputs: `clk`, `rst`, `tx_start`, `tx_data[7:0]`, `rx_ready_clr`
  - Outputs: `tx_busy`, `rx_ready`, `rx_data[7:0]`

### `uart_tb`

- Generates a 100 MHz clock (`10 ns` period).
- Applies reset, then runs three tests in loopback:
  - Sends `0x41`, `0x55`, and `0xAA`.
  - Waits for `rx_ready`, prints received data, and clears `rx_ready` using `rx_ready_clr`.
- Includes a timeout watchdog to avoid infinite simulation if something goes wrong. 

## Simulation

1. Add all Verilog source files and `uart_tb.v` to your simulator project. 
2. Set `uart_tb` as the top-level simulation module. 
3. Run the simulation.  
   You should see console messages similar to:
   - `Test 1: Sending 0x41`
   - `Received: 0x41 (Expected: 0x41)`
   - `Test 2: Sending 0x55`
   - `Received: 0x55 (Expected: 0x55)`
   - `Test 3: Sending 0xAA`
   - `Received: 0xAA (Expected: 0xAA)`
   - `All tests complete!` 

If you see the `ERROR: Timeout!` message, it indicates that the receiver did not assert `rx_ready` in time, and you may need to check clock, baud rate, or connections.

## Parameters and Configuration

- System clock: 100 MHz (10 ns period).
- Default baud rate (in `baud_rate_generator`): 115200 for faster simulation.  
  For a different baud rate, adjust the `BAUD_RATE` parameter and rebuild the project. 

## Usage Notes

- The design assumes an 8‑bit data word with no parity and one stop bit (8N1). 
- For integration on hardware, connect `tx_line` and `rx_line` to appropriate FPGA pins and replace the internal loopback with external UART lines. 

<img width="1000" height="269" alt="image" src="https://github.com/user-attachments/assets/2d3a11f3-bfc3-4424-ad18-08f8f1a49e77" />
