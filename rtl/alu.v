module alu (
    input  wire[31:0] i_a,
    input  wire[31:0] i_b,
    input  wire[3:0]  i_alu_op,
    output reg [31:0] o_result,
    output wire       o_zero
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
        case (i_alu_op)
            ALU_ADD:  o_result = i_a + i_b;
            ALU_SUB:  o_result = i_a - i_b;
            ALU_SLL:  begin
                case (i_b[4:0])
                    5'd0: o_result = i_a;
                    5'd1: o_result = {i_a[30:0], 1'b0};
                    5'd2: o_result = {i_a[29:0], 2'b0};
                    5'd3: o_result = {i_a[28:0], 3'b0};
                    5'd4: o_result = {i_a[27:0], 4'b0};
                    5'd5: o_result = {i_a[26:0], 5'b0};
                    5'd6: o_result = {i_a[25:0], 6'b0};
                    5'd7: o_result = {i_a[24:0], 7'b0};
                    5'd8: o_result = {i_a[23:0], 8'b0};
                    5'd9: o_result = {i_a[22:0], 9'b0};
                    5'd10: o_result = {i_a[21:0], 10'b0};
                    5'd11: o_result = {i_a[20:0], 11'b0};
                    5'd12: o_result = {i_a[19:0], 12'b0};
                    5'd13: o_result = {i_a[18:0], 13'b0};
                    5'd14: o_result = {i_a[17:0], 14'b0};
                    5'd15: o_result = {i_a[16:0], 15'b0};
                    5'd16: o_result = {i_a[15:0], 16'b0};
                    5'd17: o_result = {i_a[14:0], 17'b0};
                    5'd18: o_result = {i_a[13:0], 18'b0};
                    5'd19: o_result = {i_a[12:0], 19'b0};
                    5'd20: o_result = {i_a[11:0], 20'b0};
                    5'd21: o_result = {i_a[10:0], 21'b0};
                    5'd22: o_result = {i_a[9:0], 22'b0};
                    5'd23: o_result = {i_a[8:0], 23'b0};
                    5'd24: o_result = {i_a[7:0], 24'b0};
                    5'd25: o_result = {i_a[6:0], 25'b0};
                    5'd26: o_result = {i_a[5:0], 26'b0};
                    5'd27: o_result = {i_a[4:0], 27'b0};
                    5'd28: o_result = {i_a[3:0], 28'b0};
                    5'd29: o_result = {i_a[2:0], 29'b0};
                    5'd30: o_result = {i_a[1:0], 30'b0};
                    5'd31: o_result = {i_a[0], 31'b0};
                    default: o_result = i_a;
                endcase
            end
            ALU_SLT:  o_result = (i_a[31] != i_b[31]) ? (i_a[31] ? 32'd1 : 32'd0) : (i_a < i_b ? 32'd1 : 32'd0);
            ALU_SLTU: o_result = (i_a < i_b) ? 32'd1 : 32'd0;
            ALU_XOR:  o_result = i_a ^ i_b;
            ALU_SRL:  begin
                case (i_b[4:0])
                    5'd0: o_result = i_a;
                    5'd1: o_result = {1'b0, i_a[31:1]};
                    5'd2: o_result = {2'b0, i_a[31:2]};
                    5'd3: o_result = {3'b0, i_a[31:3]};
                    5'd4: o_result = {4'b0, i_a[31:4]};
                    5'd5: o_result = {5'b0, i_a[31:5]};
                    5'd6: o_result = {6'b0, i_a[31:6]};
                    5'd7: o_result = {7'b0, i_a[31:7]};
                    5'd8: o_result = {8'b0, i_a[31:8]};
                    5'd9: o_result = {9'b0, i_a[31:9]};
                    5'd10: o_result = {10'b0, i_a[31:10]};
                    5'd11: o_result = {11'b0, i_a[31:11]};
                    5'd12: o_result = {12'b0, i_a[31:12]};
                    5'd13: o_result = {13'b0, i_a[31:13]};
                    5'd14: o_result = {14'b0, i_a[31:14]};
                    5'd15: o_result = {15'b0, i_a[31:15]};
                    5'd16: o_result = {16'b0, i_a[31:16]};
                    5'd17: o_result = {17'b0, i_a[31:17]};
                    5'd18: o_result = {18'b0, i_a[31:18]};
                    5'd19: o_result = {19'b0, i_a[31:19]};
                    5'd20: o_result = {20'b0, i_a[31:20]};
                    5'd21: o_result = {21'b0, i_a[31:21]};
                    5'd22: o_result = {22'b0, i_a[31:22]};
                    5'd23: o_result = {23'b0, i_a[31:23]};
                    5'd24: o_result = {24'b0, i_a[31:24]};
                    5'd25: o_result = {25'b0, i_a[31:25]};
                    5'd26: o_result = {26'b0, i_a[31:26]};
                    5'd27: o_result = {27'b0, i_a[31:27]};
                    5'd28: o_result = {28'b0, i_a[31:28]};
                    5'd29: o_result = {29'b0, i_a[31:29]};
                    5'd30: o_result = {30'b0, i_a[31:30]};
                    5'd31: o_result = {31'b0, i_a[31]};
                    default: o_result = i_a;
                endcase
            end
            ALU_SRA:  begin
                case (i_b[4:0])
                    5'd0: o_result = i_a;
                    5'd1: o_result = {{1{i_a[31]}}, i_a[31:1]};
                    5'd2: o_result = {{2{i_a[31]}}, i_a[31:2]};
                    5'd3: o_result = {{3{i_a[31]}}, i_a[31:3]};
                    5'd4: o_result = {{4{i_a[31]}}, i_a[31:4]};
                    5'd5: o_result = {{5{i_a[31]}}, i_a[31:5]};
                    5'd6: o_result = {{6{i_a[31]}}, i_a[31:6]};
                    5'd7: o_result = {{7{i_a[31]}}, i_a[31:7]};
                    5'd8: o_result = {{8{i_a[31]}}, i_a[31:8]};
                    5'd9: o_result = {{9{i_a[31]}}, i_a[31:9]};
                    5'd10: o_result = {{10{i_a[31]}}, i_a[31:10]};
                    5'd11: o_result = {{11{i_a[31]}}, i_a[31:11]};
                    5'd12: o_result = {{12{i_a[31]}}, i_a[31:12]};
                    5'd13: o_result = {{13{i_a[31]}}, i_a[31:13]};
                    5'd14: o_result = {{14{i_a[31]}}, i_a[31:14]};
                    5'd15: o_result = {{15{i_a[31]}}, i_a[31:15]};
                    5'd16: o_result = {{16{i_a[31]}}, i_a[31:16]};
                    5'd17: o_result = {{17{i_a[31]}}, i_a[31:17]};
                    5'd18: o_result = {{18{i_a[31]}}, i_a[31:18]};
                    5'd19: o_result = {{19{i_a[31]}}, i_a[31:19]};
                    5'd20: o_result = {{20{i_a[31]}}, i_a[31:20]};
                    5'd21: o_result = {{21{i_a[31]}}, i_a[31:21]};
                    5'd22: o_result = {{22{i_a[31]}}, i_a[31:22]};
                    5'd23: o_result = {{23{i_a[31]}}, i_a[31:23]};
                    5'd24: o_result = {{24{i_a[31]}}, i_a[31:24]};
                    5'd25: o_result = {{25{i_a[31]}}, i_a[31:25]};
                    5'd26: o_result = {{26{i_a[31]}}, i_a[31:26]};
                    5'd27: o_result = {{27{i_a[31]}}, i_a[31:27]};
                    5'd28: o_result = {{28{i_a[31]}}, i_a[31:28]};
                    5'd29: o_result = {{29{i_a[31]}}, i_a[31:29]};
                    5'd30: o_result = {{30{i_a[31]}}, i_a[31:30]};
                    5'd31: o_result = {{31{i_a[31]}}, i_a[31]};
                    default: o_result = i_a;
                endcase
            end
            ALU_OR:   o_result = i_a | i_b;
            ALU_AND:  o_result = i_a & i_b;
            default:  o_result = 32'd0;
        endcase
    end

    // Zero flag
    assign o_zero = (o_result == 32'd0);

endmodule
