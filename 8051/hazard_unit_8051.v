module hazard_unit_8051(
  input        ID_ex_uses_acc,
  input        EX_mem_acc_write,
  input        EX_mem_mem_read,
  output reg   stall
);
  always @(*) begin
    // Stall only for load-use hazard (when previous instruction is a load)
    stall = (ID_ex_uses_acc && EX_mem_acc_write && EX_mem_mem_read);
  end
endmodule 