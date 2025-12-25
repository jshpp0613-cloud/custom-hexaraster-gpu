module hex_to_screen_q16 (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,

    // Axial hex coords (integers)
    input  logic signed [31:0] q,
    input  logic signed [31:0] r,
    input  logic signed [31:0] s,   // should be -q-r

    // Config
    input  logic        pointy_top,
    input  logic signed [31:0] hex_size_q16, // Q16.16
    input  logic signed [31:0] cam_x_q16,
    input  logic signed [31:0] cam_y_q16,
    input  logic signed [31:0] zoom_q16,     // Q16.16

    input  logic        snap_to_center,

    // Screen output (Q16.16)
    output logic signed [31:0] screen_x_q16,
    output logic signed [31:0] screen_y_q16,
    output logic        valid_out
);

    // =========================
    // Q16.16 constants
    // =========================
    localparam int SQRT3_Q      = 32'd113512;
    localparam int THREE_DIV2_Q = 32'd98304;
    localparam int ONE_DIV2_Q   = 32'd32768;

    // =========================
    // Internal (wide for safety)
    // =========================
    logic signed [63:0] hx_tmp, hy_tmp;
    logic signed [31:0] hx_q16, hy_q16;
    logic signed [31:0] wx_q16, wy_q16;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
        end else if (valid_in) begin

            // =========================
            // Cube validation (debug)
            // =========================
            // synthesis translate_off
            assert(q + r + s == 0);
            // synthesis translate_on

            // =========================
            // Stage 1: Hex → local space
            // =========================
            if (pointy_top) begin
                // hx = size * √3 * (q + r/2)
                hx_tmp = (q <<< 16) + (r * ONE_DIV2_Q);
                hx_tmp = (hx_tmp * SQRT3_Q) >>> 16;
                hx_tmp = (hx_tmp * hex_size_q16) >>> 16;

                // hy = size * 3/2 * r
                hy_tmp = (r * THREE_DIV2_Q);
                hy_tmp = (hy_tmp * hex_size_q16) >>> 16;
            end else begin
                // hx = size * 3/2 * q
                hx_tmp = (q * THREE_DIV2_Q);
                hx_tmp = (hx_tmp * hex_size_q16) >>> 16;

                // hy = size * √3 * (r + q/2)
                hy_tmp = (r <<< 16) + (q * ONE_DIV2_Q);
                hy_tmp = (hy_tmp * SQRT3_Q) >>> 16;
                hy_tmp = (hy_tmp * hex_size_q16) >>> 16;
            end

            hx_q16 <= hx_tmp[31:0];
            hy_q16 <= hy_tmp[31:0];

            // =========================
            // Stage 2: Snapping
            // =========================
            wx_q16 <= hx_q16;
            wy_q16 <= hy_q16;

            // =========================
            // Stage 3: Camera transform
            // =========================
            screen_x_q16 <= ((wx_q16 - cam_x_q16) * zoom_q16) >>> 16;
            screen_y_q16 <= ((wy_q16 - cam_y_q16) * zoom_q16) >>> 16;

            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule
