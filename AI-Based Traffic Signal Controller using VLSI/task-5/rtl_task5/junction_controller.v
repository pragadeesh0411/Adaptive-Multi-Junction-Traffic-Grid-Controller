
// ============================================================
// AMTGC - Parameterized Junction Controller
// ============================================================

module junction_controller #(

    parameter integer GREEN_TIME                = 5,
    parameter integer GREEN_MIN_TIME            = 4,
    parameter integer GREEN_MAX_TIME            = 7,
    parameter integer GREEN_EXTENSION_PER_LEVEL = 1,

    parameter integer YELLOW_TIME               = 2,
    parameter integer RED_TIME                  = 2,
    parameter integer PED_TIME                  = 3,

    parameter integer COUNTER_WIDTH             = 16,

    parameter integer USE_ADAPTIVE              = 1,
    parameter integer USE_GREEN_WAVE            = 0

)(
    input  wire                     clk,
    input  wire                     reset,

    input  wire                     emergency_override,

    input  wire [2:0]               traffic_density,

    input  wire                     pedestrian_request,
    input  wire                     pedestrian_grant,

    input  wire                     green_wave_start,

    output reg                      ns_red,
    output reg                      ns_yellow,
    output reg                      ns_green,

    output reg                      ew_red,
    output reg                      ew_yellow,
    output reg                      ew_green,

    output reg                      pedestrian_active,

    output reg [2:0]                state_code,

    output reg [COUNTER_WIDTH-1:0]  timer_target,

    output wire                     ped_pending,
    output wire                     ped_service_done
);


// ============================================================
// STATE DEFINITIONS
// ============================================================

localparam [2:0] S_NS_GREEN      = 3'd0;
localparam [2:0] S_NS_YELLOW     = 3'd1;
localparam [2:0] S_ALL_RED_TO_EW = 3'd2;
localparam [2:0] S_EW_GREEN      = 3'd3;
localparam [2:0] S_EW_YELLOW     = 3'd4;
localparam [2:0] S_ALL_RED_TO_NS = 3'd5;
localparam [2:0] S_PEDESTRIAN    = 3'd6;


// ============================================================
// STATE REGISTERS
// ============================================================

reg [2:0] state_q;
reg [2:0] state_d;


// ============================================================
// PEDESTRIAN REGISTERS
// ============================================================

reg ped_request_latched;
reg ped_request_previous;

reg ped_return_to_ns;


// ============================================================
// GREEN WAVE
// ============================================================

reg wave_pending;


// ============================================================
// ADAPTIVE DENSITY
// ============================================================

reg [2:0] sampled_density;


// ============================================================
// TIMER
// ============================================================

wire [COUNTER_WIDTH-1:0] timer_count;
wire timer_done;
wire timer_start;

reg [COUNTER_WIDTH-1:0] timer_target_internal;


// ============================================================
// INTEGER CALCULATION
// ============================================================

integer green_calculation;


// ============================================================
// PEDESTRIAN REQUEST EDGE
// ============================================================

wire pedestrian_request_rise;

assign pedestrian_request_rise =
        pedestrian_request &
        ~ped_request_previous;


// ============================================================
// PEDESTRIAN OUTPUTS
// ============================================================

assign ped_pending =
        ped_request_latched;

assign ped_service_done =
        (state_q == S_PEDESTRIAN) &&
        timer_done;


// ============================================================
// TIMER START
//
// Timer runs while state remains unchanged.
// When state changes, timer resets.
// ============================================================

assign timer_start =
        (state_q == state_d) &&
        !emergency_override;


// ============================================================
// GENERIC TIMER INSTANCE
// ============================================================

generic_timer #(
    .COUNTER_WIDTH(COUNTER_WIDTH)
)
phase_timer (
    .clk(clk),
    .reset(reset),
    .start(timer_start),
    .count_target(timer_target_internal),
    .done(timer_done),
    .count(timer_count)
);


// ============================================================
// ADAPTIVE GREEN-TIME CALCULATION
//
// Density is sampled only at the beginning of a green phase.
// ============================================================

