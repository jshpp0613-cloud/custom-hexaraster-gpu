module hex_to_screen_q16_batch #(
    parameter BATCH = 10
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  valid_in,

    // Axial hex coords (integers)
    input  logic signed [15:0]    q [0:BATCH-1],
    input  logic signed [15:0]    r [0:BATCH-1],
    input  logic signed [15:0]    s [0:BATCH-1],

    // Config
    input  logic                  pointy_top,
    input  logic signed [31:0]   hex_size_q16, // Q16.16
    input  logic signed [31:0]   cam_x_q16,
    input  logic signed [31:0]   cam_y_q16,
    input  logic signed [31:0]   zoom_q16,     // Q16.16

    input  logic                  snap_to_center,

    // Screen output (Q16.16)
    output logic signed [31:0]   screen_x_q16 [0:BATCH-1],
    output logic signed [31:0]   screen_y_q16 [0:BATCH-1],
    output logic                  valid_out
);

    // Q16.16 constants
    localparam int SQRT3_Q      = 32'd113512;
    localparam int THREE_DIV2_Q = 32'd98304;
    localparam int ONE_DIV2_Q   = 32'd32768;

    integer i;
    logic signed [63:0] hx_tmp, hy_tmp;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 0;
        end else if (valid_in) begin
            for (i=0; i<BATCH; i=i+1) begin
                if (pointy_top) begin
                    hx_tmp = (q[i] <<< 16) + (r[i] * ONE_DIV2_Q);
                    hx_tmp = (hx_tmp * SQRT3_Q) >>> 16;
                    hx_tmp = (hx_tmp * hex_size_q16) >>> 16;

                    hy_tmp = (r[i] * THREE_DIV2_Q);
                    hy_tmp = (hy_tmp * hex_size_q16) >>> 16;
                end else begin
                    hx_tmp = (q[i] * THREE_DIV2_Q);
                    hx_tmp = (hx_tmp * hex_size_q16) >>> 16;

                    hy_tmp = (r[i] <<< 16) + (q[i] * ONE_DIV2_Q);
                    hy_tmp = (hy_tmp * SQRT3_Q) >>> 16;
                    hy_tmp = (hy_tmp * hex_size_q16) >>> 16;
                end

                // Camera transform
                screen_x_q16[i] <= ((hx_tmp[31:0] - cam_x_q16) * zoom_q16) >>> 16;
                screen_y_q16[i] <= ((hy_tmp[31:0] - cam_y_q16) * zoom_q16) >>> 16;
            end
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end

endmodule
