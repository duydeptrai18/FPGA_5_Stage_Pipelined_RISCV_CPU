/*
- This module will determine the alu operation, and alu valid based on opcode, funct3, and funct7 if needed.
- If the opcode is valid but neither of the other 2 signals, alu_valid = 0.
- Alu_add is the default operation
*/

module alu_decoder(
    input [31:0] instruction,
    output reg [3:0] alu_operation,
    output reg alu_valid
);

wire [6:0] opcode = instruction[6:0];
wire [2:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];

// Instruction groups
localparam R_TYPE = 7'b0110011;
localparam I_TYPE = 7'b0010011;
localparam LOAD   = 7'b0000011;
localparam STORE  = 7'b0100011;
localparam BRANCH = 7'b1100011;
localparam JAL    = 7'b1101111;
localparam JALR   = 7'b1100111;
localparam LUI    = 7'b0110111;
localparam AUIPC  = 7'b0010111;

// ALU operations
localparam ALU_ADD  = 4'b0000;
localparam ALU_SUB  = 4'b0001;
localparam ALU_AND  = 4'b0010;
localparam ALU_OR   = 4'b0011;
localparam ALU_XOR  = 4'b0100;
localparam ALU_SLL  = 4'b0101;
localparam ALU_SRL  = 4'b0110;
localparam ALU_SRA  = 4'b0111;
localparam ALU_SLT  = 4'b1000;
localparam ALU_SLTU = 4'b1001;

 
// Branch funct3 values
localparam F3_BEQ  = 3'b000;
localparam F3_BNE  = 3'b001;
localparam F3_BLT  = 3'b100;
localparam F3_BGE  = 3'b101;
localparam F3_BLTU = 3'b110;
localparam F3_BGEU = 3'b111;

// Arithmetic funct3 values
localparam F3_ADD_SUB = 3'b000;
localparam F3_SLL     = 3'b001;
localparam F3_SLT     = 3'b010;
localparam F3_SLTU    = 3'b011;
localparam F3_XOR     = 3'b100;
localparam F3_SRL_SRA = 3'b101;
localparam F3_OR      = 3'b110;
localparam F3_AND     = 3'b111;

// R-type funct7 values; also used to check I-type shift encodings
localparam F7_NORMAL  = 7'b0000000;
localparam F7_SUB_SRA = 7'b0100000;

always @(*) begin
    alu_valid     = 1'b0;
    alu_operation = ALU_ADD;

    case (opcode)
        R_TYPE: begin
            case (funct3)
                F3_ADD_SUB: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_ADD;
                        alu_valid = 1'b1;
                    end
                    else if (funct7 == F7_SUB_SRA) begin
                        alu_operation = ALU_SUB;
                        alu_valid = 1'b1;
                    end
                end

                F3_SLL: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_SLL;
                        alu_valid = 1'b1;
                    end
                end

                F3_SLT: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_SLT;
                        alu_valid = 1'b1;
                    end
                end

                F3_SLTU: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_SLTU;
                        alu_valid = 1'b1;
                    end
                end

                F3_XOR: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_XOR;
                        alu_valid = 1'b1;
                    end
                end

                F3_SRL_SRA: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_SRL;
                        alu_valid = 1'b1;
                    end
                    else if (funct7 == F7_SUB_SRA) begin
                        alu_operation = ALU_SRA;
                        alu_valid = 1'b1;
                    end
                end

                F3_OR: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_OR;
                        alu_valid = 1'b1;
                    end
                end

                F3_AND: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_AND;
                        alu_valid = 1'b1;
                    end
                end
        
            endcase
        end

        I_TYPE: begin
            // Only shifts check funct7. For other I-type operations, instruction[31:25] is part of the immediate.
            case (funct3)
                F3_ADD_SUB: begin
                    alu_operation = ALU_ADD; // ADDI
                    alu_valid = 1'b1;
                end

                F3_SLL: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_SLL; // SLLI
                        alu_valid = 1'b1;
                    end
                end

                F3_SLT: begin
                    alu_operation = ALU_SLT; // SLTI
                    alu_valid = 1'b1;
                end

                F3_SLTU: begin
                    alu_operation = ALU_SLTU; // SLTIU
                    alu_valid = 1'b1;
                end

                F3_XOR: begin
                    alu_operation = ALU_XOR; // XORI
                    alu_valid = 1'b1;
                end

                F3_SRL_SRA: begin
                    if (funct7 == F7_NORMAL) begin
                        alu_operation = ALU_SRL; // SRLI
                        alu_valid = 1'b1;
                    end
                    else if (funct7 == F7_SUB_SRA) begin
                        alu_operation = ALU_SRA; // SRAI
                        alu_valid = 1'b1;
                    end
                end

                F3_OR: begin
                    alu_operation = ALU_OR; // ORI
                    alu_valid = 1'b1;
                end

                F3_AND: begin
                    alu_operation = ALU_AND; // ANDI
                    alu_valid = 1'b1;
                end
            endcase
        end

        BRANCH: begin
            case (funct3)
                F3_BEQ, F3_BNE: begin
                    alu_operation = ALU_SUB;
                    alu_valid = 1'b1;
                end

                F3_BLT, F3_BGE: begin
                    alu_operation = ALU_SLT;
                    alu_valid = 1'b1;
                end

                F3_BLTU, F3_BGEU: begin
                    alu_operation = ALU_SLTU;
                    alu_valid = 1'b1;
                end
            endcase
        end

        STORE: begin
            if (funct3 == 3'b010) begin // SW
                alu_operation = ALU_ADD;
                alu_valid = 1'b1;
            end
        end

        LOAD: begin
            if (funct3 == 3'b010) begin // LW
                alu_operation = ALU_ADD;
                alu_valid = 1'b1;
            end
        end

        JALR: begin
            if (funct3 == 3'b000) begin
                alu_operation = ALU_ADD;
                alu_valid = 1'b1;
            end
        end

        JAL, LUI, AUIPC: begin
            alu_operation = ALU_ADD;
            alu_valid = 1'b1;
        end
    endcase
end

endmodule