
`timescale 1ns/1ps

// ============================================================
// Adaptive Multi-Junction Traffic Grid Controller
// Task 3 - System Integration
// ============================================================

module amtgc_top #(
    // --------------------------------------------------------
    // Junction A parameters
    // --------------------------------------------------------

    parameter integer A_GREEN_TIME  = 6,
    parameter integer A_YELLOW_TIME = 2,
    parameter integer A_RED_TIME    = 2,
    parameter integer A_PED_TIME    = 2,

    // --------------------------------------------------------
    // Junction B parameters
    // --------------------------------------------------------

    parameter integer B_GREEN_TIME  = 6,
    parameter integer B_YELLOW_TIME = 2,
    parameter integer B_RED_TIME    = 2,
    parameter integer B_PED_TIME    = 3,

    // --------------------------------------------------------
    // Common parameters
    // --------------------------------------------------------

    parameter integer COUNTER_WIDTH    = 8,
    parameter integer GREEN_WAVE_DELAY = 1
)(
    // --------------------------------------------------------
    // System inputs
    // --------------------------------------------------------

    input wire clk,
    input wire reset,
    input wire emergency_override,

    // Pedestrian requests
    input wire a_pedestrian_request,
    input wire b_pedestrian_request,

    // --------------------------------------------------------
    // Junction A outputs
    // --------------------------------------------------------

    output wire a_ns_red,
    output wire a_ns_yellow,
    output wire a_ns_green,

    output wire a_ew_red,
    output wire a_ew_yellow,
    output wire a_ew_green,

    // --------------------------------------------------------
    // Junction B outputs
    // --------------------------------------------------------

    output wire b_ns_red,
    output wire b_ns_yellow,
    output wire b_ns_green,

    output wire b_ew_red,
    output wire b_ew_yellow,
    output wire b_ew_green,

    // --------------------------------------------------------
    // Pedestrian status
    // --------------------------------------------------------

    output wire a_pedestrian_active,
    output wire b_pedestrian_active,

    // --------------------------------------------------------
    // FSM state outputs
    // --------------------------------------------------------

    output wire [2:0] a_state,
    output wire [2:0] b_state,

    // --------------------------------------------------------
    // Timer target outputs
    // --------------------------------------------------------

    output wire [COUNTER_WIDTH-1:0] a_timer_target,
    output wire [COUNTER_WIDTH-1:0] b_timer_target,

    // --------------------------------------------------------
    // Pedestrian pending status
    // --------------------------------------------------------

    output wire a_ped_pending,
    output wire b_ped_pending,

    // --------------------------------------------------------
    // Arbiter grants
    // --------------------------------------------------------

    output wire ped_grant_a,
    output wire ped_grant_b,

    // --------------------------------------------------------
    // Green-wave status
    // --------------------------------------------------------

    output wire green_wave_start_b
);

    // --------------------------------------------------------
    // Internal pedestrian completion signals
    // --------------------------------------------------------

    wire ped_service_done_a;
    wire ped_service_done_b;

    wire priority_a_next;

    // ========================================================
    // Shared Pedestrian Arbiter
    // ========================================================

    ped_arbiter shared_ped_arbiter (
        .clk(clk),
        .reset(reset),

        .req_a(a_ped_pending),
        .req_b(b_ped_pending),

        .service_done_a(ped_service_done_a),
        .service_done_b(ped_service_done_b),

        .grant_a(ped_grant_a),
        .grant_b(ped_grant_b),

        .priority_a_next(priority_a_next)
    );

    // ========================================================
    // Green-Wave Coordinator
    // ========================================================

    green_wave_coordinator #(
        .GREEN_WAVE_DELAY(GREEN_WAVE_DELAY),
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) wave_coordinator (
        .clk(clk),
        .reset(reset),

        .source_ns_green(a_ns_green),

        .wave_start(green_wave_start_b)
    );

    // ========================================================
    // Junction A
    // ========================================================

    junction_controller #(
        .GREEN_TIME(A_GREEN_TIME),
        .YELLOW_TIME(A_YELLOW_TIME),
        .RED_TIME(A_RED_TIME),
        .PED_TIME(A_PED_TIME),
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .USE_GREEN_WAVE(0)
    ) junction_a (
        .clk(clk),
        .reset(reset),
        .emergency_override(emergency_override),

        .pedestrian_request(a_pedestrian_request),
        .pedestrian_grant(ped_grant_a),

        .green_wave_start(1'b0),

        .ns_red(a_ns_red),
        .ns_yellow(a_ns_yellow),
        .ns_green(a_ns_green),

        .ew_red(a_ew_red),
        .ew_yellow(a_ew_yellow),
        .ew_green(a_ew_green),

        .pedestrian_active(a_pedestrian_active),

        .state_code(a_state),
        .timer_target(a_timer_target),

        .ped_pending(a_ped_pending),
        .ped_service_done(ped_service_done_a)
    );

    // ========================================================
    // Junction B
    // Same RTL, different parameter set.
    // ========================================================

    junction_controller #(
        .GREEN_TIME(B_GREEN_TIME),
        .YELLOW_TIME(B_YELLOW_TIME),
        .RED_TIME(B_RED_TIME),
        .PED_TIME(B_PED_TIME),
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .USE_GREEN_WAVE(1)
    ) junction_b (
        .clk(clk),
        .reset(reset),
        .emergency_override(emergency_override),

        .pedestrian_request(b_pedestrian_request),
        .pedestrian_grant(ped_grant_b),

        .green_wave_start(green_wave_start_b),

        .ns_red(b_ns_red),
        .ns_yellow(b_ns_yellow),
        .ns_green(b_ns_green),

        .ew_red(b_ew_red),
        .ew_yellow(b_ew_yellow),
        .ew_green(b_ew_green),

        .pedestrian_active(b_pedestrian_active),

        .state_code(b_state),
        .timer_target(b_timer_target),

        .ped_pending(b_ped_pending),
        .ped_service_done(ped_service_done_b)
    );

endmodule