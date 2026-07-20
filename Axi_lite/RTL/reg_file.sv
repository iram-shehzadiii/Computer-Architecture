module reg_file (
    input  logic        clk,
    input  logic        rst,
    input  logic [4:0]  read_reg1,
    input  logic [4:0]  read_reg2,
    input  logic [4:0]  write_reg,
    input  logic        RegWrite,
    input  logic [31:0] write_data,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] regfile [31:0];

    // Asynchronous read
    always_comb begin
        read_data1 = regfile[read_reg1];
        read_data2 = regfile[read_reg2];
    end

    // Write on negedge
    always_ff @(negedge clk or posedge rst) begin
        if (rst) begin
            regfile[0] <= 32'd0;   // only x0 reset
        end
        else if (RegWrite && write_reg != 5'd0) begin
            regfile[write_reg] <= write_data;
        end
    end

endmodule