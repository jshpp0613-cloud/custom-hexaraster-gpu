module hexagonal_rasterizer (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,

    input  logic [31:0] q_f, r_f, s_f,
    input  logic [3:0]  radius,

    output logic signed [15:0] q,
    output logic signed [15:0] r,
    output logic [7:0]  depth,
    output logic        valid_out
);

    logic signed [31:0] qr, rr, sr;
    logic [31:0] dq, dr, ds;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
        end else if (valid_in) begin
            qr <= q_f;
            rr <= r_f;
            sr <= s_f;

            dq <= (qr > q_f) ? (qr - q_f) : (q_f - qr);
            dr <= (rr > r_f) ? (rr - r_f) : (r_f - rr);
            ds <= (sr > s_f) ? (sr - s_f) : (s_f - sr);

            if (dq > dr && dq > ds) begin
                q <= -rr - sr;
                r <= rr;
            end else if (dr > ds) begin
                q <= qr;
                r <= -qr - sr;
            end else begin
                q <= qr;
                r <= rr;
            end

            depth <= 8'd0;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule
