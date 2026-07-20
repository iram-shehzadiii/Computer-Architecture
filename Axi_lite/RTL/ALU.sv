module ALU(
    input  logic [31:0] src1,
    input  logic [31:0] src2,
    input  logic [3:0]  ALUcontrol,
    output logic        b_out,
    output logic [31:0] ALU_result
);

always_comb begin
    ALU_result = 32'd0;
    b_out = 0;

    case (ALUcontrol)
        // ADD / ADDI / load / store /jalr
        4'b0000: ALU_result = src1 + src2;

        // SUB
        4'b0001: ALU_result = src1 - src2;

        // OR / ORI
        4'b0010: ALU_result = src1 | src2;

        // AND / ANDI
        4'b0011: ALU_result = src1 & src2;

        // XOR / XORI
        4'b0100: ALU_result = src1 ^ src2;

        // SLL
        4'b0101: ALU_result = src1 << src2[4:0];

        // SRA
        4'b0110: ALU_result = $signed(src1) >>> src2[4:0];

        // SRL
        4'b0111: ALU_result = src1 >> src2[4:0];

        // SLT / BLT condition check
        4'b1000: ALU_result = ($signed(src1) < $signed(src2)) ? 32'd1 : 32'd0;

        // SLTU / SLTIU / BLTU condition check
        4'b1001: ALU_result = (src1 < src2) ? 32'd1 : 32'd0;

        // BEQ condition check
        4'b1010: ALU_result = (src1 == src2) ? 32'd1 : 32'd0;

        // BNE
        4'b1011: ALU_result = (src1 != src2) ? 32'd1 : 32'd0;

        // BGE
        4'b1100: ALU_result = ($signed(src1) >= $signed(src2)) ? 32'd1 : 32'd0;

        // BGEU
        4'b1101: ALU_result = (src1 >= src2) ? 32'd1 : 32'd0;

        default: ALU_result = 32'd0;
    endcase


    b_out = (ALU_result != 32'd0) ? 1'b1 : 1'b0;
end

endmodule