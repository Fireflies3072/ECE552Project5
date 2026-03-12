module control_unit (
    input  wire[6:0] i_opcode,
    input  wire[2:0] i_funct3,
    input  wire[6:0] i_funct7,
    output reg       o_reg_wen,  // 0: don't write register, 1: write register
    output reg       o_alu_src1, // 0: rs1, 1: pc
    output reg       o_alu_src2, // 0: rs2, 1: imm
    output reg[3:0]  o_alu_op,   // ALU arithmetic operations
    output reg       o_mem_ren,  // 0: don't read memory, 1: read memory
    output reg       o_mem_wen,  // 0: don't write memory, 1: write memory
    output reg[1:0]  o_wb_mux,   // Write back: 0: ALU, 1: Mem, 2: PC+4, 3: Imm
    output reg       o_branch,   // 0: don't branch, 1: branch
    output reg       o_jump,     // 0: don't jump, 1: jump
    output reg       o_jalr,     // 0: don't jalr, 1: jalr
    output reg       o_halt      // 0: don't exit, 1: exit
);
    // ALU arithmetic operations
    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;
    localparam ALU_SLL = 4'd2;
    localparam ALU_SLT = 4'd3;
    localparam ALU_SLTU = 4'd4;
    localparam ALU_XOR = 4'd5;
    localparam ALU_SRL = 4'd6;
    localparam ALU_SRA = 4'd7;
    localparam ALU_OR = 4'd8;
    localparam ALU_AND = 4'd9;

    always @(*) begin
        // Initialize default output values
        o_reg_wen = 0;
        o_alu_src1 = 0;
        o_alu_src2 = 0;
        o_alu_op = 4'b0000;
        o_mem_ren = 0;
        o_mem_wen = 0;
        o_wb_mux = 2'd0;
        o_branch = 0;
        o_jump = 0;
        o_jalr = 0;
        o_halt = 0;

        case (i_opcode)
            7'b0110011: begin // R-type
                o_reg_wen = 1;
                o_alu_src2 = 0;
                o_wb_mux  = 2'd0;
                case (i_funct3)
                    3'b000: o_alu_op = (i_funct7[5]) ? ALU_SUB : ALU_ADD; // sub : add
                    3'b001: o_alu_op = ALU_SLL; // sll
                    3'b010: o_alu_op = ALU_SLT; // slt
                    3'b011: o_alu_op = ALU_SLTU; // sltu
                    3'b100: o_alu_op = ALU_XOR; // xor
                    3'b101: o_alu_op = (i_funct7[5]) ? ALU_SRA : ALU_SRL; // sra : srl
                    3'b110: o_alu_op = ALU_OR; // or
                    3'b111: o_alu_op = ALU_AND; // and
                    default: o_alu_op = ALU_ADD;
                endcase
            end

            7'b0010011: begin // I-type (arithmetic, ex. addi, ...)
                o_reg_wen = 1;
                o_alu_src2 = 1;
                o_wb_mux  = 2'd0;
                case (i_funct3)
                    3'b000: o_alu_op = ALU_ADD; // addi
                    3'b001: o_alu_op = ALU_SLL; // slli
                    3'b010: o_alu_op = ALU_SLT; // slti
                    3'b011: o_alu_op = ALU_SLTU; // sltiu
                    3'b100: o_alu_op = ALU_XOR; // xori
                    3'b101: o_alu_op = (i_funct7[5]) ? ALU_SRA : ALU_SRL; // srai : srli
                    3'b110: o_alu_op = ALU_OR; // ori
                    3'b111: o_alu_op = ALU_AND; // andi
                    default: o_alu_op = ALU_ADD;
                endcase
            end
            7'b0000011: begin // I-type (load, ex. lb, ...)
                o_reg_wen = 1;
                o_alu_src2 = 1;
                o_alu_op = ALU_ADD; // add address
                o_mem_ren = 1;
                o_wb_mux = 2'd1;
            end

            7'b0100011: begin // S-type (store, ex. sb, ...)
                o_alu_src2 = 1;
                o_alu_op = ALU_ADD; // add address
                o_mem_wen = 1;
            end

            7'b1100011: begin // B-type (branch, ex. beq, ...)
                o_branch = 1;
                o_alu_src2 = 0;
                case (i_funct3)
                    3'b000, 3'b001: o_alu_op = ALU_XOR; // beq, bne (use xor)
                    3'b100, 3'b101: o_alu_op = ALU_SLT; // blt, bge (use slt)
                    3'b110, 3'b111: o_alu_op = ALU_SLTU; // bltu, bgeu (use sltu)
                    default: o_alu_op = ALU_ADD;
                endcase
            end

            7'b1101111: begin // J-type (jal)
                o_reg_wen = 1;
                o_jump = 1;
                o_wb_mux = 2'd2; // PC+4
            end

            7'b1100111: begin // I-type (jalr)
                o_reg_wen = 1;
                o_jalr = 1;
                o_alu_src2 = 1;
                o_alu_op = ALU_ADD; // rs1 + imm
                o_wb_mux = 2'd2; // PC+4
            end

            7'b0110111: begin // U-type (lui)
                o_reg_wen = 1;
                o_wb_mux = 2'd3; // imm
            end
            7'b0010111: begin // U-type (auipc)
                o_reg_wen = 1;
                o_alu_src1 = 1; // pc
                o_alu_src2 = 1; // imm
                o_alu_op = ALU_ADD;
                o_wb_mux = 2'd0; // ALU
            end

            7'b1110011: begin // System (ebreak)
                case (i_funct3)
                    3'b000: begin
                        case (i_funct7)
                            7'b0000000: o_halt = 1;
                            default: ;
                        endcase
                    end
                    default: ;
                endcase
            end

            default: ;
        endcase
    end
endmodule
