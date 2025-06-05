`timescale 1ns/1ps
module pipeline_8051(
  input        clk,
  input        rst
);
  // Program counter (16-bit for 8051)
  reg [15:0] PC;
  reg [7:0] instr_mem [0:65535];  // 64KB instruction memory
  integer i;

  // 8051 Special Function Registers
  reg [7:0] ACC;        // Accumulator
  reg [7:0] B_reg;      // B register
  reg [7:0] PSW;        // Program Status Word
  reg [7:0] DPH, DPL;   // Data Pointer High/Low
  reg [7:0] SP;         // Stack Pointer
  reg [7:0] direct_mem [0:255];  // Direct addressing memory

  // Pipeline registers
  reg [15:0] IF_ID_instr, IF_ID_pc;
  reg [15:0] ID_EX_pc;
  reg [7:0]  ID_EX_acc, ID_EX_operand, ID_EX_direct_addr;
  reg [3:0]  ID_EX_opcode;
  reg        ID_EX_is_branch, ID_EX_is_jump;
  
  // EX/MEM pipeline registers
  reg [7:0]  EX_MEM_alu_result;
  reg [7:0]  EX_MEM_operand;
  reg [7:0]  EX_MEM_direct_addr;
  reg        EX_MEM_acc_write;
  reg        EX_MEM_mem_read;
  reg        EX_MEM_mem_write;
  reg        EX_MEM_is_branch;
  reg        EX_MEM_branch_taken;

  // MEM/WB pipeline registers
  reg [7:0]  MEM_WB_alu_result;
  reg [7:0]  MEM_WB_read_data;
  reg [7:0]  MEM_WB_direct_addr;
  reg        MEM_WB_acc_write;
  reg        MEM_WB_mem_read_active;

  // Control signals
  wire [1:0] forwardA;
  wire       stall;
  wire       cache_hit;
  wire [7:0] cache_data_out;
  wire       branch_taken_prediction;

  // Initialize instruction memory and SFRs
  initial begin
    // Initialize 8051 instruction memory
    // MOV A, #05h - Load immediate 5 into accumulator
    instr_mem[0] = 8'h74;  // MOV A, #data opcode
    instr_mem[1] = 8'h05;  // immediate data 5
    
    // MOV direct, #03h - Load immediate 3 into direct address 30h
    instr_mem[2] = 8'h75;  // MOV direct, #data opcode
    instr_mem[3] = 8'h30;  // direct address 30h
    instr_mem[4] = 8'h03;  // immediate data 3
    
    // ADD A, direct - Add direct address 30h to accumulator (data hazard)
    instr_mem[5] = 8'h25;  // ADD A, direct opcode
    instr_mem[6] = 8'h30;  // direct address 30h
    
    // CJNE A, #08h, rel - Compare A with 8, jump if not equal (branch hazard)
    instr_mem[7] = 8'hB4;  // CJNE A, #data, rel opcode
    instr_mem[8] = 8'h08;  // compare value 8
    instr_mem[9] = 8'h03;  // relative jump +3
    
    // MOV direct, A - Store accumulator to address 31h
    instr_mem[10] = 8'hF5; // MOV direct, A opcode
    instr_mem[11] = 8'h31; // direct address 31h
    
    // ADD A, #02h - Add immediate 2 to accumulator (data hazard)
    instr_mem[12] = 8'h24; // ADD A, #data opcode
    instr_mem[13] = 8'h02; // immediate data 2
    
    for (i = 14; i < 65536; i = i + 1)
      instr_mem[i] = 8'h00;  // NOP
    
    // Initialize SFRs
    ACC = 8'h00;
    B_reg = 8'h00;
    PSW = 8'h00;
    DPH = 8'h00;
    DPL = 8'h00;
    SP = 8'h07;  // Default stack pointer
    
    // Initialize direct memory
    for (i = 0; i < 256; i = i + 1)
      direct_mem[i] = 8'h00;
  end

  // IF Stage: update PC and fetch instruction
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      PC           <= 16'h0000;
      IF_ID_pc     <= 16'h0000;
      IF_ID_instr  <= 16'h0000;
    end else if (!stall) begin
      if (EX_MEM_is_branch && EX_MEM_branch_taken) begin
        PC <= EX_MEM_alu_result; // Branch target from ALU
      end else begin
        // Instruction length depends on opcode (8051 has variable length)
        case (instr_mem[PC])
          8'h74: PC <= PC + 2;  // MOV A, #data (2 bytes)
          8'h75: PC <= PC + 3;  // MOV direct, #data (3 bytes)
          8'h25: PC <= PC + 2;  // ADD A, direct (2 bytes)
          8'hF5: PC <= PC + 2;  // MOV direct, A (2 bytes)
          8'h24: PC <= PC + 2;  // ADD A, #data (2 bytes)
          8'hB4: PC <= PC + 3;  // CJNE A, #data, rel (3 bytes)
          default: PC <= PC + 1; // 1-byte instructions
        endcase
      end
      IF_ID_pc     <= PC;
      IF_ID_instr  <= {instr_mem[PC], instr_mem[PC+1]}; // Fetch 2 bytes
    end
  end

  // ID Stage: decode and operand fetch
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ID_EX_pc         <= 16'h0000;
      ID_EX_acc        <= 8'h00;
      ID_EX_operand    <= 8'h00;
      ID_EX_direct_addr <= 8'h00;
      ID_EX_opcode     <= 4'h0;
      ID_EX_is_branch  <= 1'b0;
      ID_EX_is_jump    <= 1'b0;
    end else if (!stall) begin
      ID_EX_pc         <= IF_ID_pc;
      ID_EX_acc        <= ACC;
      ID_EX_opcode     <= IF_ID_instr[15:12];
      ID_EX_is_branch  <= (IF_ID_instr[15:8] == 8'hB4); // CJNE
      ID_EX_is_jump    <= (IF_ID_instr[15:8] == 8'h80); // SJMP
      
      case (IF_ID_instr[15:8])
        8'h74: begin // MOV A, #data
          ID_EX_operand <= IF_ID_instr[7:0];
          ID_EX_opcode <= 4'h7;
        end
        8'h75: begin // MOV direct, #data
          ID_EX_direct_addr <= IF_ID_instr[7:0];
          ID_EX_operand <= instr_mem[IF_ID_pc+2];
          ID_EX_opcode <= 4'h5;  // 使用不同的opcode區分MOV direct,#data
        end
        8'h25: begin // ADD A, direct
          ID_EX_direct_addr <= IF_ID_instr[7:0];
          ID_EX_opcode <= 4'h2;
        end
        8'hF5: begin // MOV direct, A
          ID_EX_direct_addr <= IF_ID_instr[7:0];
          ID_EX_opcode <= 4'hF;
        end
        8'h24: begin // ADD A, #data
          ID_EX_operand <= IF_ID_instr[7:0];
          ID_EX_direct_addr <= 8'h00;  // Clear direct_addr for immediate mode
          ID_EX_opcode <= 4'h2;
        end
        8'hB4: begin // CJNE A, #data, rel
          ID_EX_operand <= IF_ID_instr[7:0];
          ID_EX_direct_addr <= instr_mem[IF_ID_pc+2];
          ID_EX_opcode <= 4'hB;
        end
        default: begin
          ID_EX_operand <= 8'h00;
          ID_EX_direct_addr <= 8'h00;
          ID_EX_opcode <= 4'h0;
        end
      endcase
    end
  end

  // EX Stage: ALU operation and forwarding
  reg [7:0] alu_operand1, alu_operand2;
  reg [7:0] alu_result;
  reg       branch_condition;

  always @(*) begin
    // Forward MUX A (for accumulator forwarding)
    case (forwardA)
      2'b00: alu_operand1 = ID_EX_acc;
      2'b01: alu_operand1 = MEM_WB_alu_result;
      2'b10: alu_operand1 = EX_MEM_alu_result;
      default: alu_operand1 = ID_EX_acc;
    endcase

    // ALU operation based on 8051 instruction
    case (ID_EX_opcode)
      4'h7: alu_result = ID_EX_operand;                    // MOV A, #data
      4'h5: alu_result = ID_EX_operand;                    // MOV direct, #data (pass operand to memory)
      4'h2: begin
        if (ID_EX_direct_addr != 8'h00)
          alu_result = alu_operand1 + direct_mem[ID_EX_direct_addr]; // ADD A, direct
        else
          alu_result = alu_operand1 + ID_EX_operand;       // ADD A, #data
      end
      4'hF: alu_result = alu_operand1;                     // MOV direct, A (pass ACC)
      4'hB: begin
        alu_result = ID_EX_pc + ID_EX_direct_addr;         // Branch target
        branch_condition = (alu_operand1 != ID_EX_operand); // Compare for CJNE
      end
      default: alu_result = alu_operand1;
    endcase
  end

  // EX/MEM pipeline register update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      EX_MEM_alu_result   <= 8'h00;
      EX_MEM_operand      <= 8'h00;
      EX_MEM_direct_addr  <= 8'h00;
      EX_MEM_acc_write    <= 1'b0;
      EX_MEM_mem_read     <= 1'b0;
      EX_MEM_mem_write    <= 1'b0;
      EX_MEM_is_branch    <= 1'b0;
      EX_MEM_branch_taken <= 1'b0;
    end else begin
      EX_MEM_alu_result   <= alu_result;
      EX_MEM_operand      <= ID_EX_operand;
      EX_MEM_direct_addr  <= ID_EX_direct_addr;
      EX_MEM_is_branch    <= ID_EX_is_branch;
      EX_MEM_branch_taken <= ID_EX_is_branch ? branch_condition : 1'b0;
      
      case (ID_EX_opcode)
        4'h7: begin // MOV A, #data or MOV direct, #data
          EX_MEM_acc_write <= 1'b1;   // MOV A writes to ACC
          EX_MEM_mem_write <= 1'b0;   // MOV A doesn't write memory
        end
        4'h5: begin // MOV direct, #data
          EX_MEM_acc_write <= 1'b0;   // MOV direct, #data doesn't write ACC
          EX_MEM_mem_write <= 1'b1;   // MOV direct, #data writes memory
        end
        4'h2: begin // ADD A
          EX_MEM_acc_write <= 1'b1;   // ADD writes to ACC
          EX_MEM_mem_write <= 1'b0;   // ADD doesn't write memory
        end
        4'hF: begin // MOV direct, A
          EX_MEM_acc_write <= 1'b0;   // MOV direct,A doesn't write ACC
          EX_MEM_mem_write <= 1'b1;   // MOV direct,A writes memory
        end
        4'hB: begin // CJNE (branch)
          EX_MEM_acc_write <= 1'b0;   // CJNE doesn't write ACC
          EX_MEM_mem_write <= 1'b0;   // CJNE doesn't write memory
        end
        default: begin
          EX_MEM_acc_write <= 1'b0;
          EX_MEM_mem_write <= 1'b0;
        end
      endcase
    end
  end

  // MEM/WB pipeline register update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      MEM_WB_alu_result     <= 8'h00;
      MEM_WB_read_data      <= 8'h00;
      MEM_WB_direct_addr    <= 8'h00;
      MEM_WB_acc_write      <= 1'b0;
      MEM_WB_mem_read_active <= 1'b0;
    end else begin
      MEM_WB_alu_result     <= EX_MEM_alu_result;
      MEM_WB_read_data      <= cache_data_out;
      MEM_WB_direct_addr    <= EX_MEM_direct_addr;
      MEM_WB_acc_write      <= EX_MEM_acc_write;
      MEM_WB_mem_read_active <= EX_MEM_mem_read;
    end
  end

  // WB Stage: Write Back to registers
  always @(posedge clk) begin
    if (MEM_WB_acc_write) begin
      ACC <= MEM_WB_alu_result;
    end
    if (EX_MEM_mem_write) begin
      direct_mem[EX_MEM_direct_addr] <= EX_MEM_alu_result;
    end
  end

  // Instantiate support units
  forwarding_unit_8051 FU(
    .EX_mem_acc_write(EX_MEM_acc_write),
    .MEM_wb_acc_write(MEM_WB_acc_write),
    .ID_ex_uses_acc(1'b1),  // Most 8051 instructions use accumulator
    .forwardA(forwardA)
  );

  hazard_unit_8051 HU(
    .ID_ex_uses_acc(1'b1),
    .EX_mem_acc_write(EX_MEM_acc_write),
    .EX_mem_mem_read(EX_MEM_mem_read),
    .stall(stall)
  );

  branch_predictor_8051 BP(
    .clk(clk),
    .pc(IF_ID_pc),
    .branch(ID_EX_is_branch),
    .actual(EX_MEM_branch_taken),
    .taken(branch_taken_prediction),
    .update()
  );

  cache_controller_8051 CC(
    .clk(clk),
    .rst(rst),
    .addr({8'h00, EX_MEM_direct_addr}), // 8-bit address extended to 16-bit
    .rd(EX_MEM_mem_read),
    .wr(EX_MEM_mem_write),
    .hit(cache_hit),
    .data_out(cache_data_out)
  );

endmodule 