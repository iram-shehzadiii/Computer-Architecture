module branch_adder(input  logic [31:0] adr,
                    input  logic [31:0] ImmExtend,
                    output logic [31:0] pc_target
);

always_comb begin
    pc_target = adr + ImmExtend;
end

endmodule