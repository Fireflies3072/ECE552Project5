`default_nettype none

module mem_stage (
    input wire i_valid,
    input wire[31:0] i_alu_result,
    input wire[31:0] i_rs2_data,
    input wire i_mem_ren,
    input wire i_mem_wen,
    input wire[2:0] i_funct3,
    input wire[31:0] i_dmem_rdata,

    output wire[31:0] o_dmem_addr,
    output wire o_dmem_ren,
    output wire o_dmem_wen,
    output wire[3:0] o_dmem_mask,
    output wire[31:0] o_dmem_wdata,

    output wire[31:0] o_load_data,
    output wire[3:0] o_mem_dmem_mask,
    output wire[31:0] o_mem_dmem_wdata
);
    reg[3:0] mem_dmem_mask;
    reg[31:0] mem_dmem_wdata;

    // Write data to memory and read data from memory
    always @(*) begin
        mem_dmem_mask = 4'b0000;
        mem_dmem_wdata = 32'b0;
        case ({i_mem_wen, i_mem_ren})
            2'b10: begin
                case (i_funct3)
                    3'b000: begin
                        case (i_alu_result[1:0])
                            2'b00: begin mem_dmem_mask = 4'b0001; mem_dmem_wdata = {{24{i_rs2_data[7]}}, i_rs2_data[7:0]}; end
                            2'b01: begin mem_dmem_mask = 4'b0010; mem_dmem_wdata = {{16{i_rs2_data[7]}}, i_rs2_data[7:0], 8'b0}; end
                            2'b10: begin mem_dmem_mask = 4'b0100; mem_dmem_wdata = {{8{i_rs2_data[7]}}, i_rs2_data[7:0], 16'b0}; end
                            2'b11: begin mem_dmem_mask = 4'b1000; mem_dmem_wdata = {i_rs2_data[7:0], 24'b0}; end
                            default: begin mem_dmem_mask = 4'b0000; mem_dmem_wdata = 32'b0; end
                        endcase
                    end
                    3'b001: begin
                        case (i_alu_result[1])
                            1'b0: begin mem_dmem_mask = 4'b0011; mem_dmem_wdata = {16'b0, i_rs2_data[15:0]}; end
                            1'b1: begin mem_dmem_mask = 4'b1100; mem_dmem_wdata = {i_rs2_data[15:0], 16'b0}; end
                            default: begin mem_dmem_mask = 4'b0000; mem_dmem_wdata = 32'b0; end
                        endcase
                    end
                    3'b010: begin
                        mem_dmem_mask = 4'b1111;
                        mem_dmem_wdata = i_rs2_data;
                    end
                    default: begin
                        mem_dmem_mask = 4'b0000;
                        mem_dmem_wdata = 32'b0;
                    end
                endcase
            end
            2'b01: begin
                case (i_funct3)
                    3'b000, 3'b100: begin
                        case (i_alu_result[1:0])
                            2'b00: mem_dmem_mask = 4'b0001;
                            2'b01: mem_dmem_mask = 4'b0010;
                            2'b10: mem_dmem_mask = 4'b0100;
                            2'b11: mem_dmem_mask = 4'b1000;
                            default: mem_dmem_mask = 4'b0000;
                        endcase
                    end
                    3'b001, 3'b101: begin
                        case (i_alu_result[1])
                            1'b0: mem_dmem_mask = 4'b0011;
                            1'b1: mem_dmem_mask = 4'b1100;
                            default: mem_dmem_mask = 4'b0000;
                        endcase
                    end
                    3'b010: mem_dmem_mask = 4'b1111;
                    default: mem_dmem_mask = 4'b0000;
                endcase
            end
            default: begin
                mem_dmem_mask = 4'b0000;
                mem_dmem_wdata = 32'b0;
            end
        endcase
    end

    assign o_dmem_addr = {i_alu_result[31:2], 2'b00};
    assign o_dmem_ren = i_valid && i_mem_ren;
    assign o_dmem_wen = i_valid && i_mem_wen;
    assign o_dmem_mask = i_valid ? mem_dmem_mask : 4'b0000;
    assign o_dmem_wdata = mem_dmem_wdata;

    // Prepare output data
    reg [31:0] mem_load_data;
    always @(*) begin
        case (i_funct3)
            3'b000: begin // lb
                case (i_alu_result[1:0])
                    2'b00: mem_load_data = {{24{i_dmem_rdata[7]}}, i_dmem_rdata[7:0]};
                    2'b01: mem_load_data = {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]};
                    2'b10: mem_load_data = {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]};
                    2'b11: mem_load_data = {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]};
                    default: mem_load_data = 32'd0;
                endcase
            end
            3'b001: begin // lh
                case (i_alu_result[1])
                    1'b0: mem_load_data = {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]};
                    1'b1: mem_load_data = {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]};
                    default: mem_load_data = 32'd0;
                endcase
            end
            3'b010: mem_load_data = i_dmem_rdata; // lw
            3'b100: begin // lbu
                case (i_alu_result[1:0])
                    2'b00: mem_load_data = {{24{i_dmem_rdata[7]}}, i_dmem_rdata[7:0]};
                    2'b01: mem_load_data = {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]};
                    2'b10: mem_load_data = {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]};
                    2'b11: mem_load_data = {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]};
                    default: mem_load_data = 32'd0;
                endcase
            end
            3'b101: begin // lhu
                case (i_alu_result[1])
                    1'b0: mem_load_data = {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]};
                    1'b1: mem_load_data = {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]};
                    default: mem_load_data = 32'd0;
                endcase
            end
            default: mem_load_data = 32'd0;
        endcase
    end

    assign o_load_data = mem_load_data;
    assign o_mem_dmem_mask = mem_dmem_mask;
    assign o_mem_dmem_wdata = mem_dmem_wdata;
endmodule

`default_nettype wire
