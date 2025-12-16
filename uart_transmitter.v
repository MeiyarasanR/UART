`timescale 1ns / 1ps
// =============================================================================
// UART TRANSMITTER MODULE
// Sends 8-bit data serially: START(0) + 8 DATA BITS + STOP(1)
// =============================================================================
module uart_transmitter(
    input wire clk,           // System clock
    input wire rst,           // Reset signal
    input wire tx_start,      // Start transmission
    input wire tx_clk_en,     // Baud rate enable pulse
    input wire [7:0] tx_data, // Data to transmit
    output reg tx_line,       // Serial output line
    output wire tx_busy       // Transmission in progress flag
);

    // State definitions
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    reg [1:0] state = IDLE;           // Initialize state
    reg [2:0] bit_index = 3'd0;       // Initialize bit_index
    reg [7:0] tx_shift_reg = 8'd0;    // Initialize shift register
    
    // State machine
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_line <= 1'b1;  // Line idles high
            bit_index <= 3'd0;
            tx_shift_reg <= 8'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    tx_line <= 1'b1;  // Keep line high when idle
                    if (tx_start) begin
                        state <= START;
                        tx_shift_reg <= tx_data;  // Load data
                        bit_index <= 3'd0;
                    end
                end
                
                START: begin
                    if (tx_clk_en) begin
                        tx_line <= 1'b0;  // Send start bit (low)
                        state <= DATA;
                    end
                end
                
                DATA: begin
                    if (tx_clk_en) begin
                        tx_line <= tx_shift_reg[bit_index];  // Send current bit
                        if (bit_index == 3'd7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1'b1;
                    end
                end
                
                STOP: begin
                    if (tx_clk_en) begin
                        tx_line <= 1'b1;  // Send stop bit (high)
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                    tx_line <= 1'b1;
                end
            endcase
        end
    end
    
    // Busy flag: high when not in IDLE state
    assign tx_busy = (state != IDLE);
    
endmodule




