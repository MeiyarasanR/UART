`timescale 1ns / 1ps
// =============================================================================
// UART RECEIVER MODULE
// Receives 8-bit data serially: START(0) + 8 DATA BITS + STOP(1)
// Uses 16x oversampling for accurate bit detection
// =============================================================================
module uart_receiver(
    input wire clk,            // System clock
    input wire rst,            // Reset signal
    input wire rx_line,        // Serial input line
    input wire rx_clk_en,      // Baud rate enable (16x)
    input wire rx_ready_clr,   // Clear ready flag
    output reg rx_ready,       // Data received flag
    output reg [7:0] rx_data   // Received data
);
    // State definitions
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    
    reg [1:0] state = IDLE;            // Initialize state
    reg [3:0] sample_count = 4'd0;     // Initialize sample counter
    reg [2:0] bit_index = 3'd0;        // Initialize bit index
    reg [7:0] rx_shift_reg = 8'd0;     // Initialize shift register
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            rx_ready <= 1'b0;
            rx_data <= 8'd0;
            sample_count <= 4'd0;
            bit_index <= 3'd0;
            rx_shift_reg <= 8'd0;
        end
        else begin
            // Clear ready flag when requested
            if (rx_ready_clr)
                rx_ready <= 1'b0;
                
            if (rx_clk_en) begin
                case (state)
                    IDLE: begin
                        sample_count <= 4'd0;
                        bit_index <= 3'd0;
                        // Wait for start bit (line goes low)
                        if (rx_line == 1'b0) begin
                            state <= START;
                        end
                    end
                    
                    START: begin
                        // Count 16 samples to reach middle of first data bit
                        if (sample_count == 4'd15) begin
                            state <= DATA;
                            sample_count <= 4'd0;
                        end
                        else begin
                            sample_count <= sample_count + 1'b1;
                        end
                    end
                    
                    DATA: begin
                        sample_count <= sample_count + 1'b1;
                        
                        // Sample in the middle of the bit period
                        if (sample_count == 4'd8) begin
                            rx_shift_reg[bit_index] <= rx_line;
                        end
                        
                        // Move to next bit or STOP state after full bit period
                        if (sample_count == 4'd15) begin
                            if (bit_index == 3'd7) begin
                                // Just finished bit 7, move to STOP
                                state <= STOP;
                                sample_count <= 4'd0;
                            end else begin
                                // Move to next bit
                                bit_index <= bit_index + 1'b1;
                                sample_count <= 4'd0;
                            end
                        end
                    end
                    
                    STOP: begin
                        // Wait for stop bit period
                        if (sample_count == 4'd15) begin
                            state <= IDLE;
                            rx_data <= rx_shift_reg;  // Output received data
                            rx_ready <= 1'b1;         // Signal data is ready
                            sample_count <= 4'd0;
                        end
                        else begin
                            sample_count <= sample_count + 1'b1;
                        end
                    end
                    
                    default: begin
                        state <= IDLE;
                        sample_count <= 4'd0;
                        bit_index <= 3'd0;
                    end
                endcase
            end
        end
    end
endmodule

