module vertex_shader_hex_q16 (
    input  logic        clk,
    input  logic        reset,

    input  logic        valid_in,
    input  logic        ready_in,
    output logic        ready_out,

    // World position (Q16.16)
    input  logic signed [31:0] x_q16,
    input  logic signed [31:0] y_q16,
    input  logic signed [31:0] z_q16,

    // 4x4 transform (Q16.16)
    input  logic signed [31:0] matrix [0:3][0:3],

    // Hex size (Q16.16)
    input  logic signed [31:0] hex_size_q16,

    // Hex cube coords (Q16.16)
    output logic signed [31:0] q_f,
    output logic signed [31:0] r_f,
    output logic signed [31:0] s_f,

    output logic        valid_out
);

    // constants in Q16.16
    localparam signed [31:0] SQRT3_DIV_3 = 32'sd37837;  // √3/3
    localparam signed [31:0] ONE_DIV_3   = 32'sd21845;
    localparam signed [31:0] TWO_DIV_3   = 32'sd43691;

    logic signed [63:0] wx, wy;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
            ready_out <= 1'b1;
        end
        else if (valid_in && ready_in) begin
            // world → local
            wx <= matrix[0][0]*x_q16 + matrix[0][1]*y_q16 +
                  matrix[0][2]*z_q16 + matrix[0][3];
            wy <= matrix[1][0]*x_q16 + matrix[1][1]*y_q16 +
                  matrix[1][2]*z_q16 + matrix[1][3];

            // axial hex (pointy-top)
            q_f <= ((SQRT3_DIV_3 * wx - ONE_DIV_3 * wy) >>> 16) / hex_size_q16;
            r_f <= ((TWO_DIV_3 * wy) >>> 16) / hex_size_q16;
            s_f <= -(q_f + r_f);

            valid_out <= 1'b1;
            ready_out <= ready_in;
        end
        else begin
            valid_out <= 1'b0;
            ready_out <= ready_in;
        end
    end
endmodule
