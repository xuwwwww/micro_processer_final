module cache_controller(
  input        clk,
  input        rst,
  input  [31:0] addr,
  input        rd,
  input        wr,
  output reg   hit,
  output reg [31:0] data_out
);
  reg [31:0] cache_mem [0:63];
  reg [22:0] tags      [0:63];
  integer idx;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      hit <= 1'b0;
      data_out <= 32'b0;
      for (idx=0; idx<64; idx=idx+1) begin
        cache_mem[idx] <= 32'b0;
        tags[idx]      <= 23'b0;
      end
    end else if (rd || wr) begin
      idx = addr[8:5];
      if (tags[idx] == addr[31:9]) begin
        hit <= 1'b1;
        data_out <= cache_mem[idx];
      end else begin
        hit <= 1'b0;
        // 模擬主記憶體讀取：此處可用 testbench 提供記憶體內容
        cache_mem[idx] <= 32'hDEADBEEF;
        tags[idx]      <= addr[31:9];
        data_out       <= 32'hDEADBEEF;
      end
      if (wr && hit)
        cache_mem[idx] <= data_out;
    end
  end
endmodule