module forwarding_unit_8051(
  input        EX_mem_acc_write,
  input        MEM_wb_acc_write,
  input        ID_ex_uses_acc,
  output reg [1:0] forwardA
);
  always @(*) begin
    forwardA = 2'b00;  // No forwarding by default
    
    // Forward from EX/MEM stage (most recent)
    if (EX_mem_acc_write && ID_ex_uses_acc)
      forwardA = 2'b10;
    // Forward from MEM/WB stage
    else if (MEM_wb_acc_write && ID_ex_uses_acc)
      forwardA = 2'b01;
  end
endmodule 