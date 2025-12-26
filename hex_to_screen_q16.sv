module hex_to_screen_q16 (
    input  logic        clk,
    input  logic        reset,

    input  logic        valid_in,
    input  logic        ready_in,
    output logic        ready_out,

    // Hex axial (Q16.16)
    input  logic signed [31:0] q_f,
    input  logic signed [31:0] r_f,

    // Config
    input  logic signed [31:0] hex_size_q16,
    input  logic signed [31:0] cam_x_q16,
    input  logic signed [31:0] cam_y_q16,
    input  logic signed [31:0] zoom_q16,

    // Screen (Q16.16)
    output logic signed [31:0] screen_x_q16,
    output logic signed [31:0] screen_y_q16,

    output logic        valid_out
);

    localparam signed [31:0] SQRT3 = 32'sd113512; // √3 Q16.16
    localparam signed [31:0] THREE_DIV_2 = 32'sd98304;

    logic signed [63:0] hx, hy;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
            ready_out <= 1'b1;
        end
        else if (valid_in && ready_in) begin
            // hex → local
            hx <= (SQRT3 * (q_f + (r_f >>> 1))) >>> 16;
            hy <= (THREE_DIV_2 * r_f) >>> 16;

            hx <= (hx * hex_size_q16) >>> 16;
            hy <= (hy * hex_size_q16) >>> 16;

            // camera + zoom
            screen_x_q16 <= ((hx - cam_x_q16) * zoom_q16) >>> 16;
            screen_y_q16 <= ((hy - cam_y_q16) * zoom_q16) >>> 16;

            valid_out <= 1'b1;
            ready_out <= ready_in;
        end
        else begin
            valid_out <= 1'b0;
            ready_out <= ready_in;
        end
    end
endmodule
