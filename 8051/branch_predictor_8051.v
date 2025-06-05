module branch_predictor_8051(
  input        clk,
  input  [15:0] pc,
  input        branch,
  input        actual,
  output reg   taken,
  output reg   update
);
  reg [1:0] BHT [0:255];
  wire [7:0] idx = pc[9:2];
  integer i;
  
  initial begin
    for (i=0; i<256; i=i+1)
      BHT[i] = 2'b01; // weakly not-taken
  end
  
  always @(posedge clk) begin
    if (branch) begin
      taken <= BHT[idx][1];
      update <= 1'b1;
      if (actual && BHT[idx] != 2'b11)
        BHT[idx] <= BHT[idx] + 1;
      else if (!actual && BHT[idx] != 2'b00)
        BHT[idx] <= BHT[idx] - 1;
    end else begin
      update <= 1'b0;
    end
  end
endmodule 