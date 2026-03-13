module imm_gen (
    input  wire[31:0] i_inst,
    output reg[31:0]  o_imm
);
    // Extract opcode from instruction
    wire[6:0] opcode = i_inst[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011, // I-type (arithmetic ex. addi, ...)
            7'b0000011, // I-type (load, ex. lb, ...)
            7'b1100111: // I-type (jalr)
                o_imm = {{20{i_inst[31]}}, i_inst[31:20]};
            
            7'b0100011: // S-type (store, ex. sb, ...)
                o_imm = {{20{i_inst[31]}}, i_inst[31:25], i_inst[11:7]};
            
            7'b1100011: // B-type (branch, ex. beq, ...)
                o_imm = {{19{i_inst[31]}}, i_inst[31], i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0};
            
            7'b0110111, // U-type (lui)
            7'b0010111: // U-type (auipc)
                o_imm = {i_inst[31:12], 12'b0};
            
            7'b1101111: // J-type (jal)
                o_imm = {{11{i_inst[31]}}, i_inst[31], i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0};
            
            default:
                o_imm = 32'd0;
        endcase
    end

endmodule
