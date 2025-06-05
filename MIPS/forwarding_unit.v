module forwarding_unit(
  input  [4:0] EX_mem_rd,
  input  [4:0] MEM_wb_rd,
  input        EX_mem_regwrite,
  input        MEM_wb_regwrite,
  input  [4:0] ID_ex_rs,
  input  [4:0] ID_ex_rt,
  output reg [1:0] forwardA,
  output reg [1:0] forwardB
);
  always @(*) begin
    forwardA = 2'b00;
    forwardB = 2'b00;
    if (EX_mem_regwrite && EX_mem_rd != 5'b00000 && EX_mem_rd == ID_ex_rs)
      forwardA = 2'b10;
    else if (MEM_wb_regwrite && MEM_wb_rd != 5'b00000 && MEM_wb_rd == ID_ex_rs)
      forwardA = 2'b01;
    if (EX_mem_regwrite && EX_mem_rd != 5'b00000 && EX_mem_rd == ID_ex_rt)
      forwardB = 2'b10;
    else if (MEM_wb_regwrite && MEM_wb_rd != 5'b00000 && MEM_wb_rd == ID_ex_rt)
      forwardB = 2'b01;
  end
endmodule