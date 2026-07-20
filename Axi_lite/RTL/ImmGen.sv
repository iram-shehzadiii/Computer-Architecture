module ImmGen (
    input  logic [31:0] instr,
    output logic [31:0] ImmExtend
);

//instruction[6:0]=opcode, instruction[14:12]=func3, instruction[31:25]=func7(for shift instructions)
always_comb begin
    case (instr[6:0])

        // I-Type (LOAD)
        7'b0000011: begin
            ImmExtend = {{20{instr[31]}}, instr[31:20]};
        end

        // I-Type (ARITHMETIC)
        7'b0010011: begin
            // Shift instructions: SLLI, SRLI, SRAI
            if ((instr[14:12] == 3'b001 && instr[31:25] == 7'b0000000) ||  // SLLI
                (instr[14:12] == 3'b101 && instr[31:25] == 7'b0000000) ||  // SRLI
                (instr[14:12] == 3'b101 && instr[31:25] == 7'b0100000))    // SRAI
            begin
                ImmExtend = {27'd0, instr[24:20]}; // shamt
            end
            else begin
                ImmExtend = {{20{instr[31]}}, instr[31:20]}; // for other arithmetic instructions
            end
        end

        // S-Type
        7'b0100011: begin
            ImmExtend = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        end

        // B-Type
        7'b1100011: begin
            ImmExtend = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
        end

        // J-Type
        7'b1101111: begin
            ImmExtend = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        end

        // I-Type (JALR)
        7'b1100111: begin
            ImmExtend = {{20{instr[31]}}, instr[31:20]};
        end

        // U-Type (LUI)
        7'b0110111: begin
            ImmExtend = {instr[31:12], 12'b0};
        end

        // U-Type (AUIPC)
        7'b0010111: begin
            ImmExtend = {instr[31:12], 12'b0};
        end

        // Default
        default: begin
            ImmExtend = 32'b0;
        end

    endcase
end

endmodule