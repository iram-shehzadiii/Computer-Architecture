module cpu(
    input logic clk,
    input logic rst
);

// PC
logic [31:0] pc_out;     
logic [31:0] pc_next;    


logic [31:0] instr;
logic [31:0] immediate;

// Regfile
logic [31:0] read_data1, read_data2;
logic [31:0] write_data;  

//  ALU
logic [31:0] alu_operand2; // after ALUsrc mux
logic [31:0] ALU_result;
logic [3:0]  ALU_operation;
logic        zero;          

// Dmem 
logic [31:0] mem_read_data;


logic [31:0] PCplus4;     
logic [31:0] pc_target;     
logic [31:0] branch_src;   

// control signals
logic        RegWrite, ALUsrc, MemWrite, MemRead;
logic        branch, jump, jalr;
logic [1:0]  MemtoReg, ALUop;

// PC mux selection
logic pc_sel;
assign pc_sel = (branch & zero) | jump;

 
pc p1 (
    .clk     (clk),
    .rst     (rst),
    .in_addr (pc_next),
    .out_addr(pc_out)
);

pc_adder s1(
    .out_addr(pc_out),
    .PCplus4 (PCplus4)
);

Imem p2 (
    .addr (pc_out),
    .instr(instr)
);

control_logic ctrl(
    .opcode  (instr[6:0]),
    .branch  (branch),
    .jump    (jump),
    .jalr    (jalr),
    .MemRead (MemRead),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .ALUop   (ALUop),
    .ALUsrc  (ALUsrc),
    .RegWrite(RegWrite)
);

ImmGen s3(
    .instruction(instr),
    .immediate  (immediate)
);

reg_file p3(
    .clk       (clk),
    .rst       (rst),
    .read_reg1 (instr[19:15]),
    .read_reg2 (instr[24:20]),
    .write_reg (instr[11:7]),
    .RegWrite  (RegWrite),
    .write_data(write_data),
    .read_data1(read_data1),
    .read_data2(read_data2)
);

mux m2(
    .in1    (read_data2),
    .in2    (immediate),
    .sel    (ALUsrc),
    .mux_out(alu_operand2)
);

ALUctrl s4(
    .ALUop       (ALUop),
    .func3       (instr[14:12]),
    .func7       (instr[31:25]),
    .ALU_operation(ALU_operation)
);

ALU p4(
    .operand1  (read_data1),
    .operand2  (alu_operand2),
    .ALU_operation(ALU_operation),
    .ALU_result(ALU_result),
    .zero      (zero)
);

Dmem p5(
    .clk       (clk),
    .MemWrite  (MemWrite),
    .MemRead   (MemRead),
    .address   (ALU_result),
    .write_data(read_data2),
    .read_data (mem_read_data)
);

mux m4(
    .in1    (pc_out), 
    .in2    (read_data1), 
    .sel    (jalr),
    .mux_out(branch_src)
);

branch_adder s2(
    .branch_src (branch_src),
    .immediate(immediate),
    .pc_target(pc_target)
);

mux m1(
    .in1    (PCplus4),  
    .in2    (pc_target), 
    .sel    (pc_sel),
    .mux_out(pc_next)
);

mux_4x1 m3(
    .in1    (ALU_result),  
    .in2    (mem_read_data), 
    .in3    (PCplus4),     
    .in4    (immediate),     
    .sel    (MemtoReg),
    .mux_out(write_data)
);

endmodule