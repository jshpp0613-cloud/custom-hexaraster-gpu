module hexagonal_rasterizer (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,

    // Fractional axial coordinates from vertex shader
    input  logic [31:0] q_f,
    input  logic [31:0] r_f,
    input  logic [31:0] s_f,   // = -q_f - r_f

    // Optional coverage radius (0 = single hex)
    input  logic [3:0]  radius,

    // Output integer axial hex
    output logic signed [31:0] q,
    output logic signed [31:0] r,

    output logic        valid_out
);

    // =========================
    // Internal registers
    // =========================
    logic signed [31:0] q_round, r_round, s_round;
    logic [31:0] dq, dr, ds;

    // Coverage stepping
    logic signed [31:0] q_cov, r_cov;
    logic [3:0]         cov_step;

    // =========================
    // Stage 1: Round components
    // =========================
    always_ff @(posedge clk) begin
        if (reset) begin
            q_round <= 0;
            r_round <= 0;
            s_round <= 0;
        end else if (valid_in) begin
            // Replace with proper FP rounding unit if needed
            q_round <= q_f;
            r_round <= r_f;
            s_round <= s_f;
        end
    end

    // =========================
    // Stage 2: Error computation
    // =========================
    always_ff @(posedge clk) begin
        if (reset) begin
            dq <= 0;
            dr <= 0;
            ds <= 0;
        end else if (valid_in) begin
            dq <= (q_round > q_f) ? (q_round - q_f) : (q_f - q_round);
            dr <= (r_round > r_f) ? (r_round - r_f) : (r_f - r_round);
            ds <= (s_round > s_f) ? (s_round - s_f) : (s_f - s_round);
        end
    end

    // =========================
    // Stage 3: Cube correction
    // =========================
    always_ff @(posedge clk) begin
        if (reset) begin
            q <= 0;
            r <= 0;
        end else if (valid_in) begin
            if (dq > dr && dq > ds) begin
                q <= -r_round - s_round;
                r <= r_round;
            end else if (dr > ds) begin
                q <= q_round;
                r <= -q_round - s_round;
            end else begin
                q <= q_round;
                r <= r_round;
            end
        end
    end

    // =========================
    // Stage 4: Coverage logic
    // =========================
    always_ff @(posedge clk) begin
        if (reset) begin
            q_cov     <= 0;
            r_cov     <= 0;
            cov_step  <= 0;
            valid_out <= 0;
        end else if (valid_in) begin
            if (radius == 0) begin
                q_cov     <= q;
                r_cov     <= r;
                valid_out <= 1'b1;
            end else begin
                // Simple axial ring walk (can be expanded)
                q_cov     <= q + cov_step;
                r_cov     <= r - cov_step;
                cov_step  <= cov_step + 1'b1;
                valid_out <= (cov_step <= radius);
            end
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
