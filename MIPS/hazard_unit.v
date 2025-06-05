module hazard_unit(
  input  [4:0] ID_ex_rs,
  input  [4:0] ID_ex_rt,
  input  [4:0] EX_mem_rt,
  input        EX_mem_memread,
  output reg   stall
);
  always @(*) begin
    stall = (EX_mem_memread && 
            ((EX_mem_rt == ID_ex_rs) || (EX_mem_rt == ID_ex_rt)));
  end
endmodule