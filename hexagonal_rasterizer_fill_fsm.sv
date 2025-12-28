module hexagonal_rasterizer_fill_fsm #(
    parameter int RADIUS  = 2,
    parameter int MAX_OUT = 64
)(
    input  logic               clk,
    input  logic               reset,
    input  logic               valid_in,

    input  logic signed [15:0] q_center,
    input  logic signed [15:0] r_center,

    output logic signed [15:0] q_out,
    output logic signed [15:0] r_out,
    output logic [7:0]         depth,
    output logic               out_valid,
    output logic               busy
);

    // FSM state
    typedef enum logic [1:0] {
        IDLE,
        GEN,
        DONE
    } state_t;

    state_t state;

    // Loop variables (now REAL registers)
    logic signed [7:0] dq;
    logic signed [7:0] dr;
    logic [7:0]        out_count;

    // Bounds for dr depend on dq
    function automatic signed [7:0] dr_min(input signed [7:0] dq);
        dr_min = (dq < 0) ? (-RADIUS - dq) : (-RADIUS);
    endfunction

    function automatic signed [7:0] dr_max(input signed [7:0] dq);
        dr_max = (dq > 0) ? (RADIUS - dq) : (RADIUS);
    endfunction

    // FSM
    always_ff @(posedge clk) begin
        if (reset) begin
            state     <= IDLE;
            dq        <= 0;
            dr        <= 0;
            out_count <= 0;
            out_valid <= 0;
            busy      <= 0;
        end else begin
            out_valid <= 0;

            case (state)

                // -----------------
                // IDLE
                // -----------------
                IDLE: begin
                    busy <= 0;
                    if (valid_in) begin
                        dq        <= -RADIUS;
                        dr        <= dr_min(-RADIUS);
                        out_count <= 0;
                        busy      <= 1;
                        state     <= GEN;
                    end
                end

                // -----------------
                // GEN: emit 1 hex / cycle
                // -----------------
                GEN: begin
                    // Output current hex
                    q_out     <= q_center + dq;
                    r_out     <= r_center + dr;
                    depth     <= 8'd0;
                    out_valid <= 1;

                    out_count <= out_count + 1;

                    // Advance dr / dq
                    if (dr < dr_max(dq)) begin
                        dr <= dr + 1;
                    end else begin
                        dq <= dq + 1;
                        if (dq + 1 <= RADIUS)
                            dr <= dr_min(dq + 1);
                    end

                    // Done condition
                    if (dq == RADIUS && dr == dr_max(RADIUS)) begin
                        state <= DONE;
                    end
                end

                // -----------------
                // DONE
                // -----------------
                DONE: begin
                    busy  <= 0;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
