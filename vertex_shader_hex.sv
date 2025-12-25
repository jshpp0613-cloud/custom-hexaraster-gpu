module vertex_shader_hex (
    input  logic        clk,
    input  logic        reset,

    // Handshake
    input  logic        valid_in,
    output logic        ready_out,
    input  logic        ready_in,

    // Inputs
    input  logic [31:0] x, y, z,
    input  logic [31:0] matrix [0:3][0:3],
    input  logic [31:0] hex_size,

    // Outputs (REGISTERED)
    output logic [31:0] screen_x,
    output logic [31:0] screen_y,
    output logic [31:0] hex_q_f,
    output logic [31:0] hex_r_f,
    output logic [31:0] hex_s_f,
    output logic [7:0]  hex_lod,
    output logic        valid_out
);

    // =========================
    // Constants (unchanged)
    // =========================
    localparam logic [31:0] SQRT3_DIV_3 = 32'h3F13CD3A;
    localparam logic [31:0] ONE_DIV_3   = 32'h3EAAAAAB;
    localparam logic [31:0] TWO_DIV_3   = 32'h3F2AAAAB;

    // =========================
    // Ready logic
    // =========================
    assign ready_out = !valid_out || ready_in;
    // Explanation:
    // - If we are empty, we can accept new input
    // - If downstream accepted our output, we can accept new input

    // =========================
    // Sequential logic
    // =========================
    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
        end
        else if (ready_out) begin
            // We are allowed to update our output register
            if (valid_in) begin
                // =========================
                // Matrix transform
                // =========================
                screen_x <= matrix[0][0]*x +
                            matrix[0][1]*y +
                            matrix[0][2]*z +
                            matrix[0][3];

                screen_y <= matrix[1][0]*x +
                            matrix[1][1]*y +
                            matrix[1][2]*z +
                            matrix[1][3];

                // =========================
                // Hex conversion
                // =========================
                hex_q_f <= (SQRT3_DIV_3 * screen_x -
                            ONE_DIV_3   * screen_y) / hex_size;

                hex_r_f <= (TWO_DIV_3 * screen_y) / hex_size;
                hex_s_f <= -(hex_q_f + hex_r_f);

                // =========================
                // LOD (placeholder)
                // =========================
                hex_lod <= ((screen_x * screen_x +
                             screen_y * screen_y) > 32'h4F000000)
                           ? 8'd3 : 8'd1;

                valid_out <= 1'b1;
            end else begin
                // No new input, clear valid
                valid_out <= 1'b0;
            end
        end
        // else: stalled → HOLD ALL REGISTERS
    end

endmodule
