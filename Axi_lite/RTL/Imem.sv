
module Imem(
    input  logic [31:0] address,
    output logic [31:0] instr
);
    always_comb begin
        case (address[9:2])
            8'd0:    instr = 32'h400002b7; // lui x5, 0x40000
            8'd1:    instr = 32'h04100313; // addi x6, x0, 65
            8'd2:    instr = 32'h0082a383; // lw x7, 8(x5)
            8'd3:    instr = 32'h0083f393; // andi x7, x7, 8
            8'd4:    instr = 32'hfe039de3; // bne x7, x0, -8
            8'd5:    instr = 32'h0062a223; // sw x6, 4(x5)
            8'd6:    instr = 32'h0000006f; // jal x0, halt
            default: instr = 32'h00000013; // NOP
        endcase
    end
endmodule


// module Imem(input  logic [31:0] address,
//             output logic [31:0] instr
//             );

// logic [31:0] memory [255:0];

// always_comb begin
//     instr = memory[address[9:2]]; 
// end

// endmodule