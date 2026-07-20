module tb_axi;

    logic        clk, rst;
    logic [31:0] addr, wdata, rdata;
    logic        wen, ren, stall;

    logic [31:0] AWADDR, WDATA, ARADDR, RDATA;
    logic        AWVALID, AWREADY;
    logic [3:0]  WSTRB;
    logic        WVALID,  WREADY;
    logic [1:0]  BRESP,   RRESP;
    logic        BVALID,  BREADY;
    logic        ARVALID, ARREADY;
    logic        RVALID,  RREADY;

    axi_master_bridge master (
        .ACLK    (clk),
        .ARESETn (~rst),
        .addr    (addr),
        .wdata   (wdata),
        .wen     (wen),
        .ren     (ren),
        .rdata   (rdata),
        .stall   (stall),
        .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
        .WDATA(WDATA),   .WSTRB(WSTRB),     .WVALID(WVALID),   .WREADY(WREADY),
        .BRESP(BRESP),   .BVALID(BVALID),   .BREADY(BREADY),
        .ARADDR(ARADDR), .ARVALID(ARVALID), .ARREADY(ARREADY),
        .RDATA(RDATA),   .RRESP(RRESP),     .RVALID(RVALID),   .RREADY(RREADY)
    );

    axi_slave_model slave (
        .ACLK   (clk),
        .ARESETn(~rst),
        .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
        .WDATA(WDATA),   .WSTRB(WSTRB),     .WVALID(WVALID),   .WREADY(WREADY),
        .BRESP(BRESP),   .BVALID(BVALID),   .BREADY(BREADY),
        .ARADDR(ARADDR), .ARVALID(ARVALID), .ARREADY(ARREADY),
        .RDATA(RDATA),   .RRESP(RRESP),     .RVALID(RVALID),   .RREADY(RREADY)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // reset
        rst = 1; wen = 0; ren = 0; addr = 0; wdata = 0;
        repeat(5) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        // ── TEST 1: write 0x41 to TX FIFO at 0x40000004 ──────────
        $display("TEST1: write 0x41 to 0x40000004");
        addr  = 32'h40000004;
        wdata = 32'h00000041;
        wen   = 1;
        @(posedge clk);
        while (stall) @(posedge clk);
        wen = 0;
        repeat(2) @(posedge clk);
        $display("      slave.tx_fifo_reg = 0x%08h  (expect 0x00000041)",
                  slave.tx_fifo_reg);

        // ── TEST 2: read STATUS from 0x40000008 ───────────────────
        $display("TEST2: read STATUS from 0x40000008");
        addr = 32'h40000008;
        ren  = 1;
        @(posedge clk);
        while (stall) @(posedge clk);
        repeat(3) @(posedge clk);
        ren = 0;
        repeat(1) @(posedge clk);
        $display("      rdata = 0x%08h  (expect 0x00000001)", rdata);
        repeat(1) @(posedge clk);

        // ── TEST 3: read RX FIFO from 0x40000000 ─────────────────
        $display("TEST3: read RX FIFO from 0x40000000");
        addr = 32'h40000000;
        ren  = 1;
        @(posedge clk);
        while (stall) @(posedge clk);
        repeat(3) @(posedge clk);
        ren = 0;
        repeat(1) @(posedge clk);
        $display("      rdata = 0x%08h  (expect 0x00000042)", rdata);
        repeat(1) @(posedge clk);

        $display("done");
        $stop;
    end

endmodule