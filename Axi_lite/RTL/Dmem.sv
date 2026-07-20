module Dmem (
    input  logic         clk,
    input  logic         MemWrite,
    input  logic         MemRead,
    input  logic [31:0]  address,
    input  logic [31:0]  write_data,
    output logic [31:0]  read_data
);

logic [31:0] memory [511:0];

// Synchronous write
always_ff @(posedge clk) begin
    if (MemWrite)
        memory[address[10:2]] <= write_data;
end

// Asynchronous read
always_comb begin
    if (MemRead)
        read_data = memory[address[10:2]];
    else
        read_data = 32'b0;
end

endmodule