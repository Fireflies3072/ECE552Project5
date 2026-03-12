module regfile (
    input  wire       i_clk,
    input  wire       i_rst,
    input  wire[4:0]  i_rs1_addr,
    input  wire[4:0]  i_rs2_addr,
    input  wire[4:0]  i_rd_addr,
    input  wire[31:0] i_rd_data,
    input  wire       i_rd_wen,
    output wire[31:0] o_rs1_data,
    output wire[31:0] o_rs2_data
);
    // Define 32 registers of 32 bits each
    reg[31:0] regs[0:31];

    // Read registers by directly mapping values to outputs
    assign o_rs1_data = (i_rs1_addr == 5'b0) ? 32'b0 : regs[i_rs1_addr];
    assign o_rs2_data = (i_rs2_addr == 5'b0) ? 32'b0 : regs[i_rs2_addr];

    // Write data to registers synchronously
    always @(posedge i_clk) begin
        if (i_rst) begin
            regs[0]  <= 32'b0; regs[1]  <= 32'b0; regs[2]  <= 32'b0; regs[3]  <= 32'b0;
            regs[4]  <= 32'b0; regs[5]  <= 32'b0; regs[6]  <= 32'b0; regs[7]  <= 32'b0;
            regs[8]  <= 32'b0; regs[9]  <= 32'b0; regs[10] <= 32'b0; regs[11] <= 32'b0;
            regs[12] <= 32'b0; regs[13] <= 32'b0; regs[14] <= 32'b0; regs[15] <= 32'b0;
            regs[16] <= 32'b0; regs[17] <= 32'b0; regs[18] <= 32'b0; regs[19] <= 32'b0;
            regs[20] <= 32'b0; regs[21] <= 32'b0; regs[22] <= 32'b0; regs[23] <= 32'b0;
            regs[24] <= 32'b0; regs[25] <= 32'b0; regs[26] <= 32'b0; regs[27] <= 32'b0;
            regs[28] <= 32'b0; regs[29] <= 32'b0; regs[30] <= 32'b0; regs[31] <= 32'b0;
        end else if (i_rd_wen && i_rd_addr != 5'b0) begin
            regs[i_rd_addr] <= i_rd_data;
        end
    end

endmodule
