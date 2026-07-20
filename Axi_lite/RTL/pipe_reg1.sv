module pipe_reg1 (
    input  logic        clk,
    input  logic        rst,
    input  logic        flush,
    input  logic        stall_in,
    input  logic [31:0] pc_out_f,
    input  logic [31:0] instr_f,
    input  logic [31:0] PCplus4_f,

    output logic [31:0] PCplus4_de,
    output logic [31:0] instr_de,
    output logic [31:0] pc_out_de
);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        PCplus4_de <=  32'd0;
        instr_de   <=  32'd0;
        pc_out_de  <=  32'd0;
    end
    
    else if (flush) begin
        instr_de   <= 32'd0; 
    end

    else if (!stall_in)  begin
        PCplus4_de <= PCplus4_f;
        instr_de   <= instr_f;
        pc_out_de  <= pc_out_f;
    end
end

endmodule

