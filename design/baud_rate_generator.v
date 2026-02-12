`timescale 1ns / 1ps
// =============================================================================
// BAUD RATE GENERATOR
// Generates enable pulses for transmitter and receiver
// TX: 1 pulse per bit period (e.g., 9600 Hz for 9600 baud)
// RX: 16 pulses per bit period (16x oversampling for accurate detection)
// =============================================================================
module baud_rate_generator(
    input wire clk,           // System clock (e.g., 100 MHz)
    input wire rst,           // Reset signal
    output reg tx_clk_en,     // Transmit clock enable
    output reg rx_clk_en      // Receive clock enable (16x TX rate)
);

    parameter CLK_FREQ = 100_000_000;  // 100 MHz system clock
    parameter BAUD_RATE = 9600;        // Target baud rate
    
    // Calculate divisors
    localparam TX_DIVISOR = CLK_FREQ / BAUD_RATE;           // ~10417 for 9600 baud
    localparam RX_DIVISOR = CLK_FREQ / (BAUD_RATE * 16);    // ~651 for 16x oversampling
    
    reg [15:0] tx_counter = 16'd0;     // Initialize counter
    reg [15:0] rx_counter = 16'd0;     // Initialize counter
    
    // Transmitter clock enable generation
    always @(posedge clk) begin
        if (rst) begin
            tx_counter <= 16'd0;
            tx_clk_en <= 1'b0;
        end
        else if (tx_counter == TX_DIVISOR - 1) begin
            tx_counter <= 16'd0;
            tx_clk_en <= 1'b1;  // Pulse for one clock cycle
        end
        else begin
            tx_counter <= tx_counter + 1'b1;
            tx_clk_en <= 1'b0;
        end
    end
    
    // Receiver clock enable generation (16x faster)
    always @(posedge clk) begin
        if (rst) begin
            rx_counter <= 16'd0;
            rx_clk_en <= 1'b0;
        end
        else if (rx_counter == RX_DIVISOR - 1) begin
            rx_counter <= 16'd0;
            rx_clk_en <= 1'b1;  // Pulse for one clock cycle
        end
        else begin
            rx_counter <= rx_counter + 1'b1;
            rx_clk_en <= 1'b0;
        end
    end
    
endmodule
