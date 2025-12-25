module vertex_shader_hex (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,

    input  logic [31:0] x, y, z,
    input  logic [31:0] matrix [0:3][0:3],
    input  logic [31:0] hex_size,

    output logic [31:0] screen_x, screen_y,
    output logic [31:0] hex_q_f, hex_r_f, hex_s_f,
    output logic [7:0]  hex_lod,
    output logic        valid_out
);

    localparam logic [31:0] SQRT3_DIV_3 = 32'h3F13CD3A;
    localparam logic [31:0] ONE_DIV_3   = 32'h3EAAAAAB;
    localparam logic [31:0] TWO_DIV_3   = 32'h3F2AAAAB;

    logic [31:0] wx, wy;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
        end else if (valid_in) begin
            wx <= matrix[0][0]*x + matrix[0][1]*y + matrix[0][2]*z + matrix[0][3];
            wy <= matrix[1][0]*x + matrix[1][1]*y + matrix[1][2]*z + matrix[1][3];

            screen_x <= wx;
            screen_y <= wy;

            hex_q_f <= (SQRT3_DIV_3*wx - ONE_DIV_3*wy) / hex_size;
            hex_r_f <= (TWO_DIV_3*wy) / hex_size;
            hex_s_f <= -(hex_q_f + hex_r_f);

            hex_lod <= (wx*wx + wy*wy > 32'h4F000000) ? 8'd3 : 8'd1;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule
