module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and combinationally returns a 32-bit instruction word. This
    // is not representative of a realistic memory interface; it has been
    // modeled as more similar to a DFF or SRAM to simplify phase 3. In
    // later phases, you will replace this with a more realistic memory.
    //
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire [31:0] i_imem_rdata,
    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle. Reads are combinational - values are available immediately after
    // updating the address and asserting read enable. Writes occur on (and
    // are visible at) the next clock edge.
    //
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address on the next rising clock edge. It is illegal to assert this and
    // `o_dmem_ren` on the same cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // WISC-25 supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
	// The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this
    // should be 5'd0.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`), this
    // should be 5'd0.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc

`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS,
`endif
);
    // Fill in your implementation here.

    // PC Register
    reg[31:0] pc;
    wire[31:0] next_pc;

    always @(posedge i_clk) begin
        if (i_rst) begin
            pc <= RESET_ADDR;
        end else begin
            pc <= next_pc;
        end
    end

    // Instruction Fetch
    assign o_imem_raddr = pc;
    wire[31:0] inst = i_imem_rdata;

    // Decode
    wire[6:0] opcode = inst[6:0];
    wire[2:0] funct3 = inst[14:12];
    wire[6:0] funct7 = inst[31:25];
    wire[4:0] rs1_addr = inst[19:15];
    wire[4:0] rs2_addr = inst[24:20];
    wire[4:0] rd_addr = inst[11:7];

    wire reg_wen, alu_src1, alu_src2, mem_ren, mem_wen, branch, jump, jalr, halt;
    wire[3:0] alu_op;
    wire[1:0] wb_mux;

    control_unit ctrl (
        .i_opcode(opcode),
        .i_funct3(funct3),
        .i_funct7(funct7),
        .o_reg_wen(reg_wen),
        .o_alu_src1(alu_src1),
        .o_alu_src2(alu_src2),
        .o_alu_op(alu_op),
        .o_mem_ren(mem_ren),
        .o_mem_wen(mem_wen),
        .o_wb_mux(wb_mux),
        .o_branch(branch),
        .o_jump(jump),
        .o_jalr(jalr),
        .o_halt(halt)
    );

    wire[31:0] imm;
    imm_gen imm_g (
        .i_inst(inst),
        .o_imm(imm)
    );

    wire[31:0] rs1_data, rs2_data;
    reg[31:0] rd_data;
    regfile rf (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_addr(rs1_addr),
        .i_rs2_addr(rs2_addr),
        .i_rd_addr(rd_addr),
        .i_rd_data(rd_data),
        .i_rd_wen(reg_wen),
        .o_rs1_data(rs1_data),
        .o_rs2_data(rs2_data)
    );

    // Execute
    wire[31:0] alu_op_a = (alu_src1) ? pc : rs1_data;
    wire[31:0] alu_op_b = (alu_src2) ? imm : rs2_data;
    wire[31:0] alu_result;
    wire alu_zero;
    alu alu_inst (
        .i_a(alu_op_a),
        .i_b(alu_op_b),
        .i_alu_op(alu_op),
        .o_result(alu_result),
        .o_zero(alu_zero)
    );

    // Branch/Jump Logic
    reg take_branch;
    always @(*) begin
        case (funct3)
            3'b000: take_branch = alu_zero; // beq
            3'b001: take_branch = !alu_zero; // bne
            3'b100: take_branch = !alu_zero; // blt
            3'b101: take_branch = alu_zero; // bge
            3'b110: take_branch = !alu_zero; // bltu
            3'b111: take_branch = alu_zero; // bgeu
            default: take_branch = 0;
        endcase
    end

    wire[31:0] pc_plus_4 = pc + 4;
    wire[31:0] branch_target = pc + imm;
    wire[31:0] jalr_target = alu_result & ~32'h1;
    assign next_pc = (jump) ? branch_target :
                          (jalr) ? jalr_target :
                          (branch && take_branch) ? branch_target :
                          pc_plus_4;

    // Memory Access
    assign o_dmem_addr = {alu_result[31:2], 2'b00};
    assign o_dmem_ren = mem_ren;
    assign o_dmem_wen = mem_wen;
    
    // Memory Mask and Write Data
    reg[3:0] dmem_mask;
    reg[31:0] dmem_wdata;
    always @(*) begin
        dmem_mask = 4'b0000;
        dmem_wdata = 32'd0;
        case (mem_wen)
            1'b1: begin
                case (funct3)
                    3'b000: begin // sb
                        case (alu_result[1:0])
                            2'b00: begin dmem_mask = 4'b0001; dmem_wdata = {{24{rs2_data[7]}}, rs2_data[7:0]}; end
                            2'b01: begin dmem_mask = 4'b0010; dmem_wdata = {{16{rs2_data[7]}}, rs2_data[7:0], 8'b0}; end
                            2'b10: begin dmem_mask = 4'b0100; dmem_wdata = {{8{rs2_data[7]}}, rs2_data[7:0], 16'b0}; end
                            2'b11: begin dmem_mask = 4'b1000; dmem_wdata = {rs2_data[7:0], 24'b0}; end
                            default: begin dmem_mask = 4'b0000; dmem_wdata = 32'b0; end
                        endcase
                    end
                    3'b001: begin // sh
                        case (alu_result[1])
                            1'b0: begin dmem_mask = 4'b0011; dmem_wdata = {{16{rs2_data[15]}}, rs2_data[15:0]}; end
                            1'b1: begin dmem_mask = 4'b1100; dmem_wdata = {rs2_data[15:0], 16'b0}; end
                            default: begin dmem_mask = 4'b0000; dmem_wdata = 32'b0; end
                        endcase
                    end
                    3'b010: begin // sw
                        dmem_mask = 4'b1111;
                        dmem_wdata = rs2_data;
                    end
                    default: ;
                endcase
            end
            1'b0: begin
                case (mem_ren)
                    1'b1: begin
                        case (funct3)
                            3'b000, 3'b100: begin // lb, lbu
                                case (alu_result[1:0])
                                    2'b00: dmem_mask = 4'b0001;
                                    2'b01: dmem_mask = 4'b0010;
                                    2'b10: dmem_mask = 4'b0100;
                                    2'b11: dmem_mask = 4'b1000;
                                    default: dmem_mask = 4'b0000;
                                endcase
                            end
                            3'b001, 3'b101: begin // lh, lhu
                                case (alu_result[1])
                                    1'b0: dmem_mask = 4'b0011;
                                    1'b1: dmem_mask = 4'b1100;
                                    default: dmem_mask = 4'b0000;
                                endcase
                            end
                            3'b010: dmem_mask = 4'b1111; // lw
                            default: ;
                        endcase
                    end
                    default: ;
                endcase
            end
            default: ;
        endcase
    end
    assign o_dmem_mask = dmem_mask;
    assign o_dmem_wdata = dmem_wdata;

    // Load Data Processing
    reg [31:0] load_data;
    always @(*) begin
        case (funct3)
            3'b000: begin // lb
                case (alu_result[1:0])
                    2'b00: load_data = {{24{i_dmem_rdata[7]}}, i_dmem_rdata[7:0]};
                    2'b01: load_data = {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]};
                    2'b10: load_data = {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]};
                    2'b11: load_data = {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]};
                    default: load_data = 32'd0;
                endcase
            end
            3'b001: begin // lh
                case (alu_result[1:0])
                    2'b00: load_data = {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]};
                    2'b10: load_data = {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]};
                    default: load_data = 32'd0;
                endcase
            end
            3'b010: load_data = i_dmem_rdata; // lw

            3'b100: begin // lbu
                case (alu_result[1:0])
                    2'b00: load_data = {24'd0, i_dmem_rdata[7:0]};
                    2'b01: load_data = {24'd0, i_dmem_rdata[15:8]};
                    2'b10: load_data = {24'd0, i_dmem_rdata[23:16]};
                    2'b11: load_data = {24'd0, i_dmem_rdata[31:24]};
                    default: load_data = 32'd0;
                endcase
            end
            3'b101: begin // lhu
                case (alu_result[1:0])
                    2'b00: load_data = {16'd0, i_dmem_rdata[15:0]};
                    2'b10: load_data = {16'd0, i_dmem_rdata[31:16]};
                    default: load_data = 32'd0;
                endcase
            end

            default: load_data = 32'd0;
        endcase
    end

    // Writeback
    always @(*) begin
        case (wb_mux)
            2'd0: rd_data = alu_result;
            2'd1: rd_data = load_data;
            2'd2: rd_data = pc_plus_4;
            2'd3: rd_data = imm;
            default: rd_data = 32'd0;
        endcase
    end

    // Retire Interface
    assign o_retire_valid = !i_rst;
    assign o_retire_inst = inst;
    assign o_retire_trap = 0;
    assign o_retire_halt = halt;
    assign o_retire_rs1_raddr = rs1_addr;
    assign o_retire_rs2_raddr = rs2_addr;
    assign o_retire_rs1_rdata = rs1_data;
    assign o_retire_rs2_rdata = rs2_data;
    assign o_retire_rd_waddr = (reg_wen) ? rd_addr : 5'd0;
    assign o_retire_rd_wdata = rd_data;
    assign o_retire_pc = pc;
    assign o_retire_next_pc = next_pc;

endmodule

`default_nettype wire
