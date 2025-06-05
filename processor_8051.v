module processor_8051(
    input clk,
    input rst
);

// 8051 core registers
reg [15:0] PC;
reg [7:0] ACC;
reg [7:0] B;
reg [7:0] R0, R1, R2, R3, R4, R5, R6, R7;
reg [7:0] SP;
reg C, AC, F0, RS1, RS0, OV, P;

// Memory
reg [7:0] code_mem [0:4095];
reg [7:0] data_mem [0:255];

// Instruction processing
reg [7:0] current_instr;
reg [7:0] operand1, operand2;

// State machine
reg [2:0] state;
parameter FETCH = 0, DECODE = 1, EXECUTE = 2;

// Test program setup
initial begin
    R0 = 8'h03;     // outer counter
    R1 = 8'h02;     // inner counter
    R2 = 8'h00;     // branch counter
    
    // Nested loop test program
    code_mem[0] = 8'h78;   code_mem[1] = 8'h02;  // MOV R0, #02h
    code_mem[2] = 8'h79;   code_mem[3] = 8'h02;  // MOV R1, #02h
    code_mem[4] = 8'h7A;   code_mem[5] = 8'h00;  // MOV R2, #00h
    
    code_mem[6] = 8'h0A;                         // INC R2
    code_mem[7] = 8'h19;                         // DEC R1
    code_mem[8] = 8'hB9;   code_mem[9] = 8'h00;  code_mem[10] = 8'hFC; // CJNE R1,#00h,REL
    
    code_mem[11] = 8'h79;  code_mem[12] = 8'h02; // MOV R1, #02h
    code_mem[13] = 8'h18;                        // DEC R0
    code_mem[14] = 8'hB8;  code_mem[15] = 8'h00; code_mem[16] = 8'hF0; // CJNE R0,#00h,REL
    
    code_mem[17] = 8'h00;
    code_mem[18] = 8'h00;
    code_mem[19] = 8'h00;
    
    for (integer i = 20; i < 4096; i = i + 1) begin
        code_mem[i] = 8'h00;
    end
end

// Processor execution
always @(posedge clk or posedge rst) begin
    if (rst) begin
        PC <= 16'h0000;
        state <= FETCH;
        ACC <= 8'h00;
        B <= 8'h00;
        SP <= 8'h07;
        C <= 0; AC <= 0; F0 <= 0; RS1 <= 0; RS0 <= 0; OV <= 0; P <= 0;
    end else begin
        case (state)
            FETCH: begin
                current_instr <= code_mem[PC];
                PC <= PC + 1;
                state <= DECODE;
            end
            
            DECODE: begin
                case (current_instr)
                    8'h78: begin // MOV R0, #data
                        operand1 <= code_mem[PC];
                        PC <= PC + 1;
                    end
                    8'h79: begin // MOV R1, #data
                        operand1 <= code_mem[PC];
                        PC <= PC + 1;
                    end
                    8'h7A: begin // MOV R2, #data
                        operand1 <= code_mem[PC];
                        PC <= PC + 1;
                    end
                    8'h0A: begin // INC R2
                    end
                    8'h18: begin // DEC R0
                    end
                    8'h19: begin // DEC R1
                    end
                    8'hB8, 8'hB9: begin // CJNE Rn, #data, rel
                        operand1 <= code_mem[PC];
                        operand2 <= code_mem[PC + 1];
                        PC <= PC + 2;
                    end
                    default: begin
                    end
                endcase
                state <= EXECUTE;
            end
            
            EXECUTE: begin
                case (current_instr)
                    8'h78: R0 <= operand1;
                    8'h79: R1 <= operand1;
                    8'h7A: R2 <= operand1;
                    8'h0A: R2 <= R2 + 1;
                    8'h18: R0 <= R0 - 1;
                    8'h19: R1 <= R1 - 1;
                    8'hB8: begin // CJNE R0, #data, rel
                        if (R0 != operand1) begin
                            PC <= PC + {{8{operand2[7]}}, operand2};
                        end
                    end
                    8'hB9: begin // CJNE R1, #data, rel
                        if (R1 != operand1) begin
                            PC <= PC + {{8{operand2[7]}}, operand2};
                        end
                    end
                    default: begin
                    end
                endcase
                state <= FETCH;
            end
        endcase
    end
end

endmodule 