always @(*) begin

    green_calculation = GREEN_TIME;

    if (USE_ADAPTIVE != 0) begin

        green_calculation =
            GREEN_TIME +
            sampled_density * GREEN_EXTENSION_PER_LEVEL;

    end


    if (green_calculation < GREEN_MIN_TIME) begin

        green_calculation =
            GREEN_MIN_TIME;

    end
    else if (green_calculation > GREEN_MAX_TIME) begin

        green_calculation =
            GREEN_MAX_TIME;

    end

end


// ============================================================
// TIMER TARGET SELECTION
// ============================================================

always @(*) begin

    case (state_q)

        S_NS_GREEN: begin

            timer_target_internal =
                green_calculation;

        end

        S_NS_YELLOW: begin

            timer_target_internal =
                YELLOW_TIME;

        end

        S_ALL_RED_TO_EW: begin

            timer_target_internal =
                RED_TIME;

        end

        S_EW_GREEN: begin

            timer_target_internal =
                green_calculation;

        end

        S_EW_YELLOW: begin

            timer_target_internal =
                YELLOW_TIME;

        end

        S_ALL_RED_TO_NS: begin

            timer_target_internal =
                RED_TIME;

        end

        S_PEDESTRIAN: begin

            timer_target_internal =
                PED_TIME;

        end

        default: begin

            timer_target_internal =
                RED_TIME;

        end

    endcase

end


// ============================================================
// NEXT STATE LOGIC
// ============================================================

always @(*) begin

    state_d = state_q;


    // --------------------------------------------------------
    // Emergency override
    // --------------------------------------------------------

    if (emergency_override) begin

        state_d = S_ALL_RED_TO_NS;

    end

    else begin

        case (state_q)

            // ------------------------------------------------
            // NS GREEN
            // ------------------------------------------------

            S_NS_GREEN: begin

                if (timer_done)
                    state_d = S_NS_YELLOW;

            end


            // ------------------------------------------------
            // NS YELLOW
            // ------------------------------------------------

            S_NS_YELLOW: begin

                if (timer_done)
                    state_d = S_ALL_RED_TO_EW;

            end


            // ------------------------------------------------
            // ALL RED BEFORE EW
            // ------------------------------------------------

            S_ALL_RED_TO_EW: begin

                if (timer_done) begin

                    if (ped_request_latched &&
                        pedestrian_grant)

                        state_d = S_PEDESTRIAN;

                    else

                        state_d = S_EW_GREEN;

                end

            end


            // ------------------------------------------------
            // EW GREEN
            // ------------------------------------------------

            S_EW_GREEN: begin

                if (timer_done)
                    state_d = S_EW_YELLOW;

            end


            // ------------------------------------------------
            // EW YELLOW
            // ------------------------------------------------

            S_EW_YELLOW: begin

                if (timer_done)
                    state_d = S_ALL_RED_TO_NS;

            end


            // ------------------------------------------------
            // ALL RED BEFORE NS
            // ------------------------------------------------

            S_ALL_RED_TO_NS: begin

                if (timer_done) begin

                    if (ped_request_latched &&
                        pedestrian_grant) begin

                        state_d = S_PEDESTRIAN;

                    end

                    else if (USE_GREEN_WAVE != 0) begin

                        if (wave_pending ||
                            green_wave_start)

                            state_d = S_NS_GREEN;

                    end

                    else begin

                        state_d = S_NS_GREEN;

                    end

                end

            end


            // ------------------------------------------------
            // PEDESTRIAN
            // ------------------------------------------------

            S_PEDESTRIAN: begin

                if (timer_done) begin

                    if (ped_return_to_ns)

                        state_d = S_NS_GREEN;

                    else

                        state_d = S_EW_GREEN;

                end

            end


            // ------------------------------------------------
            // DEFAULT
            // ------------------------------------------------

            default: begin

                state_d =
                    S_ALL_RED_TO_NS;

            end

        endcase

    end

end


// ============================================================
// SEQUENTIAL LOGIC
// ============================================================

