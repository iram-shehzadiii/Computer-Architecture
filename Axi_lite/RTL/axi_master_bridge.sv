module axi_master_bridge (
    input  logic        ACLK,
    input  logic        ARESETn,

    // Processor interface
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        wen,
    input  logic        ren,
    output logic [31:0] rdata,
    output logic        stall,

    // AXI Write Address Channel
    output logic [31:0] AWADDR,
    output logic        AWVALID,
    input  logic        AWREADY,

    // AXI Write Data Channel
    output logic [31:0] WDATA,
    output logic [3:0]  WSTRB,
    output logic        WVALID,
    input  logic        WREADY,

    // AXI Write Response Channel
    input  logic [1:0]  BRESP,
    input  logic        BVALID,
    output logic        BREADY,

    // AXI Read Address Channel
    output logic [31:0] ARADDR,
    output logic        ARVALID,
    input  logic        ARREADY,

    // AXI Read Data Channel
    input  logic [31:0] RDATA,
    input  logic [1:0]  RRESP,
    input  logic        RVALID,
    output logic        RREADY
);

    typedef enum logic [2:0] {
        IDLE    = 3'd0,
        WRITE   = 3'd1,
        WR_ADDR = 3'd2,
        WR_DATA = 3'd3,
        WR_RESP = 3'd4,
        RD_ADDR = 3'd5,
        RD_DATA = 3'd6
    } state_t;

    state_t state, next_state;

    logic [31:0] rdata_reg;
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            rdata_reg <= 32'b0;
        else if (state == RD_DATA && RVALID)
            rdata_reg <= RDATA;
    end

    assign rdata = rdata_reg;


    // ─────────────────────────────────────────────
    // STATE REGISTER
    // ─────────────────────────────────────────────
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ─────────────────────────────────────────────
    // NEXT STATE LOGIC
    // ─────────────────────────────────────────────
    always_comb begin
        next_state = state;

        case (state)

            IDLE: begin
                if (wen)       next_state = WRITE;
                else if (ren)  next_state = RD_ADDR;
            end

            WRITE: begin
                if (AWREADY && WREADY)
                    next_state = WR_RESP;
                else if (AWREADY)
                    next_state = WR_DATA;
                else if (WREADY)
                    next_state = WR_ADDR;
            end

            WR_ADDR: begin
                if (AWREADY && WREADY)
                    next_state = WR_RESP;
                else if (AWREADY)
                    next_state = WR_RESP;
            end

            WR_DATA: begin
                if (AWREADY && WREADY)
                    next_state = WR_RESP;
                else if (WREADY)
                    next_state = WR_RESP;
            end

            WR_RESP: begin
                if (BVALID)
                    next_state = IDLE;
            end

            RD_ADDR: begin
                if (ARREADY)
                    next_state = RD_DATA;
            end

            RD_DATA: begin
                if (RVALID)
                    next_state = IDLE;
            end

            default: next_state = IDLE;

        endcase
    end

    // ─────────────────────────────────────────────
    // OUTPUT LOGIC
    // ─────────────────────────────────────────────
    always_comb begin

        // defaults
        AWADDR  = 32'b0;
        AWVALID = 1'b0;
        WDATA   = 32'b0;
        WSTRB   = 4'b1111;
        WVALID  = 1'b0;
        BREADY  = 1'b0;

        ARADDR  = 32'b0;
        ARVALID = 1'b0;
        RREADY  = 1'b0;
        
        stall   = (state != IDLE);

        case (state)

            IDLE: begin
                // no AXI activity
            end

            WRITE: begin
                AWADDR  = addr;
                AWVALID = 1'b1;

                WDATA   = wdata;
                WSTRB   = 4'b1111;
                WVALID  = 1'b1;

                BREADY  = 1'b1;
            end

            WR_ADDR: begin
                AWADDR  = addr;
                AWVALID = 1'b1;
                BREADY  = 1'b1;
            end

            WR_DATA: begin
                WDATA   = wdata;
                WSTRB   = 4'b1111;
                WVALID  = 1'b1;
                BREADY  = 1'b1;
            end

            WR_RESP: begin
                BREADY = 1'b1;
            end

            RD_ADDR: begin
                ARADDR  = addr;
                ARVALID = 1'b1;
                RREADY  = 1'b1;
            end

            RD_DATA: begin
                RREADY = 1'b1;
            end

        endcase
    end

endmodule


