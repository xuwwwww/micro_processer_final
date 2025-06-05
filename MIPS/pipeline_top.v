`timescale 1ns/1ps
module pipeline_top(
  input        clk,
  input        rst
);
  // Instruction memory and program counter
  reg [31:0] PC;
  reg [31:0] instr_mem [0:255];
  integer i;

  // Register file
  reg [31:0] regfile [0:31];
  wire [4:0] rs = IF_ID_instr[25:21];
  wire [4:0] rt = IF_ID_instr[20:16];
  wire [4:0] rd = IF_ID_instr[15:11];
  wire [15:0] imm = IF_ID_instr[15:0];
  wire [31:0] sign_ext_imm = {{16{imm[15]}}, imm};

  // Pipeline registers
  reg [31:0] IF_ID_instr, IF_ID_pc;
  reg [31:0] ID_EX_pc, ID_EX_reg1, ID_EX_reg2, ID_EX_imm;
  reg [4:0]  ID_EX_rs, ID_EX_rt, ID_EX_rd;
  reg [5:0]  ID_EX_funct;
  reg [5:0]  ID_EX_opcode;
  
  // EX/MEM pipeline registers
  reg [31:0] EX_MEM_alu_result;
  reg [31:0] EX_MEM_reg2_value;
  reg [4:0]  EX_MEM_rd_reg;
  reg        EX_MEM_reg_write;
  reg        EX_MEM_mem_read;
  reg        EX_MEM_mem_write;

  // MEM/WB pipeline registers
  reg [31:0] MEM_WB_alu_result;
  reg [31:0] MEM_WB_read_data;
  reg [4:0]  MEM_WB_rd_reg;
  reg        MEM_WB_reg_write;
  reg        MEM_WB_mem_read_active; // For WB stage to know if it was a memory read

  // Control signals
  wire [1:0] forwardA, forwardB;
  wire       stall;
  wire       cache_hit;          // Cache hit signal
  wire [31:0] cache_data_out;    // Data from cache

  // Wires for connecting pipeline register outputs to unit inputs
  wire [4:0] EX_MEM_rd;
  wire [4:0] MEM_WB_rd;
  wire       EX_MEM_regwrite;
  wire       MEM_WB_regwrite;
  wire       EX_MEM_memread;
  wire       EX_MEM_memwrite;

  // Initialize instruction memory and register file
  initial begin
    // Initialize instruction memory
    instr_mem[0] = 32'h20080005;           // addi $t0, $zero, 5
    instr_mem[1] = 32'h20090003;           // addi $t1, $zero, 3
    instr_mem[2] = 32'h01094020;           // add $t0, $t0, $t1    (data hazard with previous addi)
    instr_mem[3] = 32'h11090002;           // beq $t0, $t1, 2      (branch hazard)
    instr_mem[4] = 32'h200A0001;           // addi $t2, $zero, 1   (branch target)
    instr_mem[5] = 32'h200B0002;           // addi $t3, $zero, 2   (branch target)
    instr_mem[6] = 32'h014B4020;           // add $t0, $t2, $t3    (data hazard with previous addi)
    for (i = 7; i < 256; i = i + 1)
      instr_mem[i] = 32'h00000000;
    
    // Initialize register file
    for (i = 0; i < 32; i = i + 1)
      regfile[i] = 32'h00000000;
  end

  // IF Stage: update PC and fetch instruction
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      PC           <= 0;
      IF_ID_pc     <= 0;
      IF_ID_instr  <= 32'h00000000;
    end else if (!stall) begin
      PC           <= PC + 4;
      IF_ID_pc     <= PC;
      IF_ID_instr  <= instr_mem[PC[9:2]];
    end
  end

  // ID Stage: decode and register fetch
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ID_EX_pc      <= 0;
      ID_EX_reg1    <= 0;
      ID_EX_reg2    <= 0;
      ID_EX_imm     <= 0;
      ID_EX_rs      <= 0;
      ID_EX_rt      <= 0;
      ID_EX_rd      <= 0;
      ID_EX_funct   <= 0;
      ID_EX_opcode  <= 0;
    end else if (!stall) begin
      ID_EX_pc      <= IF_ID_pc;
      ID_EX_reg1    <= regfile[rs];
      ID_EX_reg2    <= regfile[rt];
      ID_EX_imm     <= sign_ext_imm;
      ID_EX_rs      <= rs;
      ID_EX_rt      <= rt;
      ID_EX_rd      <= rd;
      ID_EX_funct   <= IF_ID_instr[5:0];
      ID_EX_opcode  <= IF_ID_instr[31:26];
    end
  end

  // EX Stage: ALU operation and forwarding
  reg [31:0] alu_operand1, alu_operand2;
  reg [31:0] alu_result;

  always @(*) begin
    // Forward MUX A
    case (forwardA)
      2'b00: alu_operand1 = ID_EX_reg1;
      2'b01: alu_operand1 = MEM_WB_alu_result;
      2'b10: alu_operand1 = EX_MEM_alu_result;
      default: alu_operand1 = ID_EX_reg1;
    endcase

    // Forward MUX B
    case (forwardB)
      2'b00: alu_operand2 = ID_EX_reg2;
      2'b01: alu_operand2 = MEM_WB_alu_result;
      2'b10: alu_operand2 = EX_MEM_alu_result;
      default: alu_operand2 = ID_EX_reg2;
    endcase

    // Simple ALU operation (for addi)
    if (ID_EX_opcode == 6'h08) // addi
      alu_result = alu_operand1 + ID_EX_imm;
    else
      alu_result = alu_operand1 + alu_operand2; // Default add
  end

  // EX/MEM pipeline register update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      EX_MEM_alu_result <= 0;
      EX_MEM_reg2_value <= 0;
      EX_MEM_rd_reg     <= 0;
      EX_MEM_reg_write  <= 0;
      EX_MEM_mem_read   <= 0;
      EX_MEM_mem_write  <= 0;
    end else begin
      EX_MEM_alu_result <= alu_result;
      EX_MEM_reg2_value <= alu_operand2;
      EX_MEM_rd_reg     <= (ID_EX_opcode == 6'h08) ? ID_EX_rt : ID_EX_rd; // ADDI uses rt as destination
      EX_MEM_reg_write  <= (ID_EX_opcode != 6'b101011); // Do not write for SW
      EX_MEM_mem_read   <= (ID_EX_opcode == 6'b100011); // Set for LW
      EX_MEM_mem_write  <= (ID_EX_opcode == 6'b101011); // Set for SW
    end
  end

  // MEM/WB pipeline register update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      MEM_WB_alu_result <= 0;
      MEM_WB_read_data  <= 0;
      MEM_WB_rd_reg     <= 0;
      MEM_WB_reg_write  <= 0;
      MEM_WB_mem_read_active <= 0;
    end else begin
      MEM_WB_alu_result <= EX_MEM_alu_result;
      MEM_WB_read_data  <= cache_data_out; // Data from cache
      MEM_WB_rd_reg     <= EX_MEM_rd_reg;
      MEM_WB_reg_write  <= EX_MEM_reg_write;
      MEM_WB_mem_read_active <= EX_MEM_mem_read; // Pass mem_read signal
    end
  end

  // WB Stage: Write Back to Register File
  always @(posedge clk) begin
    if (MEM_WB_reg_write && MEM_WB_rd_reg != 0) begin
      if (MEM_WB_mem_read_active)
        regfile[MEM_WB_rd_reg] <= MEM_WB_read_data;  // For LW
      else
        regfile[MEM_WB_rd_reg] <= MEM_WB_alu_result; // For R-type, ADDI
    end
  end

  // Connect to hazard and forwarding units
  assign EX_MEM_rd = EX_MEM_rd_reg;
  assign MEM_WB_rd = MEM_WB_rd_reg;
  assign EX_MEM_regwrite = EX_MEM_reg_write;
  assign MEM_WB_regwrite = MEM_WB_reg_write;
  assign EX_MEM_memread = EX_MEM_mem_read;
  assign EX_MEM_memwrite = EX_MEM_mem_write;

  // Instantiate forwarding and hazard units
  forwarding_unit FU(
    .EX_mem_rd(EX_MEM_rd),
    .MEM_wb_rd(MEM_WB_rd),
    .EX_mem_regwrite(EX_MEM_regwrite),
    .MEM_wb_regwrite(MEM_WB_regwrite),
    .ID_ex_rs(ID_EX_rs),
    .ID_ex_rt(ID_EX_rt),
    .forwardA(forwardA),
    .forwardB(forwardB)
  );

  hazard_unit HU(
    .ID_ex_rs(ID_EX_rs),
    .ID_ex_rt(ID_EX_rt),
    .EX_mem_rt(EX_MEM_rd),
    .EX_mem_memread(EX_MEM_memread),
    .stall(stall)
  );

  branch_predictor BP(
    .clk(clk),
    .pc(IF_ID_pc),
    .branch(IF_ID_instr[31:26] == 6'b000100), // example BEQ opcode
    .actual(1'b0),  // testbench drives actual
    .taken(),
    .update()
  );

  cache_controller CC(
    .clk(clk),
    .rst(rst),
    .addr(EX_MEM_alu_result), // Cache address from ALU result
    .rd(EX_MEM_mem_read),
    .wr(EX_MEM_mem_write),
    .hit(cache_hit),         // Connect hit signal
    .data_out(cache_data_out) // Connect data_out signal
  );

  // TODO: 衝刺時間有限，datapath 與控制信號請依需求擴充
endmodule
