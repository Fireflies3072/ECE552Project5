module control_unit (
    input  wire[6:0] i_opcode,
    input  wire[2:0] i_funct3,
    input  wire[6:0] i_funct7,
    output reg o_reg_wen,
    output reg o_alu_src1,
    output reg o_alu_src2,
    output reg[3:0] o_alu_op,
    output reg o_mem_ren,
    output reg o_mem_wen,
    output reg[1:0] o_wb_mux,
    output reg o_branch,
    output reg o_jump,
    output reg o_jalr,
    output reg o_halt
);
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
        o_reg_wen = 0;
        o_alu_src1 = 0;
        o_alu_src2 = 0;
        o_alu_op = ALU_ADD;
        o_mem_ren = 0;
        o_mem_wen = 0;
        o_wb_mux = 2'd0;
        o_branch = 0;
        o_jump = 0;
        o_jalr = 0;
        o_halt = 0;

        case (i_opcode)
            7'b0110011: begin
                o_reg_wen = 1;
                case (i_funct3)
                    3'b000: begin
                        o_alu_op = i_funct7[5] ? ALU_SUB : ALU_ADD;
                    end
                    3'b001: o_alu_op = ALU_SLL;
                    3'b010: o_alu_op = ALU_SLT;
                    3'b011: o_alu_op = ALU_SLTU;
                    3'b100: o_alu_op = ALU_XOR;
                    3'b101: begin
                        o_alu_op = i_funct7[5] ? ALU_SRA : ALU_SRL;
                    end
                    3'b110: o_alu_op = ALU_OR;
                    3'b111: o_alu_op = ALU_AND;
                    default: o_alu_op = ALU_ADD;
                endcase
            end

            7'b0010011: begin
                o_reg_wen = 1;
                o_alu_src2 = 1;
                case (i_funct3)
                    3'b000: o_alu_op = ALU_ADD;
                    3'b001: o_alu_op = ALU_SLL;
                    3'b010: o_alu_op = ALU_SLT;
                    3'b011: o_alu_op = ALU_SLTU;
                    3'b100: o_alu_op = ALU_XOR;
                    3'b101: begin
                        o_alu_op = i_funct7[5] ? ALU_SRA : ALU_SRL;
                    end
                    3'b110: o_alu_op = ALU_OR;
                    3'b111: o_alu_op = ALU_AND;
                    default: o_alu_op = ALU_ADD;
                endcase
            end
            7'b0000011: begin
                o_reg_wen = 1;
                o_alu_src2 = 1;
                o_alu_op = ALU_ADD;
                o_mem_ren = 1;
                o_wb_mux = 2'd1;
            end

            7'b0100011: begin
                o_alu_src2 = 1;
                o_alu_op = ALU_ADD;
                o_mem_wen = 1;
            end

            7'b1100011: begin
                o_branch = 1;
                o_alu_op = ALU_ADD;
            end

            7'b1101111: begin
                o_reg_wen = 1;
                o_jump = 1;
                o_wb_mux = 2'd2;
            end

            7'b1100111: begin
                o_reg_wen = 1;
                o_jalr = 1;
                o_alu_src2 = 1;
                o_alu_op = ALU_ADD;
                o_wb_mux = 2'd2;
            end

            7'b0110111: begin
                o_reg_wen = 1;
                o_wb_mux = 2'd3;
            end
            7'b0010111: begin
                o_reg_wen = 1;
                o_alu_src1 = 1;
                o_alu_src2 = 1;
                o_alu_op = ALU_ADD;
            end

            7'b1110011: begin
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
