`timescale 1ns/1ps

// ============================================================
// Parameterized Junction Controller
// Task 3 - System Integration
//
// Moore FSM traffic controller for one 4-way junction.
// The same module is reused for Junction A and Junction B.
// ============================================================

module junction_controller #(
    parameter integer GREEN_TIME      = 8,
    parameter integer YELLOW_TIME     = 2,
    parameter integer RED_TIME        = 2,
    parameter integer PED_TIME        = 3,
    parameter integer COUNTER_WIDTH   = 8,
    parameter integer USE_GREEN_WAVE  = 0
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    emergency_override,

    input  wire                    pedestrian_request,
    input  wire                    pedestrian_grant,

    input  wire                    green_wave_start,

    output reg                     ns_red,
    output reg                     ns_yellow,
    output reg                     ns_green,

    output reg                     ew_red,
    output reg                     ew_yellow,
    output reg                     ew_green,

    output reg                     pedestrian_active,

    output reg [2:0]               state_code,
    output reg [COUNTER_WIDTH-1:0] timer_target,

    output wire                    ped_pending,
    output wire                    ped_service_done
);

    // --------------------------------------------------------
    // FSM states
    // --------------------------------------------------------

    localparam [2:0] S_NS_GREEN      = 3'b000;
    localparam [2:0] S_NS_YELLOW     = 3'b001;
    localparam [2:0] S_ALL_RED_TO_EW = 3'b010;
    localparam [2:0] S_EW_GREEN      = 3'b011;
    localparam [2:0] S_EW_YELLOW     = 3'b100;
    localparam [2:0] S_ALL_RED_TO_NS = 3'b101;
    localparam [2:0] S_PEDESTRIAN    = 3'b110;

    // --------------------------------------------------------
    // FSM registers
    // --------------------------------------------------------

    reg [2:0] state;
    reg [2:0] next_state;

    // --------------------------------------------------------
    // Pedestrian registers
    // --------------------------------------------------------

    reg ped_request_latched;
    reg ped_request_previous;
    reg ped_return_to_ns;

    wire ped_request_rising;
    wire enter_pedestrian;

    // --------------------------------------------------------
    // Timer signals
    // --------------------------------------------------------

    wire timer_done;
    wire [COUNTER_WIDTH-1:0] timer_count;

    reg [COUNTER_WIDTH-1:0] timer_target_internal;

    wire timer_start;

    // Timer continuously operates while this controller is
    // active. The generic timer still remains a separate module.
    assign timer_start = 1'b1;

    // --------------------------------------------------------
    // Pedestrian request logic
    // --------------------------------------------------------

    assign ped_request_rising =
        pedestrian_request & ~ped_request_previous;

    assign ped_pending =
        ped_request_latched;

    assign ped_service_done =
        (state == S_PEDESTRIAN) &&
        timer_done;

    assign enter_pedestrian =
        ((state == S_ALL_RED_TO_EW) ||
         (state == S_ALL_RED_TO_NS)) &&
        (next_state == S_PEDESTRIAN);

    // --------------------------------------------------------
    // Generic Timer
    // --------------------------------------------------------

    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) phase_timer (
        .clk(clk),
        .reset(reset),
        .start(timer_start),
        .count_target(timer_target_internal),
        .done(timer_done),
        .count(timer_count)
    );

    // --------------------------------------------------------
    // Timer target for each FSM state
    // --------------------------------------------------------

    always @(*) begin

        case (state)

            S_NS_GREEN: begin
                timer_target_internal = GREEN_TIME;
            end

            S_NS_YELLOW: begin
                timer_target_internal = YELLOW_TIME;
            end

            S_ALL_RED_TO_EW: begin
                timer_target_internal = RED_TIME;
            end

            S_EW_GREEN: begin
                timer_target_internal = GREEN_TIME;
            end

            S_EW_YELLOW: begin
                timer_target_internal = YELLOW_TIME;
            end

            S_ALL_RED_TO_NS: begin
                timer_target_internal = RED_TIME;
            end

            S_PEDESTRIAN: begin
                timer_target_internal = PED_TIME;
            end

            default: begin
                timer_target_internal = RED_TIME;
            end

        endcase

    end

    // --------------------------------------------------------
    // Next-state logic
    // --------------------------------------------------------

    always @(*) begin

        // Safe default
        next_state = state;

        // Emergency has highest priority.
        if (emergency_override) begin

            next_state = S_ALL_RED_TO_NS;

        end
        else begin

            case (state)

                // --------------------------------------------
                // North-South Green
                // --------------------------------------------

                S_NS_GREEN: begin

                    if (timer_done) begin
                        next_state = S_NS_YELLOW;
                    end

                end

                // --------------------------------------------
                // North-South Yellow
                // --------------------------------------------

                S_NS_YELLOW: begin

                    if (timer_done) begin
                        next_state = S_ALL_RED_TO_EW;
                    end

                end

                // --------------------------------------------
                // All Red before East-West
                // --------------------------------------------

                S_ALL_RED_TO_EW: begin

                    if (timer_done) begin

                        if (ped_request_latched &&
                            pedestrian_grant) begin

                            next_state = S_PEDESTRIAN;

                        end
                        else begin

                            next_state = S_EW_GREEN;

                        end

                    end

                end

                // --------------------------------------------
                // East-West Green
                // --------------------------------------------

                S_EW_GREEN: begin

                    if (timer_done) begin
                        next_state = S_EW_YELLOW;
                    end

                end

                // --------------------------------------------
                // East-West Yellow
                // --------------------------------------------

                S_EW_YELLOW: begin

                    if (timer_done) begin
                        next_state = S_ALL_RED_TO_NS;
                    end

                end

                // --------------------------------------------
                // All Red before North-South
                // --------------------------------------------

                S_ALL_RED_TO_NS: begin

                    if (timer_done) begin

                        // Pedestrian request is serviced first
                        // at the safe all-red boundary.
                        if (ped_request_latched &&
                            pedestrian_grant) begin

                            next_state = S_PEDESTRIAN;

                        end

                        // Junction A can immediately restart
                        // its normal NS cycle.
                        else if (USE_GREEN_WAVE == 0) begin

                            next_state = S_NS_GREEN;

                        end

                        // Junction B waits for the green-wave
                        // coordination event.
                        else if (green_wave_start) begin

                            next_state = S_NS_GREEN;

                        end

                    end

                end

                // --------------------------------------------
                // Pedestrian phase
                // --------------------------------------------

                S_PEDESTRIAN: begin

                    if (timer_done) begin

                        if (ped_return_to_ns) begin
                            next_state = S_NS_GREEN;
                        end
                        else begin
                            next_state = S_EW_GREEN;
                        end

                    end

                end

                // --------------------------------------------
                // Safety recovery
                // --------------------------------------------

                default: begin
                    next_state = S_ALL_RED_TO_NS;
                end

            endcase

        end

    end

    // --------------------------------------------------------
    // Sequential logic
    // Synchronous active-high reset
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            state                 <= S_ALL_RED_TO_NS;

            ped_request_latched   <= 1'b0;
            ped_request_previous  <= 1'b0;

            ped_return_to_ns      <= 1'b1;

        end
        else begin

            state <= next_state;

            // Remember current pedestrian input for edge detection.
            ped_request_previous <= pedestrian_request;

            // During an emergency, discard pending pedestrian
            // service so the system returns cleanly to safety.
            if (emergency_override) begin

                ped_request_latched <= 1'b0;

            end
            else if (ped_request_rising) begin

                ped_request_latched <= 1'b1;

            end
            else if (ped_service_done) begin

                ped_request_latched <= 1'b0;

            end

            // Store the traffic direction from which the
            // pedestrian phase was entered.
            if (enter_pedestrian) begin

                if (state == S_ALL_RED_TO_NS) begin

                    ped_return_to_ns <= 1'b1;

                end
                else if (state == S_ALL_RED_TO_EW) begin

                    ped_return_to_ns <= 1'b0;

                end

            end

        end

    end

    // --------------------------------------------------------
    // Moore output logic
    // --------------------------------------------------------

    always @(*) begin

        // Safe defaults
        ns_red            = 1'b0;
        ns_yellow         = 1'b0;
        ns_green          = 1'b0;

        ew_red            = 1'b0;
        ew_yellow         = 1'b0;
        ew_green          = 1'b0;

        pedestrian_active = 1'b0;

        state_code        = state;
        timer_target      = timer_target_internal;

        case (state)

            // --------------------------------------------
            // NS Green
            // --------------------------------------------

            S_NS_GREEN: begin

                ns_green = 1'b1;
                ew_red   = 1'b1;

            end

            // --------------------------------------------
            // NS Yellow
            // --------------------------------------------

            S_NS_YELLOW: begin

                ns_yellow = 1'b1;
                ew_red    = 1'b1;

            end

            // --------------------------------------------
            // All Red
            // --------------------------------------------

            S_ALL_RED_TO_EW: begin

                ns_red = 1'b1;
                ew_red = 1'b1;

            end

            // --------------------------------------------
            // EW Green
            // --------------------------------------------

            S_EW_GREEN: begin

                ns_red   = 1'b1;
                ew_green = 1'b1;

            end

            // --------------------------------------------
            // EW Yellow
            // --------------------------------------------

            S_EW_YELLOW: begin

                ns_red    = 1'b1;
                ew_yellow = 1'b1;

            end

            // --------------------------------------------
            // All Red
            // --------------------------------------------

            S_ALL_RED_TO_NS: begin

                ns_red = 1'b1;
                ew_red = 1'b1;

            end

            // --------------------------------------------
            // Pedestrian
            // --------------------------------------------

            S_PEDESTRIAN: begin

                ns_red            = 1'b1;
                ew_red            = 1'b1;
                pedestrian_active = 1'b1;

            end

            // --------------------------------------------
            // Safety default
            // --------------------------------------------

            default: begin

                ns_red = 1'b1;
                ew_red = 1'b1;

            end

        endcase

    end

endmodule