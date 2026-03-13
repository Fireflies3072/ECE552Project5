`default_nettype none

module id_stage (
    input wire i_clk,
    input wire i_rst,
    input wire[31:0] i_inst,

    input wire[4:0] i_wb_rd_addr,
    input wire[31:0] i_wb_rd_data,
    input wire i_wb_reg_wen,

    output wire[4:0] o_rs1_addr,
    output wire[4:0] o_rs2_addr,
    output wire[4:0] o_rd_addr,
    output wire[2:0] o_funct3,

    output wire[31:0] o_imm,
    output wire[31:0] o_rs1_data,
    output wire[31:0] o_rs2_data,

    output wire[3:0] o_alu_op,
    output wire[1:0] o_wb_mux,
    output wire o_reg_wen,
    output wire o_alu_src1,
    output wire o_alu_src2,
    output wire o_mem_ren,
    output wire o_mem_wen,
    output wire o_branch,
    output wire o_jump,
    output wire o_jalr,
    output wire o_halt,

    output wire o_uses_rs1,
    output wire o_uses_rs2
);
    wire[6:0] id_opcode = i_inst[6:0];
    wire[2:0] id_funct3 = i_inst[14:12];
    wire[6:0] id_funct7 = i_inst[31:25];

    assign o_rs1_addr = i_inst[19:15];
    assign o_rs2_addr = i_inst[24:20];
    assign o_rd_addr = i_inst[11:7];
    assign o_funct3 = id_funct3;

    control_unit ctrl (
        .i_opcode(id_opcode),
        .i_funct3(id_funct3),
        .i_funct7(id_funct7),
        .o_reg_wen(o_reg_wen),
        .o_alu_src1(o_alu_src1),
        .o_alu_src2(o_alu_src2),
        .o_alu_op(o_alu_op),
        .o_mem_ren(o_mem_ren),
        .o_mem_wen(o_mem_wen),
        .o_wb_mux(o_wb_mux),
        .o_branch(o_branch),
        .o_jump(o_jump),
        .o_jalr(o_jalr),
        .o_halt(o_halt)
    );

    imm_gen imm_g (
        .i_inst(i_inst),
        .o_imm(o_imm)
    );

    regfile #(
        .BYPASS_EN(1)
    ) regfile_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_addr(o_rs1_addr),
        .i_rs2_addr(o_rs2_addr),
        .i_rd_addr(i_wb_rd_addr),
        .i_rd_data(i_wb_rd_data),
        .i_rd_wen(i_wb_reg_wen),
        .o_rs1_data(o_rs1_data),
        .o_rs2_data(o_rs2_data)
    );

    assign o_uses_rs1 = (id_opcode == 7'b0110011) | // R-type
                        (id_opcode == 7'b0010011) | // I-op
                        (id_opcode == 7'b0000011) | // load
                        (id_opcode == 7'b0100011) | // store
                        (id_opcode == 7'b1100011) | // branch
                        (id_opcode == 7'b1100111);  // jalr

    assign o_uses_rs2 = (id_opcode == 7'b0110011) | // R-type
                        (id_opcode == 7'b0100011) | // store
                        (id_opcode == 7'b1100011);  // branch
endmodule

`default_nettype wire
