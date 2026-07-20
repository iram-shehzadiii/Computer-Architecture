module pc (input  logic        clk,
           input  logic        rst,
           input  logic        stall_in,
           input  logic [31:0] pc_in,
           output logic [31:0] pc_out );

always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin
        pc_out <= 32'd0;
    end
    else if (!stall_in) begin
        pc_out <= pc_in;
    end
end
endmodule