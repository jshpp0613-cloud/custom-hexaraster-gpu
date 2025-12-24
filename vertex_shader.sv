module vertex_shader_hex (
    input  logic        clk,
    input  logic        reset,

    // Object-space vertex
    input  logic [31:0] x,
    input  logic [31:0] y,
    input  logic [31:0] z,

    // 4x4 transform matrix
    input  logic [31:0] matrix [0:3][0:3],

    // Hex parameters
    input  logic [31:0] hex_size,

    // Screen-space output
    output logic [31:0] screen_x,
    output logic [31:0] screen_y,

    // Hex metadata (for raster stage or culling)
    output logic [31:0] hex_q_est,
    output logic [31:0] hex_r_est,
    output logic [31:0] hex_s_est,   // cube coord: s = -q-r

    // Level-of-detail hint
    output logic [7:0]  hex_lod,

    output logic        valid_out
);

    // =========================
    // Constants (IEEE 754)
    // =========================
    localparam logic [31:0] SQRT3_DIV_3 = 32'h3F13CD3A; // 0.57735
    localparam logic [31:0] ONE_DIV_3   = 32'h3EAAAAAB; // 0.33333
    localparam logic [31:0] TWO_DIV_3   = 32'h3F2AAAAB; // 0.66666

    // =========================
    // Internal registers
    // =========================
    logic [31:0] world_x, world_y;
    logic [31:0] q_f, r_f;

    always_ff @(posedge clk) begin
        if (reset) begin
            screen_x  <= 32'd0;
            screen_y  <= 32'd0;
            hex_q_est <= 32'd0;
            hex_r_est <= 32'd0;
            hex_s_est <= 32'd0;
            hex_lod   <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            // ==================================
            // 1. World → Screen transform
            // ==================================
            world_x <= matrix[0][0] * x +
                       matrix[0][1] * y +
                       matrix[0][2] * z +
                       matrix[0][3];

            world_y <= matrix[1][0] * x +
                       matrix[1][1] * y +
                       matrix[1][2] * z +
                       matrix[1][3];

            screen_x <= world_x;
            screen_y <= world_y;

            // ==================================
            // 2. Screen → fractional axial hex
            // ==================================
            q_f <= (SQRT3_DIV_3 * world_x - ONE_DIV_3 * world_y) / hex_size;
            r_f <= (TWO_DIV_3 * world_y) / hex_size;

            // ==================================
            // 3. Hex stabilization (vertex-level)
            //    (prevents hex popping later)
            // ==================================
            // NOTE: This is NOT final rounding —
            // raster stage can still refine.
            hex_q_est <= q_f;
            hex_r_est <= r_f;
            hex_s_est <= -(q_f + r_f);

            // ==================================
            // 4. Hex-based LOD (distance heuristic)
            // ==================================
            // Farther hexes → lower detail
            if (world_x * world_x + world_y * world_y > 32'h4F000000)
                hex_lod <= 8'd3;
            else if (world_x * world_x + world_y * world_y > 32'h4E000000)
                hex_lod <= 8'd2;
            else
                hex_lod <= 8'd1;

            valid_out <= 1'b1;
        end
    end

endmodule
