module pipe_reg2 (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 1:0] MemtoReg_de,
    input  logic        MemRead_de,
    input  logic        MemWrite_de,
    input  logic        stall_in,
    input  logic        RegWrite_de,
    input  logic [31:0] ALU_result_de,
    input  logic [31:0] read_data2_de,
    input  logic [4:0]  w_reg,
    input  logic [31:0] ImmExtend_de,
    input  logic [31:0] PCplus4_de,

    output logic [ 1:0] MemtoReg_mw,
    output logic        MemRead_mw,
    output logic        MemWrite_mw,
    output logic        RegWrite_mw,
    output logic [31:0] ALU_result_mw,
    output logic [31:0] read_data2_mw,
    output logic [4:0]  write_reg,
    output logic [31:0] ImmExtend_mw,
    output logic [31:0] PCplus4_mw
);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
    MemtoReg_mw   <= 2'd0;
    MemRead_mw    <= 0;
    MemWrite_mw   <= 0;
    RegWrite_mw   <= 0;
    ALU_result_mw <= 32'd0;
    read_data2_mw <= 32'd0;
    write_reg     <= 5'd0;
    PCplus4_mw    <= 32'd0;
    ImmExtend_mw  <= 32'd0;
    end
    
    else if (!stall_in) begin
    MemtoReg_mw   <= MemtoReg_de;
    MemRead_mw    <= MemRead_de;
    MemWrite_mw   <= MemWrite_de;
    RegWrite_mw   <= RegWrite_de;
    ALU_result_mw <= ALU_result_de;
    read_data2_mw <= read_data2_de;
    write_reg     <= w_reg;
    ImmExtend_mw    <= ImmExtend_de;
    PCplus4_mw    <= PCplus4_de;
    end
end

endmodule
