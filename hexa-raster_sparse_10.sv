module hexagonal_rasterizer_q16_correct #(
    parameter BATCH = 10
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  valid_in,

    // Q16.16 cube coordinates
    input  logic signed [31:0]    q_f [0:BATCH-1],
    input  logic signed [31:0]    r_f [0:BATCH-1],
    input  logic signed [31:0]    s_f [0:BATCH-1],

    output logic signed [15:0]    q [0:BATCH-1],
    output logic signed [15:0]    r [0:BATCH-1],
    output logic [7:0]            depth [0:BATCH-1],
    output logic                  valid_out
);

    integer i;

    // helpers
    logic signed [31:0] qi, ri, si;
    logic signed [31:0] dq, dr, ds;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 0;
        end else if (valid_in) begin
            for (i = 0; i < BATCH; i++) begin
                // -------------------------
                // Step 1: round Q16.16 → int
                // -------------------------
                qi = q_f[i] + 32'sh00008000; // +0.5
                ri = r_f[i] + 32'sh00008000;
                si = s_f[i] + 32'sh00008000;

                qi = qi >>> 16;
                ri = ri >>> 16;
                si = si >>> 16;

                // -------------------------
                // Step 2: error magnitudes
                // -------------------------
                dq = (qi <<< 16) - q_f[i];
                dr = (ri <<< 16) - r_f[i];
                ds = (si <<< 16) - s_f[i];

                if (dq < 0) dq = -dq;
                if (dr < 0) dr = -dr;
                if (ds < 0) ds = -ds;

                // -------------------------
                // Step 3: fix largest error
                // -------------------------
                if (dq > dr && dq > ds) begin
                    qi = -ri - si;
                end else if (dr > ds) begin
                    ri = -qi - si;
                end
                // else: si auto-fixed

                // -------------------------
                // Outputs
                // -------------------------
                q[i] <= qi[15:0];
                r[i] <= ri[15:0];
                depth[i] <= 8'd0;
            end
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end

endmodule
