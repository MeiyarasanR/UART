`timescale 1ns / 1ps
// =============================================================================
// UART TOP MODULE
// Integrates transmitter, receiver, and baud rate generator
// =============================================================================
module uart_top(
    input wire clk,            // System clock
    input wire rst,            // Reset signal
    input wire tx_start,       // Start transmission
    input wire [7:0] tx_data,  // Data to transmit
    input wire rx_ready_clr,   // Clear RX ready flag
    output wire tx_busy,       // Transmission busy flag
    output wire rx_ready,      // Data received flag
    output wire [7:0] rx_data  // Received data
);

    // Internal signals
    wire tx_clk_en;
    wire rx_clk_en;
    wire tx_line;
    
    // Instantiate baud rate generator
    // Use faster baud rate for simulation (115200 instead of 9600)
    baud_rate_generator #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115200)  // 12x faster for simulation
    ) baud_gen (
        .clk(clk),
        .rst(rst),
        .tx_clk_en(tx_clk_en),
        .rx_clk_en(rx_clk_en)
    );
    
    // Instantiate transmitter
    uart_transmitter transmitter (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_clk_en(tx_clk_en),
        .tx_data(tx_data),
        .tx_line(tx_line),
        .tx_busy(tx_busy)
    );
    
    // Instantiate receiver (loopback: rx_line connected to tx_line)
    uart_receiver receiver (
        .clk(clk),
        .rst(rst),
        .rx_line(tx_line),
        .rx_clk_en(rx_clk_en),
        .rx_ready_clr(rx_ready_clr),
        .rx_ready(rx_ready),
        .rx_data(rx_data)
    );
    
endmodule



