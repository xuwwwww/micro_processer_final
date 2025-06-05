module mips_pipeline(
    input clk,
    input rst
);

// Pipeline registers
reg [31:0] PC_IF_reg;
reg [31:0] IF_ID_PC, IF_ID_Instr;
reg IF_ID_Valid;

// Register file and memory
reg [31:0] registers [0:31];
reg [31:0] instr_mem [0:1023];
reg [31:0] data_mem [0:1023];

// Instruction decode
wire [5:0] opcode = IF_ID_Instr[31:26];
wire [4:0] rs = IF_ID_Instr[25:21];
wire [4:0] rt = IF_ID_Instr[20:16];
wire [4:0] rd = IF_ID_Instr[15:11];
wire [15:0] immediate = IF_ID_Instr[15:0];
wire [31:0] sign_extended_imm = {{16{immediate[15]}}, immediate};

// Control signals
reg reg_write, mem_to_reg, mem_write, alu_src, branch;
reg [2:0] alu_op;

// ALU
reg [31:0] alu_result;
reg zero;

// PC calculation
wire [31:0] PC_plus_4 = PC_IF_reg + 4;
wire [31:0] branch_target = IF_ID_PC + (sign_extended_imm << 2);
wire branch_taken = branch && zero;
wire [31:0] next_pc = branch_taken ? branch_target : PC_plus_4;

// Test program initialization
initial begin
    for (integer i = 0; i < 32; i = i + 1) begin
        registers[i] = 32'h0;
    end
    
    registers[8] = 32'h00000003;  // $t0 = 3
    registers[9] = 32'h00000002;  // $t1 = 2
    registers[10] = 32'h00000000; // $t2 = 0
    
    // Test program: nested loops
    instr_mem[0] = 32'h20090002;  // ADDI $t1, $zero, 2
    instr_mem[1] = 32'h200A0000;  // ADDI $t2, $zero, 0
    instr_mem[2] = 32'h08000003;  // J 0x0C
    
    instr_mem[3] = 32'h214A0001;  // ADDI $t2, $t2, 1
    instr_mem[4] = 32'h2129FFFF;  // ADDI $t1, $t1, -1
    instr_mem[5] = 32'h1520FFFD;  // BNE $t1, $zero, -3
    
    instr_mem[6] = 32'h2108FFFF;  // ADDI $t0, $t0, -1
    instr_mem[7] = 32'h1500FFF9;  // BNE $t0, $zero, -7
    
    // End markers
    instr_mem[8] = 32'h00000000;
    instr_mem[9] = 32'h00000000;
    instr_mem[10] = 32'h00000000;
    instr_mem[11] = 32'h00000000;
    instr_mem[12] = 32'h00000000;
end

// Control logic
always @(*) begin
    reg_write = 0;
    mem_to_reg = 0;
    mem_write = 0;
    alu_src = 0;
    branch = 0;
    alu_op = 3'b000;
    
    case (opcode)
        6'b001000: begin // ADDI
            reg_write = 1;
            alu_src = 1;
            alu_op = 3'b000;
        end
        6'b000101: begin // BNE
            branch = 1;
            alu_op = 3'b001;
        end
        6'b000010: begin // J
            // handled in PC logic
        end
        default: begin
            // NOP
        end
    endcase
end

// ALU
always @(*) begin
    case (alu_op)
        3'b000: alu_result = registers[rs] + (alu_src ? sign_extended_imm : registers[rt]);
        3'b001: alu_result = registers[rs] - registers[rt];
        default: alu_result = 32'h0;
    endcase
    zero = (alu_result == 0);
end

// Pipeline
always @(posedge clk or posedge rst) begin
    if (rst) begin
        PC_IF_reg <= 32'h0;
        IF_ID_PC <= 32'h0;
        IF_ID_Instr <= 32'h0;
        IF_ID_Valid <= 0;
    end else begin
        PC_IF_reg <= next_pc;
        IF_ID_PC <= PC_IF_reg;
        IF_ID_Instr <= instr_mem[PC_IF_reg[11:2]];
        IF_ID_Valid <= 1;
    end
end

// Write back
always @(posedge clk) begin
    if (!rst && reg_write && IF_ID_Valid && rt != 0) begin
        registers[rt] <= alu_result;
    end
end

endmodule 