    module gpu_system (
    input  logic        clk,
    input  logic        reset,

    // Input vertex (3D, fixed-point or IEEE float)
    input  logic [31:0] vertex_x,
    input  logic [31:0] vertex_y,
    input  logic [31:0] vertex_z,

    // 4x4 transform matrix (SystemVerilog)
    input  logic [31:0] matrix [0:3][0:3],

    // Hex grid scale
    input  logic [31:0] hex_size,

    // Hex axial coordinates output
    output logic [31:0] hex_q,
    output logic [31:0] hex_r,
    output logic        valid
);

    logic [31:0] screen_x, screen_y;
    logic        vs_valid;

    // =========================
    // Vertex Shader
    // =========================
    vertex_shader vs (
        .clk(clk),
        .reset(reset),
        .x(vertex_x),
        .y(vertex_y),
        .z(vertex_z),
        .matrix(matrix),
        .x_out(screen_x),
        .y_out(screen_y),
        .valid_out(vs_valid)
    );

    // =========================
    // Screen → Hex Mapper
    // =========================
    screen_to_hex hexmap (
        .clk(clk),
        .reset(reset),
        .valid_in(vs_valid),
        .x(screen_x),
        .y(screen_y),
        .hex_size(hex_size),
        .q(hex_q),
        .r(hex_r),
        .valid_out(valid)
    );

endmodule
