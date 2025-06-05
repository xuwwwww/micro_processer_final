`timescale 1ns/1ps

module testbench;

reg clk;
reg rst;

// DUT
mips_pipeline uut (
    .clk(clk),
    .rst(rst)
);

// Clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Test control
initial begin
    $dumpfile("mips_branch_bench.vcd");
    $dumpvars(1, uut);
    
    $display("Testbench: Starting simulation for MIPS Branch Prediction Benchmark.");
    
    rst = 1;
    #20 rst = 0;
    $display("Testbench: Reset released at time %0t ns.", $time);
    
    #10000; // run for 1000 cycles
    
    $display("---------------------------------------------------------------------");
    $display("Testbench: MIPS Branch Prediction Benchmark Completed.");
    $display("Testbench: Final PC value: 0x%h", uut.PC_IF_reg);
    $display("Testbench: Current simulation time: %0d ns.", $time / 1000);
    $display("Testbench: Approximate cycles: %0d.", ($time - 20000) / 10000);
    $display("---------------------------------------------------------------------");
    
    $finish;
end

endmodule 