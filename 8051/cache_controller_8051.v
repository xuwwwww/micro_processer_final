module cache_controller_8051(
  input        clk,
  input        rst,
  input  [15:0] addr,
  input        rd,
  input        wr,
  output reg   hit,
  output reg [7:0] data_out
);
  reg [7:0] cache_mem [0:63];
  reg [7:0] tags      [0:63];
  integer idx;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      hit <= 1'b0;
      data_out <= 8'b0;
      for (idx=0; idx<64; idx=idx+1) begin
        cache_mem[idx] <= 8'b0;
        tags[idx]      <= 8'b0;
      end
    end else if (rd || wr) begin
      idx = addr[7:2]; // 6-bit index for 64 entries
      if (tags[idx] == addr[15:8]) begin
        hit <= 1'b1;
        data_out <= cache_mem[idx];
      end else begin
        hit <= 1'b0;
        // Simulate main memory read: use default data for 8051
        cache_mem[idx] <= 8'hAB;
        tags[idx]      <= addr[15:8];
        data_out       <= 8'hAB;
      end
      if (wr && hit)
        cache_mem[idx] <= data_out;
    end
  end
endmodule 