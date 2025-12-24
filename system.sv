// File: gpu_system.v
module gpu_system (
    input clk,
    input reset,
    input [31:0] vertex_x, vertex_y, vertex_z,   // Input vertex (3D)
    input [31:0] matrix[3:0][3:0],               // Transformation matrix for vertex shader
    input [31:0] hex_size,                       // Hexagon size for rasterizer
    output [31:0] hex_q, hex_r,                  // Hex coordinates output by rasterizer
    output valid                                 // Rasterizer output validity flag
);

    wire [31:0] screen_x, screen_y; // Vertex shader outputs

    // Instantiate Vertex Shader
    vertex_shader vs (
        .clk(clk),
        .reset(reset),
        .x(vertex_x),
        .y(vertex_y),
        .z(vertex_z),
        .matrix(matrix),
        .x_out(screen_x),
        .y_out(screen_y)
    );

    // Instantiate Hexagonal Rasterizer
    hexagonal_rasterizer hr (
        .clk(clk),
        .reset(reset),
        .v0_x(screen_x), .v0_y(screen_y),
        .v1_x(...), .v1_y(...), // Pass other triangle vertices
        .v2_x(...), .v2_y(...),
        .hex_size(hex_size),
        .hex_q(hex_q),
        .hex_r(hex_r),
        .valid(valid)
    );

endmodule
