`timescale 1ns/1ps
module tb_8051;
  reg clk = 0;
  reg rst = 1;

  pipeline_8051 uut (
    .clk(clk),
    .rst(rst)
  );

  initial begin
    $dumpfile("waveform_8051.vcd");
    $dumpvars(0, tb_8051);
    #10 rst = 0;
    #1000 $finish;
  end

  always #5 clk = ~clk;
endmodule 