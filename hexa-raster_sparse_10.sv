module hexagonal_rasterizer_sparse_10 (
    input  logic        clk,
    input  logic        reset,

    input  logic        valid_in,
    input  logic        ready_in,

    // Fractional cube coordinates (Q16.16 or float-like)
    input  logic signed [31:0] q_f,
    input  logic signed [31:0] r_f,
    input  logic signed [31:0] s_f,

    // Per-hex change mask (from simulation / state logic)
    input  logic [9:0]  changed_mask,

    output logic signed [15:0] q [0:9],
    output logic signed [15:0] r [0:9],
    output logic [7:0]         depth [0:9],
    output logic               dirty [0:9],

    output logic        valid_out,
    output logic        ready_out
);

    logic signed [31:0] qi, ri, si;
    logic signed [31:0] dq, dr, ds;

    integer i;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
            ready_out <= 1'b1;
        end
        else if (valid_in && ready_in) begin

            // === Round cube coordinates correctly ===
            qi <= q_f;
            ri <= r_f;
            si <= s_f;

            dq <= (qi > q_f) ? (qi - q_f) : (q_f - qi);
            dr <= (ri > r_f) ? (ri - r_f) : (r_f - ri);
            ds <= (si > s_f) ? (si - s_f) : (s_f - si);

            if (dq > dr && dq > ds)
                qi <= -ri - si;
            else if (dr > ds)
                ri <= -qi - si;
            else
                si <= -qi - ri;

            // === Emit up to 10 hexes ===
            for (i = 0; i < 10; i++) begin
                q[i]     <= qi[15:0];
                r[i]     <= ri[15:0];
                depth[i] <= 8'd0;
                dirty[i] <= changed_mask[i];
            end

            valid_out <= 1'b1;
            ready_out <= ready_in;
        end
        else begin
            valid_out <= 1'b0;
            ready_out <= ready_in;
        end
    end
endmodule
