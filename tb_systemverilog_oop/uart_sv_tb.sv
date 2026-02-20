`timescale 1ns/1ps

interface uart_if;
  logic clk;
  logic rst;
  logic tx_start;
  logic [7:0] tx_data;
  logic rx_ready_clr;
  logic tx_busy;
  logic rx_ready;
  logic [7:0] rx_data;
endinterface

//--------------------Transaction-----------------
class uart_transaction;
  rand bit [7:0] din;
  bit [7:0] dout;

  function uart_transaction copy();
    copy = new();
    copy.din  = this.din;
    copy.dout = this.dout;
  endfunction
endclass


// ---------------- Generator ----------------
class uart_generator;

  mailbox #(uart_transaction) mbx;
  event done;
  event sconext;
  int count;

  function new(mailbox #(uart_transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    uart_transaction tr;
    repeat(count) begin
      tr = new();
      if(!tr.randomize())
        $error("Randomization failed");

      mbx.put(tr.copy());
      $display("[GEN] Data Sent => Dec: %0d | Hex: 0x%02h", tr.din, tr.din);

      @(sconext);
    end
    -> done;
  endtask
endclass


// ---------------- Driver ----------------
class uart_driver;

  virtual uart_if vif;
  mailbox #(uart_transaction) mbx;
  mailbox #(bit [7:0]) mbxds;

  function new(mailbox #(bit[7:0]) mbxds,
               mailbox #(uart_transaction) mbx);
    this.mbx   = mbx;
    this.mbxds = mbxds;
  endfunction

  task reset();
    vif.rst <= 1;
    vif.tx_start <= 0;
    vif.tx_data <= 0;
    vif.rx_ready_clr <= 0;

    repeat(10) @(posedge vif.clk);
    vif.rst <= 0;
    repeat(5) @(posedge vif.clk);

    $display("[DRV] Reset completed");
    $display("------------------------------");
  endtask

  task run();
    uart_transaction tr;

    forever begin
      mbx.get(tr);

      while(vif.tx_busy)
        @(posedge vif.clk);

      vif.tx_data  <= tr.din;
      vif.tx_start <= 1;
      @(posedge vif.clk);
      vif.tx_start <= 0;

      mbxds.put(tr.din);

      wait(vif.rx_ready == 1);

      vif.rx_ready_clr <= 1;
      @(posedge vif.clk);
      vif.rx_ready_clr <= 0;
    end
  endtask
endclass


// ---------------- Monitor ----------------
class uart_monitor;

  virtual uart_if vif;
  mailbox #(bit [7:0]) mbx;

  function new(mailbox #(bit[7:0]) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      @(posedge vif.rx_ready);
      $display("[MON] Data Received => Dec:%0d | Hex:0x%02h",vif.rx_data, vif.rx_data);
      mbx.put(vif.rx_data);
      @(negedge vif.rx_ready);
    end
  endtask
endclass


// ---------------- Scoreboard ----------------
class uart_scoreboard;

  mailbox #(bit [7:0]) mbxds;
  mailbox #(bit [7:0]) mbxms;
  bit [7:0] ds;
  bit [7:0] ms;

  event sconext;

  int pass = 0;
  int fail = 0;

  function new(mailbox #(bit[7:0]) mbxds,
               mailbox #(bit[7:0]) mbxms);
    this.mbxds = mbxds;
    this.mbxms = mbxms;
  endfunction
  
  task run();
     forever begin
     mbxds.get(ds);
     mbxms.get(ms);
       $display("[SCO] : DRV :%0d (0x%02H) | MON :%0d (0x%02H)", ds, ds, ms, ms);

      if (ds == ms) begin
        $display("[SCO] : DATA MATCHED");
        pass++;
      end else begin
        $display("[SCO] : DATA MISMATCHED");
        fail++;
      end

      $display("-----------------------------------------");
      -> sconext;            
    end
  endtask

  function void report();
    $display("[REPORT] : SCOREBOARD FINAL REPORT         ");
    $display("  PASS  : %0d", pass);
    $display("  FAIL  : %0d", fail);
    $display("  TOTAL : %0d", pass + fail);
    $display("-----------------------------------------");
    if (fail == 0)
      $display("  STATUS :ALL TESTS PASSED");
    else
      $display("  STATUS :%0d FAILURE(S) DETECTED", fail);
    $display("TOTAL TRANSACTIONS = %0d", pass+fail);
    $display("--------------------------------------------");
  endfunction
endclass


// ---------------- Environment ----------------
class uart_env;

  uart_generator gen;
  uart_driver    drv;
  uart_monitor   mon;
  uart_scoreboard sco;

  mailbox #(uart_transaction) mbxgd;
  mailbox #(bit [7:0]) mbxds;
  mailbox #(bit [7:0]) mbxms;

  virtual uart_if vif;

  function new(virtual uart_if vif);
    this.vif = vif;

    mbxgd = new();
    mbxds = new();
    mbxms = new();

    gen = new(mbxgd);
    drv = new(mbxds, mbxgd);
    mon = new(mbxms);
    sco = new(mbxds, mbxms);

    drv.vif = vif;
    mon.vif = vif;

    gen.sconext = sco.sconext;
  endfunction

  task run();
    drv.reset();

    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_none

    wait(gen.done.triggered);
    #500000;
    sco.report();
    $finish;
  endtask
endclass


// ---------------- Top Testbench ----------------
module uart_tb;

  uart_if vif();

  uart_top dut (
    .clk          (vif.clk),
    .rst          (vif.rst),
    .tx_start     (vif.tx_start),
    .tx_data      (vif.tx_data),
    .rx_ready_clr (vif.rx_ready_clr),
    .tx_busy      (vif.tx_busy),
    .rx_ready     (vif.rx_ready),
    .rx_data      (vif.rx_data)
  );

  initial vif.clk = 0;
  always #5 vif.clk = ~vif.clk;

  uart_env env;

  initial begin
    env = new(vif);
    env.gen.count = 20;
    env.run();
  end

  initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(1, uart_tb);   // reduced dump depth
  end

endmodule



