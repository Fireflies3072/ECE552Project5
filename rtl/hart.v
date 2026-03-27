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
    output wire [31:0] o_retire_dmem_addr,
    output wire [ 3:0] o_retire_dmem_mask,
    output wire        o_retire_dmem_ren,
    output wire        o_retire_dmem_wen,
    output wire [31:0] o_retire_dmem_rdata,
    output wire [31:0] o_retire_dmem_wdata,
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

    // IF stage
    reg[31:0] if_pc;
    wire[31:0] if_inst;
    wire[31:0] if_pc_plus_4;

    if_stage if_stage_inst (
        .i_pc(if_pc),
        .i_imem_rdata(i_imem_rdata),
        .o_imem_raddr(o_imem_raddr),
        .o_inst(if_inst),
        .o_pc_plus_4(if_pc_plus_4)
    );

    // IF/ID pipeline register
    reg if_id_valid;
    reg[31:0] if_id_pc;
    reg[31:0] if_id_inst;

    // ID stage
    wire[4:0] id_rs1_addr, id_rs2_addr, id_rd_addr;
    wire[2:0] id_funct3;
    wire[31:0] id_imm;

    wire[31:0] id_rs1_data, id_rs2_data;
    wire[3:0] id_alu_op;
    wire[1:0] id_wb_mux;
    wire id_reg_wen, id_alu_src1, id_alu_src2;
    wire id_mem_ren, id_mem_wen, id_branch, id_jump, id_jalr, id_halt;
    wire id_uses_rs1, id_uses_rs2;

    wire[31:0] wb_rd_data;
    wire[4:0] wb_rd_addr;
    wire wb_reg_wen;

    id_stage id_stage_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_inst(if_id_inst),
        .i_wb_rd_addr(wb_rd_addr),
        .i_wb_rd_data(wb_rd_data),
        .i_wb_reg_wen(wb_reg_wen),
        .o_rs1_addr(id_rs1_addr),
        .o_rs2_addr(id_rs2_addr),
        .o_rd_addr(id_rd_addr),
        .o_funct3(id_funct3),
        .o_imm(id_imm),
        .o_rs1_data(id_rs1_data),
        .o_rs2_data(id_rs2_data),
        .o_alu_op(id_alu_op),
        .o_wb_mux(id_wb_mux),
        .o_reg_wen(id_reg_wen),
        .o_alu_src1(id_alu_src1),
        .o_alu_src2(id_alu_src2),
        .o_mem_ren(id_mem_ren),
        .o_mem_wen(id_mem_wen),
        .o_branch(id_branch),
        .o_jump(id_jump),
        .o_jalr(id_jalr),
        .o_halt(id_halt),
        .o_uses_rs1(id_uses_rs1),
        .o_uses_rs2(id_uses_rs2)
    );

    // ID/EX pipeline register
    reg id_ex_valid;
    reg[31:0] id_ex_inst;
    reg[31:0] id_ex_pc;
    reg[31:0] id_ex_next_pc_seq;
    reg[31:0] id_ex_imm;
    reg[31:0] id_ex_rs1_data;
    reg[31:0] id_ex_rs2_data;
    reg[4:0] id_ex_rs1_addr;
    reg[4:0] id_ex_rs2_addr;
    reg[4:0] id_ex_rd_addr;
    reg id_ex_reg_wen;
    reg id_ex_alu_src1;
    reg id_ex_alu_src2;
    reg[3:0] id_ex_alu_op;
    reg[2:0]  id_ex_funct3;
    reg id_ex_mem_ren;
    reg id_ex_mem_wen;
    reg[1:0] id_ex_wb_mux;
    reg id_ex_branch;
    reg id_ex_jump;
    reg id_ex_jalr;
    reg id_ex_halt;

    // EX stage
    wire[31:0] ex_alu_result;
    wire[31:0] ex_next_pc;
    wire ex_control_redirect;
    wire[31:0] ex_rs1_data_fwd;
    wire[31:0] ex_rs2_data_fwd;

    ex_stage ex_stage_inst (
        .i_valid(id_ex_valid),
        .i_pc(id_ex_pc),
        .i_next_pc_seq(id_ex_next_pc_seq),
        .i_imm(id_ex_imm),
        .i_rs1_data(ex_rs1_data_fwd),
        .i_rs2_data(ex_rs2_data_fwd),
        .i_alu_src1(id_ex_alu_src1),
        .i_alu_src2(id_ex_alu_src2),
        .i_alu_op(id_ex_alu_op),
        .i_funct3(id_ex_funct3),
        .i_branch(id_ex_branch),
        .i_jump(id_ex_jump),
        .i_jalr(id_ex_jalr),
        .o_alu_result(ex_alu_result),
        .o_next_pc(ex_next_pc),
        .o_control_redirect(ex_control_redirect)
    );

    // EX/MEM pipeline register
    reg ex_mem_valid;
    reg[31:0] ex_mem_pc;
    reg[31:0] ex_mem_inst;
    reg[31:0] ex_mem_next_pc;
    reg[4:0] ex_mem_rs1_addr;
    reg[4:0] ex_mem_rs2_addr;
    reg[31:0] ex_mem_rs1_data;
    reg[31:0] ex_mem_rs2_data;
    reg[31:0] ex_mem_store_data;
    reg[4:0] ex_mem_rd_addr;
    reg ex_mem_reg_wen;
    reg[1:0] ex_mem_wb_mux;
    reg[31:0] ex_mem_alu_result;
    reg[31:0] ex_mem_imm;
    reg ex_mem_mem_ren;
    reg ex_mem_mem_wen;
    reg[2:0] ex_mem_funct3;
    reg ex_mem_halt;

    // MEM stage
    wire[31:0] mem_load_data;
    wire[3:0]  mem_dmem_mask;
    wire[31:0] mem_dmem_wdata;

    mem_stage mem_stage_inst (
        .i_valid(ex_mem_valid),
        .i_alu_result(ex_mem_alu_result),
        .i_rs2_data(ex_mem_store_data),
        .i_mem_ren(ex_mem_mem_ren),
        .i_mem_wen(ex_mem_mem_wen),
        .i_funct3(ex_mem_funct3),
        .i_dmem_rdata(i_dmem_rdata),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_mask(o_dmem_mask),
        .o_dmem_wdata(o_dmem_wdata),
        .o_load_data(mem_load_data),
        .o_mem_dmem_mask(mem_dmem_mask),
        .o_mem_dmem_wdata(mem_dmem_wdata)
    );

    // MEM/WB pipeline register
    reg mem_wb_valid;
    reg[31:0] mem_wb_pc;
    reg[31:0] mem_wb_inst;
    reg[31:0] mem_wb_next_pc;

    reg[4:0] mem_wb_rs1_addr;
    reg[4:0] mem_wb_rs2_addr;
    reg[31:0] mem_wb_rs1_data;
    reg[31:0] mem_wb_rs2_data;
    reg[4:0] mem_wb_rd_addr;
    reg mem_wb_reg_wen;

    reg[1:0] mem_wb_wb_mux;
    reg[31:0] mem_wb_alu_result;
    reg[31:0] mem_wb_load_data;
    reg[31:0] mem_wb_imm;
    reg mem_wb_halt;
    reg[31:0] mem_wb_dmem_addr;
    reg mem_wb_dmem_ren;
    reg mem_wb_dmem_wen;
    reg[3:0] mem_wb_dmem_mask;
    reg[31:0] mem_wb_dmem_rdata;
    reg[31:0] mem_wb_dmem_wdata;

    // WB stage
    wb_stage wb_stage_inst (
        .i_valid(mem_wb_valid),
        .i_reg_wen(mem_wb_reg_wen),
        .i_rd_addr(mem_wb_rd_addr),
        .i_wb_mux(mem_wb_wb_mux),
        .i_alu_result(mem_wb_alu_result),
        .i_load_data(mem_wb_load_data),
        .i_pc(mem_wb_pc),
        .i_imm(mem_wb_imm),
        .o_wb_rd_addr(wb_rd_addr),
        .o_wb_rd_data(wb_rd_data),
        .o_wb_reg_wen(wb_reg_wen)
    );

    // Execution result
    wire[31:0] ex_mem_forward_data = (ex_mem_wb_mux == 2'd0) ? ex_mem_alu_result :
                                     (ex_mem_wb_mux == 2'd2) ? (ex_mem_pc + 32'd4) :
                                     (ex_mem_wb_mux == 2'd3) ? ex_mem_imm :
                                     32'd0;

    // EX-EX forwarding condition
    wire ex_ex_forward_rs1 = ex_mem_valid && ex_mem_reg_wen && (ex_mem_rd_addr != 5'd0) &&
                             (ex_mem_rd_addr == id_ex_rs1_addr);
    wire ex_ex_forward_rs2 = ex_mem_valid && ex_mem_reg_wen && (ex_mem_rd_addr != 5'd0) &&
                             (ex_mem_rd_addr == id_ex_rs2_addr);

    // MEM-EX forwarding condition
    wire mem_ex_forward_rs1 = mem_wb_valid && mem_wb_reg_wen && (mem_wb_rd_addr != 5'd0) &&
                              (mem_wb_rd_addr == id_ex_rs1_addr);
    wire mem_ex_forward_rs2 = mem_wb_valid && mem_wb_reg_wen && (mem_wb_rd_addr != 5'd0) &&
                              (mem_wb_rd_addr == id_ex_rs2_addr);

    // Forwarding data to EX stage
    assign ex_rs1_data_fwd = ex_ex_forward_rs1 ? ex_mem_forward_data :
                             mem_ex_forward_rs1 ? wb_rd_data :
                             id_ex_rs1_data;
    assign ex_rs2_data_fwd = ex_ex_forward_rs2 ? ex_mem_forward_data :
                             mem_ex_forward_rs2 ? wb_rd_data :
                             id_ex_rs2_data;

    // Stall when load-to-use hazards (load result is not ready for next EX cycle)
    wire load_use_hazard_rs1 = id_ex_valid && id_ex_mem_ren && (id_ex_rd_addr != 5'd0) &&
                               id_uses_rs1 && (id_ex_rd_addr == id_rs1_addr);
    wire load_use_hazard_rs2 = id_ex_valid && id_ex_mem_ren && (id_ex_rd_addr != 5'd0) &&
                               id_uses_rs2 && (id_ex_rd_addr == id_rs2_addr);

    wire id_stall = if_id_valid && (load_use_hazard_rs1 || load_use_hazard_rs2);

    // Intermediate state updates
    always @(posedge i_clk) begin
        if (i_rst) begin
            // Reset everything
            if_pc <= RESET_ADDR;
            if_id_valid <= 1'b0;
            id_ex_valid <= 1'b0;
            ex_mem_valid <= 1'b0;
            mem_wb_valid <= 1'b0;
        end else begin
            // PC update
            if (ex_control_redirect) begin
                if_pc <= ex_next_pc;
            end else if (!id_stall) begin
                if_pc <= if_pc_plus_4;
            end

            // IF/ID update
            if (ex_control_redirect) begin
                if_id_valid <= 1'b0;
                if_id_pc <= 32'd0;
                if_id_inst <= 32'd0;
            end else if (!id_stall) begin
                if_id_valid <= 1'b1;
                if_id_pc <= if_pc;
                if_id_inst <= if_inst;
            end

            // ID/EX update
            if (ex_control_redirect || id_stall || !if_id_valid) begin
                id_ex_valid <= 1'b0;
                id_ex_pc <= 32'd0;
                id_ex_inst <= 32'd0;
                id_ex_next_pc_seq <= 32'd0;
                id_ex_imm <= 32'd0;
                id_ex_rs1_data <= 32'd0;
                id_ex_rs2_data <= 32'd0;
                id_ex_rs1_addr <= 5'd0;
                id_ex_rs2_addr <= 5'd0;
                id_ex_rd_addr <= 5'd0;
                id_ex_reg_wen <= 1'b0;
                id_ex_alu_src1 <= 1'b0;
                id_ex_alu_src2 <= 1'b0;
                id_ex_alu_op <= 4'd0;
                id_ex_funct3 <= 3'd0;
                id_ex_mem_ren <= 1'b0;
                id_ex_mem_wen <= 1'b0;
                id_ex_wb_mux <= 2'd0;
                id_ex_branch <= 1'b0;
                id_ex_jump <= 1'b0;
                id_ex_jalr <= 1'b0;
                id_ex_halt <= 1'b0;
            end else begin
                id_ex_valid <= 1'b1;
                id_ex_pc <= if_id_pc;
                id_ex_inst <= if_id_inst;
                id_ex_next_pc_seq <= if_id_pc + 32'd4;
                id_ex_imm <= id_imm;
                id_ex_rs1_data <= id_rs1_data;
                id_ex_rs2_data <= id_rs2_data;
                id_ex_rs1_addr <= id_rs1_addr;
                id_ex_rs2_addr <= id_rs2_addr;
                id_ex_rd_addr <= id_rd_addr;
                id_ex_reg_wen <= id_reg_wen;
                id_ex_alu_src1 <= id_alu_src1;
                id_ex_alu_src2 <= id_alu_src2;
                id_ex_alu_op <= id_alu_op;
                id_ex_funct3 <= id_funct3;
                id_ex_mem_ren <= id_mem_ren;
                id_ex_mem_wen <= id_mem_wen;
                id_ex_wb_mux <= id_wb_mux;
                id_ex_branch <= id_branch;
                id_ex_jump <= id_jump;
                id_ex_jalr <= id_jalr;
                id_ex_halt <= id_halt;
            end

            // EX/MEM update
            ex_mem_valid <= id_ex_valid;
            ex_mem_pc <= id_ex_pc;
            ex_mem_inst <= id_ex_inst;
            ex_mem_next_pc <= ex_next_pc;
            ex_mem_rs1_addr <= id_ex_rs1_addr;
            ex_mem_rs2_addr <= id_ex_rs2_addr;
            ex_mem_rs1_data <= id_ex_rs1_data;
            ex_mem_rs2_data <= id_ex_rs2_data;
            ex_mem_store_data <= ex_rs2_data_fwd;
            ex_mem_rd_addr <= id_ex_rd_addr;
            ex_mem_reg_wen <= id_ex_reg_wen;
            ex_mem_wb_mux <= id_ex_wb_mux;
            ex_mem_alu_result <= ex_alu_result;
            ex_mem_imm <= id_ex_imm;
            ex_mem_mem_ren <= id_ex_mem_ren;
            ex_mem_mem_wen <= id_ex_mem_wen;
            ex_mem_funct3 <= id_ex_funct3;
            ex_mem_halt <= id_ex_halt;

            // MEM/WB update
            mem_wb_valid <= ex_mem_valid;
            mem_wb_pc <= ex_mem_pc;
            mem_wb_inst <= ex_mem_inst;
            mem_wb_next_pc <= ex_mem_next_pc;
            mem_wb_rs1_addr <= ex_mem_rs1_addr;
            mem_wb_rs2_addr <= ex_mem_rs2_addr;
            mem_wb_rs1_data <= ex_mem_rs1_data;
            mem_wb_rs2_data <= ex_mem_rs2_data;
            mem_wb_rd_addr <= ex_mem_rd_addr;
            mem_wb_reg_wen <= ex_mem_reg_wen;
            mem_wb_wb_mux <= ex_mem_wb_mux;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_load_data <= mem_load_data;
            mem_wb_imm <= ex_mem_imm;
            mem_wb_halt <= ex_mem_halt;
            mem_wb_dmem_addr <= {ex_mem_alu_result[31:2], 2'b00};
            mem_wb_dmem_ren <= ex_mem_mem_ren;
            mem_wb_dmem_wen <= ex_mem_mem_wen;
            mem_wb_dmem_mask <= mem_dmem_mask;
            mem_wb_dmem_rdata <= i_dmem_rdata;
            mem_wb_dmem_wdata <= mem_dmem_wdata;
        end
    end

    // Assign retire values
    assign o_retire_valid = mem_wb_valid;
    assign o_retire_inst = mem_wb_inst;
    assign o_retire_trap = 1'b0;
    assign o_retire_halt = mem_wb_halt;
    assign o_retire_rs1_raddr = mem_wb_rs1_addr;
    assign o_retire_rs2_raddr = mem_wb_rs2_addr;
    assign o_retire_rs1_rdata = mem_wb_rs1_data;
    assign o_retire_rs2_rdata = mem_wb_rs2_data;
    assign o_retire_rd_waddr = (mem_wb_valid && mem_wb_reg_wen) ? mem_wb_rd_addr : 5'd0;
    assign o_retire_rd_wdata = wb_rd_data;
    assign o_retire_pc = mem_wb_pc;
    assign o_retire_next_pc = mem_wb_next_pc;
    assign o_retire_dmem_addr = mem_wb_dmem_addr;
    assign o_retire_dmem_ren = mem_wb_dmem_ren;
    assign o_retire_dmem_wen = mem_wb_dmem_wen;
    assign o_retire_dmem_mask = mem_wb_dmem_mask;
    assign o_retire_dmem_wdata = mem_wb_dmem_wdata;
    assign o_retire_dmem_rdata = mem_wb_dmem_rdata;
endmodule

`default_nettype wire
