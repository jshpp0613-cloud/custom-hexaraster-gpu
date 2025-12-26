module gpu_system_q16 #(
    parameter BATCH = 10
)(
    input  logic         clk,
    input  logic         reset,

    input  logic         in_valid,
    input  logic [31:0]  vertex_x [0:BATCH-1], // Q16.16
    input  logic [31:0]  vertex_y [0:BATCH-1], // Q16.16
    input  logic [31:0]  vertex_z [0:BATCH-1], // Q16.16

    input  logic [31:0]  matrix [0:3][0:3],   // Q16.16
    input  logic [31:0]  hex_size_q16,        // Q16.16

    input  logic         frame_start,

    output logic [63:0]  mem [0:255],
    output logic [31:0]  mem_write_count
);

    // Vertex shader outputs
    logic [31:0] screen_x [0:BATCH-1];
    logic [31:0] screen_y [0:BATCH-1];
    logic [31:0] hex_q_f [0:BATCH-1];
    logic [31:0] hex_r_f [0:BATCH-1];
    logic [31:0] hex_s_f [0:BATCH-1];
    logic [7:0]  hex_lod [0:BATCH-1];
    logic        vs_valid;

    // Rasterizer outputs
    logic [15:0] q [0:BATCH-1];
    logic [15:0] r [0:BATCH-1];
    logic [7:0]  depth [0:BATCH-1];
    logic        rast_valid;

    // =========================
    // Vertex Shader
    // =========================
    vertex_shader_hex_q16 #(.BATCH(BATCH)) vs (
        .clk(clk),
        .reset(reset),
        .valid_in(in_valid),
        .x(vertex_x),
        .y(vertex_y),
        .z(vertex_z),
        .matrix(matrix),
        .hex_size_q16(hex_size_q16),
        .screen_x(screen_x),
        .screen_y(screen_y),
        .hex_q_f(hex_q_f),
        .hex_r_f(hex_r_f),
        .hex_s_f(hex_s_f),
        .hex_lod(hex_lod),
        .valid_out(vs_valid)
    );

    // =========================
    // Hex Rasterizer
    // =========================
    hexagonal_rasterizer_q16 #(.BATCH(BATCH)) hr (
        .clk(clk),
        .reset(reset),
        .valid_in(vs_valid),
        .q_f(hex_q_f),
        .r_f(hex_r_f),
        .s_f(hex_s_f),
        .q(q),
        .r(r),
        .depth(depth),
        .valid_out(rast_valid)
    );

    // =========================
    // Event Writer
    // =========================
    hex_event_writer #(.WIDTH(64), .DEPTH(256)) writer (
        .clk(clk),
        .reset(reset),
        .frame_start(frame_start),
        .valid_in(rast_valid),
        .q(q),
        .r(r),
        .depth_val(depth),
        .material(hex_lod),
        .mem(mem),
        .write_count(mem_write_count)
    );

endmodule
