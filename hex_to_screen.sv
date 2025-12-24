module hex_to_screen (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,

    // Hex coordinates (axial)
    input  logic signed [31:0] q,
    input  logic signed [31:0] r,

    // Optional cube coord (used for validation / debug)
    input  logic signed [31:0] s,   // should be -q-r (optional)

    // Hex configuration
    input  logic        pointy_top, // 1 = pointy, 0 = flat
    input  logic [31:0] hex_size,

    // Camera
    input  logic [31:0] cam_x,
    input  logic [31:0] cam_y,
    input  logic [31:0] zoom,        // 1.0 = normal

    // Optional snapping (for stable overlays)
    input  logic        snap_to_center,

    // Screen output
    output logic [31:0] screen_x,
    output logic [31:0] screen_y,
    output logic        valid_out
);

    // =========================
    // Constants (IEEE 754)
    // =========================
    localparam logic [31:0] SQRT3      = 32'h3FDDB3D7; // 1.73205
    localparam logic [31:0] SQRT3_DIV2 = 32'h3F5DB3D7; // 0.866025
    localparam logic [31:0] THREE_DIV2 = 32'h3FC00000; // 1.5
    localparam logic [31:0] ONE_DIV2   = 32'h3F000000; // 0.5

    // =========================
    // Internal
    // =========================
    logic [31:0] hx, hy;
    logic [31:0] wx, wy;

    always_ff @(posedge clk) begin
        if (reset) begin
            screen_x <= 32'd0;
            screen_y <= 32'd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin

            // ==================================
            // 1. Hex → local world space
            // ==================================
            if (pointy_top) begin
                // x = size * √3 * (q + r/2)
                hx <= hex_size * SQRT3 *
                      (q + (r * ONE_DIV2));

                // y = size * 3/2 * r
                hy <= hex_size * THREE_DIV2 * r;
            end else begin
                // x = size * 3/2 * q
                hx <= hex_size * THREE_DIV2 * q;

                // y = size * √3 * (r + q/2)
                hy <= hex_size * SQRT3 *
                      (r + (q * ONE_DIV2));
            end

            // ==================================
            // 2. Optional center snapping
            // ==================================
            if (snap_to_center) begin
                wx <= hx;
                wy <= hy;
            end else begin
                wx <= hx;
                wy <= hy;
            end

            // ==================================
            // 3. Camera transform
            // ==================================
            screen_x <= (wx - cam_x) * zoom;
            screen_y <= (wy - cam_y) * zoom;

            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