always @(posedge clk) begin

    if (reset) begin

        state_q <= S_ALL_RED_TO_NS;

        ped_request_latched  <= 1'b0;
        ped_request_previous <= 1'b0;

        ped_return_to_ns <= 1'b1;

        wave_pending <= 1'b0;

        sampled_density <= 3'd0;

    end

    else begin

        state_q <= state_d;

        ped_request_previous <=
            pedestrian_request;


        // ----------------------------------------------------
        // Pedestrian request latch
        // ----------------------------------------------------

        if (emergency_override) begin

            ped_request_latched <= 1'b0;

        end
        else if (pedestrian_request_rise) begin

            ped_request_latched <= 1'b1;

        end
        else if (ped_service_done) begin

            ped_request_latched <= 1'b0;

        end


        // ----------------------------------------------------
        // Remember which traffic direction was interrupted
        // ----------------------------------------------------

        if ((state_q == S_ALL_RED_TO_NS) &&
            (state_d == S_PEDESTRIAN)) begin

            ped_return_to_ns <= 1'b1;

        end
        else if ((state_q == S_ALL_RED_TO_EW) &&
                 (state_d == S_PEDESTRIAN)) begin

            ped_return_to_ns <= 1'b0;

        end


        // ----------------------------------------------------
        // Green-wave pending signal
        // ----------------------------------------------------

        if (emergency_override) begin

            wave_pending <= 1'b0;

        end
        else if (state_q != S_ALL_RED_TO_NS) begin

            wave_pending <= 1'b0;

        end
        else begin

            if (green_wave_start)

                wave_pending <= 1'b1;

            if (state_d == S_NS_GREEN)

                wave_pending <= 1'b0;

        end


        // ----------------------------------------------------
        // Density sampling
        //
        // Only sample at green-phase entry.
        // ----------------------------------------------------

        if ((state_q != S_NS_GREEN) &&
            (state_d == S_NS_GREEN)) begin

            sampled_density <=
                traffic_density;

        end
        else if ((state_q != S_EW_GREEN) &&
                 (state_d == S_EW_GREEN)) begin

            sampled_density <=
                traffic_density;

        end

    end

end


// ============================================================
// MOORE OUTPUT LOGIC
// ============================================================

always @(*) begin

    ns_red    = 1'b0;
    ns_yellow = 1'b0;
    ns_green  = 1'b0;

    ew_red    = 1'b0;
    ew_yellow = 1'b0;
    ew_green  = 1'b0;

    pedestrian_active = 1'b0;

    state_code = state_q;

    timer_target =
        timer_target_internal;


    case (state_q)

        // ----------------------------------------------------
        // NS GREEN
        // ----------------------------------------------------

        S_NS_GREEN: begin

            ns_green = 1'b1;
            ew_red   = 1'b1;

        end


        // ----------------------------------------------------
        // NS YELLOW
        // ----------------------------------------------------

        S_NS_YELLOW: begin

            ns_yellow = 1'b1;
            ew_red    = 1'b1;

        end


        // ----------------------------------------------------
        // ALL RED TO EW
        // ----------------------------------------------------

        S_ALL_RED_TO_EW: begin

            ns_red = 1'b1;
            ew_red = 1'b1;

        end


        // ----------------------------------------------------
        // EW GREEN
        // ----------------------------------------------------

        S_EW_GREEN: begin

            ns_red   = 1'b1;
            ew_green = 1'b1;

        end


        // ----------------------------------------------------
        // EW YELLOW
        // ----------------------------------------------------

        S_EW_YELLOW: begin

            ns_red    = 1'b1;
            ew_yellow = 1'b1;

        end


        // ----------------------------------------------------
        // ALL RED TO NS
        // ----------------------------------------------------

        S_ALL_RED_TO_NS: begin

            ns_red = 1'b1;
            ew_red = 1'b1;

        end


        // ----------------------------------------------------
        // PEDESTRIAN
        // ----------------------------------------------------

        S_PEDESTRIAN: begin

            ns_red = 1'b1;
            ew_red = 1'b1;

            pedestrian_active =
                1'b1;

        end


        // ----------------------------------------------------
        // DEFAULT
        // ----------------------------------------------------

        default: begin

            ns_red = 1'b1;
            ew_red = 1'b1;

        end

    endcase

end

endmodule