`timescale 1ns/1ps

module testbench_8051;

reg clk;
reg rst;

// DUT
processor_8051 uut (
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
    $dumpfile("benchmark_8051.vcd");
    $dumpvars(1, uut);
    
    $display("Testbench: Starting 8051 Benchmark Simulation.");
    
    rst = 1;
    #20 rst = 0;
    $display("Testbench: Reset released at time %0t ns.", $time);
    
    #50000; // run for 5000 cycles
    
    $display("---------------------------------------------------------------------");
    $display("8051 Benchmark Results:");
    $display("Final PC: 0x%h", uut.PC);
    $display("Outer counter (R0): %d", uut.R0);
    $display("Inner counter (R1): %d", uut.R1);
    $display("Branch counter (R2): %d", uut.R2);
    $display("Simulation time: %0d ns", $time);
    $display("Cycles executed: %0d", ($time - 20) / 10);
    $display("---------------------------------------------------------------------");
    
    $finish;
end

endmodule 