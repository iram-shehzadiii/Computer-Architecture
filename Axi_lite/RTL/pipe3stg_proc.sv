// pipe3stg_proc.sv — fixed port name mismatches
// Fixes vs submitted code:
//   pc.sv       declares port as 'stall_in'  → .stall_in(stall)
//   pipe_reg1   declares port as 'stall_in'  → .stall_in(stall)
//   pipe_reg2   declares port as 'stall_in'  → .stall_in(stall)
// All three were incorrectly connected as .stall(stall) which would
// cause "named port connection does not exist" synthesis/sim errors.

module pipe3stg_proc(
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] proc_addr,
    output logic [31:0] proc_wdata,
    output logic        proc_wen,
    output logic        proc_ren,
    input  logic [31:0] rdata_in,
    input  logic        stall
);

// ── Nets ──────────────────────────────────────────────────────
logic [31:0] pc_out_f, pc_out_de, PCplus4_f, PCplus4_de, PCplus4_mw;
logic [31:0] read_data1, read_data2_mw, read_data2_de, ALU_result_mw;
logic [31:0] ALU_result_de, pc_target, instr_f, instr_de;
logic [31:0] ImmExtend_de, ImmExtend_mw;
logic [3:0]  ALUcontrol;
logic [31:0] m1out, m2out, m3out, m4out;
logic [4:0]  write_reg;

// ── Control signals ───────────────────────────────────────────
logic RegWrite_de, ALUsrc_de, MemWrite_de, MemRead_de;
logic jump_de, branch_de, jalr_de;
logic RegWrite_mw, MemWrite_mw, MemRead_mw;
logic [1:0] MemtoReg_de, MemtoReg_mw;
logic [1:0] ALUop_de;

// ── Branch/flush ──────────────────────────────────────────────
logic b_out;
logic flush;
assign flush = (b_out && branch_de) || jump_de;

// ── MW stage outputs ──────────────────────────────────────────
assign proc_addr  = ALU_result_mw;
assign proc_wdata = read_data2_mw;
assign proc_wen   = MemWrite_mw;
assign proc_ren   = MemRead_mw;

// ── PC ────────────────────────────────────────────────────────
// FIX: pc.sv port is 'stall_in', not 'stall'
pc p1(
    .pc_in   (m1out),
    .clk     (clk),
    .rst     (rst),
    .stall_in(stall),       // FIXED: was .stall
    .pc_out  (pc_out_f)
);

// ── Instruction memory ────────────────────────────────────────
Imem p2(
    .address(pc_out_f),
    .instr  (instr_f)
);

// ── Register file ─────────────────────────────────────────────
reg_file p3(
    .read_reg1 (instr_de[19:15]),
    .read_reg2 (instr_de[24:20]),
    .write_reg (write_reg),
    .write_data(m3out),
    .read_data1(read_data1),
    .read_data2(read_data2_de),
    .clk       (clk),
    .rst       (rst),
    .RegWrite  (RegWrite_mw)
);

// ── ALU source mux ────────────────────────────────────────────
mux m2(
    .in1    (read_data2_de),
    .in2    (ImmExtend_de),
    .sel    (ALUsrc_de),
    .mux_out(m2out)
);

// ── ALU ───────────────────────────────────────────────────────
ALU p4(
    .src1      (read_data1),
    .src2      (m2out),
    .b_out     (b_out),
    .ALU_result(ALU_result_de),
    .ALUcontrol(ALUcontrol)
);

// ── Writeback mux ─────────────────────────────────────────────
// in2 = rdata_in (from top mux: dmem or slave_rdata)
mux_4x1 m3(
    .in1    (ALU_result_mw),
    .in2    (rdata_in),
    .in3    (PCplus4_mw),
    .in4    (ImmExtend_mw),
    .sel    (MemtoReg_mw),
    .mux_out(m3out)
);

// ── PC+4 adder ────────────────────────────────────────────────
pc_adder s1(
    .pc_out (pc_out_f),
    .PCplus4(PCplus4_f)
);

// ── Branch target adder ───────────────────────────────────────
branch_adder s2(
    .adr      (m4out),
    .ImmExtend(ImmExtend_de),
    .pc_target(pc_target)
);

// ── PC mux ────────────────────────────────────────────────────
mux m1(
    .in1    (PCplus4_f),
    .in2    (pc_target & 32'hFFFFFFFE),
    .sel    (flush),
    .mux_out(m1out)
);

// ── Immediate generator ───────────────────────────────────────
ImmGen s3(
    .instr    (instr_de),
    .ImmExtend(ImmExtend_de)
);

// ── ALU control ───────────────────────────────────────────────
ALUctrl s4(
    .ALUop     (ALUop_de),
    .func3     (instr_de[14:12]),
    .func7     (instr_de[31:25]),
    .ALUcontrol(ALUcontrol)
);

// ── Main control ──────────────────────────────────────────────
control_logic ctrl(
    .opcode  (instr_de[6:0]),
    .RegWrite(RegWrite_de),
    .ALUsrc  (ALUsrc_de),
    .MemWrite(MemWrite_de),
    .MemRead (MemRead_de),
    .MemtoReg(MemtoReg_de),
    .branch  (branch_de),
    .jump    (jump_de),
    .jalr    (jalr_de),
    .ALUop   (ALUop_de)
);

// ── Pipeline register 1 (IF → DE) ────────────────────────────
// FIX: pipe_reg1 port is 'stall_in', not 'stall'
pipe_reg1 pipe1(
    .clk       (clk),
    .rst       (rst),
    .flush     (flush),
    .stall_in  (stall),     // FIXED: was .stall
    .pc_out_f  (pc_out_f),
    .instr_f   (instr_f),
    .PCplus4_f (PCplus4_f),
    .pc_out_de (pc_out_de),
    .instr_de  (instr_de),
    .PCplus4_de(PCplus4_de)
);

// ── Pipeline register 2 (DE → MWB) ───────────────────────────
// FIX: pipe_reg2 port is 'stall_in', not 'stall'
pipe_reg2 pipe2(
    .clk          (clk),
    .rst          (rst),
    .stall_in     (stall),  // FIXED: was .stall
    .MemtoReg_de  (MemtoReg_de),
    .MemRead_de   (MemRead_de),
    .MemWrite_de  (MemWrite_de),
    .RegWrite_de  (RegWrite_de),
    .ALU_result_de(ALU_result_de),
    .read_data2_de(read_data2_de),
    .ImmExtend_de (ImmExtend_de),
    .w_reg        (instr_de[11:7]),
    .PCplus4_de   (PCplus4_de),
    .MemtoReg_mw  (MemtoReg_mw),
    .MemRead_mw   (MemRead_mw),
    .MemWrite_mw  (MemWrite_mw),
    .RegWrite_mw  (RegWrite_mw),
    .ALU_result_mw(ALU_result_mw),
    .read_data2_mw(read_data2_mw),
    .write_reg    (write_reg),
    .ImmExtend_mw (ImmExtend_mw),
    .PCplus4_mw   (PCplus4_mw)
);

// ── JALR source mux ───────────────────────────────────────────
mux m4(
    .in1    (pc_out_de),
    .in2    (read_data1),
    .sel    (jalr_de),
    .mux_out(m4out)
);

endmodule
