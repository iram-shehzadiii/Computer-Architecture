module pc_adder(input  logic [31:0] pc_out,
                output logic [31:0] PCplus4);

always_comb begin
    PCplus4 = pc_out + 32'd4;
end

endmodule