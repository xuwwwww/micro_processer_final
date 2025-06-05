`timescale 1ns/1ps
module tb;
  reg clk = 0;
  reg rst = 1;

  pipeline_top uut (
    .clk(clk),
    .rst(rst)
  );

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);   // Add tb module as target
    #10 rst = 0;
    #500 $finish;
  end

  always #5 clk = ~clk;
endmodule