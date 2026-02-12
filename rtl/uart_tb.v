`timescale 1ns / 1ps
// =============================================================================
// Testbench(verilog)
// =============================================================================
module uart_tb;
    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;
    reg rx_ready_clr;
    wire tx_busy;
    wire rx_ready;
    wire [7:0] rx_data;
    
    // Instantiate UART
    uart_top dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .rx_ready_clr(rx_ready_clr),
        .tx_busy(tx_busy),
        .rx_ready(rx_ready),
        .rx_data(rx_data)
    );
    
    // Clock: 10ns period = 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test sequence
    initial begin
        // Initialize
        rst = 1;
        tx_start = 0;
        tx_data = 0;
        rx_ready_clr = 0;
        
        // Reset
        #100;
        rst = 0;
        #100;
        
        // Test 1: Send 0x41
        $display("Test 1: Sending 0x41");
        tx_data = 8'h41;
        tx_start = 1;
        #20 tx_start = 0;
        
        wait(rx_ready);
        $display("Received: 0x%h (Expected: 0x41)", rx_data);
        rx_ready_clr = 1;
        #20 rx_ready_clr = 0;
        #100000;
        
        // Test 2: Send 0x55
        $display("Test 2: Sending 0x55");
        tx_data = 8'h55;
        tx_start = 1;
        #20 tx_start = 0;
        
        wait(rx_ready);
        $display("Received: 0x%h (Expected: 0x55)", rx_data);
        rx_ready_clr = 1;
        #20 rx_ready_clr = 0;
        #100000;
        
        // Test 3: Send 0xAA
        $display("Test 3: Sending 0xAA");
        tx_data = 8'hAA;
        tx_start = 1;
        #20 tx_start = 0;
        
        wait(rx_ready);
        $display("Received: 0x%h (Expected: 0xAA)", rx_data);
        rx_ready_clr = 1;
        #20 rx_ready_clr = 0;
        #100000;
        
        $display("All tests complete!");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #2000000;
        $display("ERROR: Timeout!");
        $finish;
    end
    
endmodule
