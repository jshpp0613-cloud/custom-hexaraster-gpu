module gpu_system (
    input  logic        clk,
    input  logic        reset,

    // Vertex input (from host)
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] vertex_x,
    input  logic [31:0] vertex_y,
    input  logic [31:0] vertex_z,

    // Transform + hex config
    input  logic [31:0] matrix [0:3][0:3],
    input  logic [31:0] hex_size_q16,

    // Frame control
    input  logic        frame_start,

    // Host memory interface
    output logic [31:0] mem_addr,
    output logic [63:0] mem_data,
    output logic        mem_we,
    input  logic        mem_ready,
    input  logic [31:0] buffer_base
);

    // =========================
    // Wires / regs
    // =========================
    logic [31:0] screen_x, screen_y;
    logic [31:0] q_f, r_f, s_f;
    logic [7:0]  lod;
    logic        vs_valid, rast_valid;

    logic signed [15:0] q, r;
    logic [7:0] depth;

    // Handshake
    logic vs_ready, rast_ready;

    // =========================
    // Vertex Shader (Hex-aware)
    // =========================
    vertex_shader_hex_fixed vs (
        .clk(clk),
        .reset(reset),
        .valid_in(in_valid),
        .ready_out(in_ready),
        .ready_in(vs_ready),
        .x(vertex_x),
        .y(vertex_y),
        .z(vertex_z),
        .matrix(matrix),
        .hex_size_q16(hex_size_q16),
        .screen_x_q16(screen_x),
        .screen_y_q16(screen_y),
        .hex_q_f_q16(q_f),
        .hex_r_f_q16(r_f),
        .hex_s_f_q16(s_f),
        .hex_lod(lod),
        .valid_out(vs_valid)
    );

    // =========================
    // Hex Rasterizer (stall-safe)
    // =========================
    hexagonal_rasterizer hr (
        .clk(clk),
        .reset(reset),
        .valid_in(vs_valid),
        .ready_in(rast_ready),
        .q_f(q_f),
        .r_f(r_f),
        .s_f(s_f),
        .radius(4'd0),
        .q(q),
        .r(r),
        .depth(depth),
        .valid_out(rast_valid),
        .ready_out(vs_ready) // propagate backpressure to shader
    );

    // =========================
    // Host-backed Output Writer
    // =========================
    hex_event_writer writer (
        .clk(clk),
        .reset(reset),
        .frame_start(frame_start),
        .valid_in(rast_valid),
        .ready_in(mem_ready), // stall if memory is busy
        .q(q),
        .r(r),
        .depth(depth),
        .material(8'd0),
        .mem_addr(mem_addr),
        .mem_data(mem_data),
        .mem_we(mem_we),
        .mem_ready(mem_ready),
        .buffer_base(buffer_base),
        .ready_out(rast_ready) // backpressure to rasterizer
    );

endmodule
