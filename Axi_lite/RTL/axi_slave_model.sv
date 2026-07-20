module axi_slave_model (
    input  logic        ACLK,
    input  logic        ARESETn,
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WVALID,
    output logic        WREADY,
    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    output logic [31:0] RDATA,
    output logic [1:0]  RRESP,
    output logic        RVALID,
    input  logic        RREADY
);

    localparam logic [31:0] STATUS_VAL = 32'h00000001;

    logic [31:0] tx_fifo_reg;
    logic [31:0] rx_fifo_reg;
    logic [31:0] control_reg;

    // ── Write FSM ─────────────────────────────────────────────────
    typedef enum logic [1:0] { W_IDLE=2'd0, W_LATCH=2'd1, W_RESP=2'd2 } wstate_t;
    wstate_t wstate;
    logic [31:0] waddr_reg;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            wstate      <= W_IDLE;
            waddr_reg   <= 32'b0;
            tx_fifo_reg <= 32'b0;           // FIX: initialised here
            rx_fifo_reg <= 32'h00000042;    // FIX: 'B' preloaded here
            control_reg <= 32'b0;           // FIX: initialised here
            AWREADY     <= 1'b0;
            WREADY      <= 1'b0;
            BVALID      <= 1'b0;
            BRESP       <= 2'b00;
        end else begin
            case (wstate)

                W_IDLE: begin
                    AWREADY <= 1'b0;
                    WREADY  <= 1'b0;
                    BVALID  <= 1'b0;
                    if (AWVALID && WVALID) begin
                        AWREADY   <= 1'b1;
                        WREADY    <= 1'b1;
                        waddr_reg <= AWADDR;
                        case (AWADDR[3:0])
                            4'h4: tx_fifo_reg <= WDATA;
                            4'hC: control_reg <= WDATA;
                            default: ;
                        endcase
                        wstate <= W_RESP;
                    end else if (AWVALID && !WVALID) begin
                        AWREADY   <= 1'b1;
                        waddr_reg <= AWADDR;
                        wstate    <= W_LATCH;
                    end
                end

                W_LATCH: begin
                    AWREADY <= 1'b0;
                    WREADY  <= 1'b0;
                    if (WVALID) begin
                        WREADY <= 1'b1;
                        case (waddr_reg[3:0])
                            4'h4: tx_fifo_reg <= WDATA;
                            4'hC: control_reg <= WDATA;
                            default: ;
                        endcase
                        wstate <= W_RESP;
                    end
                end

                W_RESP: begin
                    AWREADY <= 1'b0;
                    WREADY  <= 1'b0;
                    BVALID  <= 1'b1;
                    BRESP   <= 2'b00;
                    if (BVALID && BREADY) begin
                        BVALID <= 1'b0;
                        wstate <= W_IDLE;
                    end
                end

                default: wstate <= W_IDLE;
            endcase
        end
    end

    // ── Read FSM ──────────────────────────────────────────────────
    typedef enum logic [1:0] { R_IDLE=2'd0, R_RESP=2'd1 } rstate_t;
    rstate_t rstate;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rstate  <= R_IDLE;
            ARREADY <= 1'b0;
            RVALID  <= 1'b0;
            RDATA   <= 32'b0;
            RRESP   <= 2'b00;
        end else begin
            case (rstate)

                R_IDLE: begin
                    ARREADY <= 1'b0;
                    RVALID  <= 1'b0;
                    if (ARVALID) begin
                        ARREADY <= 1'b1;
                        case (ARADDR[3:0])
                            4'h0: RDATA <= rx_fifo_reg;
                            4'h8: RDATA <= STATUS_VAL;
                            default: RDATA <= 32'b0;
                        endcase
                        rstate <= R_RESP;
                    end
                end

                R_RESP: begin
                    ARREADY <= 1'b0;
                    RVALID  <= 1'b1;
                    RRESP   <= 2'b00;
                    if (RVALID && RREADY) begin
                        RVALID <= 1'b0;
                        rstate <= R_IDLE;
                    end
                end

                default: rstate <= R_IDLE;
            endcase
        end
    end

endmodule