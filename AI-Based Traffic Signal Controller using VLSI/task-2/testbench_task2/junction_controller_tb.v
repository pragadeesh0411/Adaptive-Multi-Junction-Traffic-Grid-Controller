`timescale 1ns/1ps

// ============================================================
// Junction Controller Testbench
// Two DUTs use the same RTL with different parameters.
// ============================================================

module junction_controller_tb;

    // --------------------------------------------------------
    // Test parameters
    // --------------------------------------------------------

    localparam integer A_GREEN_TIME  = 4;
    localparam integer A_YELLOW_TIME = 2;
    localparam integer A_RED_TIME    = 2;
    localparam integer A_PED_TIME    = 2;

    localparam integer B_GREEN_TIME  = 6;
    localparam integer B_YELLOW_TIME = 2;
    localparam integer B_RED_TIME    = 3;
    localparam integer B_PED_TIME    = 2;

    localparam integer COUNTER_WIDTH = 4;

    // --------------------------------------------------------
    // FSM state names for checking the DUT
    // --------------------------------------------------------

    localparam [2:0] S_NS_GREEN      = 3'd0;
    localparam [2:0] S_NS_YELLOW     = 3'd1;
    localparam [2:0] S_ALL_RED_TO_EW = 3'd2;
    localparam [2:0] S_EW_GREEN      = 3'd3;
    localparam [2:0] S_EW_YELLOW     = 3'd4;
    localparam [2:0] S_ALL_RED_TO_NS = 3'd5;
    localparam [2:0] S_PEDESTRIAN    = 3'd6;

    // --------------------------------------------------------
    // Common inputs
    // --------------------------------------------------------

    reg clk;
    reg reset;

    reg pedestrian_request_a;
    reg pedestrian_request_b;

    reg pedestrian_grant_a;
    reg pedestrian_grant_b;

    reg green_wave_start_a;
    reg green_wave_start_b;

    // --------------------------------------------------------
    // Junction A outputs
    // --------------------------------------------------------

    wire a_ns_red;
    wire a_ns_yellow;
    wire a_ns_green;

    wire a_ew_red;
    wire a_ew_yellow;
    wire a_ew_green;

    wire a_pedestrian_active;

    wire [2:0] a_state_code;

    wire [COUNTER_WIDTH-1:0] a_timer_target;

    wire a_ped_pending;
    wire a_ped_service_done;

    // --------------------------------------------------------
    // Junction B outputs
    // --------------------------------------------------------

    wire b_ns_red;
    wire b_ns_yellow;
    wire b_ns_green;

    wire b_ew_red;
    wire b_ew_yellow;
    wire b_ew_green;

    wire b_pedestrian_active;

    wire [2:0] b_state_code;

    wire [COUNTER_WIDTH-1:0] b_timer_target;

    wire b_ped_pending;
    wire b_ped_service_done;

    integer errors;
    integer i;

    // --------------------------------------------------------
    // Junction A instance
    // --------------------------------------------------------

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

        .pedestrian_request(pedestrian_request_a),
        .pedestrian_grant(pedestrian_grant_a),

        .green_wave_start(green_wave_start_a),

        .ns_red(a_ns_red),
        .ns_yellow(a_ns_yellow),
        .ns_green(a_ns_green),

        .ew_red(a_ew_red),
        .ew_yellow(a_ew_yellow),
        .ew_green(a_ew_green),

        .pedestrian_active(a_pedestrian_active),

        .state_code(a_state_code),
        .timer_target(a_timer_target),

        .ped_pending(a_ped_pending),
        .ped_service_done(a_ped_service_done)
    );

    // --------------------------------------------------------
    // Junction B instance
    // Same RTL, different parameters.
    // --------------------------------------------------------

    junction_controller #(
        .GREEN_TIME(B_GREEN_TIME),
        .YELLOW_TIME(B_YELLOW_TIME),
        .RED_TIME(B_RED_TIME),
        .PED_TIME(B_PED_TIME),
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .USE_GREEN_WAVE(0)
    ) junction_b (
        .clk(clk),
        .reset(reset),

        .pedestrian_request(pedestrian_request_b),
        .pedestrian_grant(pedestrian_grant_b),

        .green_wave_start(green_wave_start_b),

        .ns_red(b_ns_red),
        .ns_yellow(b_ns_yellow),
        .ns_green(b_ns_green),

        .ew_red(b_ew_red),
        .ew_yellow(b_ew_yellow),
        .ew_green(b_ew_green),

        .pedestrian_active(b_pedestrian_active),

        .state_code(b_state_code),
        .timer_target(b_timer_target),

        .ped_pending(b_ped_pending),
        .ped_service_done(b_ped_service_done)
    );

    // --------------------------------------------------------
    // Clock generation
    // --------------------------------------------------------

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end

    // --------------------------------------------------------
    // Basic safety monitor
    // --------------------------------------------------------

    always @(posedge clk) begin

        #1;

        if (!reset) begin

            if (a_ns_green && a_ew_green) begin
                $display("ERROR: Junction A has NS and EW green together");
                errors = errors + 1;
            end

            if (b_ns_green && b_ew_green) begin
                $display("ERROR: Junction B has NS and EW green together");
                errors = errors + 1;
            end

            if (a_pedestrian_active &&
                (!a_ns_red || !a_ew_red)) begin

                $display("ERROR: Junction A pedestrian phase is not all-red");
                errors = errors + 1;
            end

            if (b_pedestrian_active &&
                (!b_ns_red || !b_ew_red)) begin

                $display("ERROR: Junction B pedestrian phase is not all-red");
                errors = errors + 1;
            end

        end

    end

    // --------------------------------------------------------
    // Main test sequence
    // --------------------------------------------------------

    initial begin

        errors = 0;

        pedestrian_request_a = 1'b0;
        pedestrian_request_b = 1'b0;

        pedestrian_grant_a = 1'b1;
        pedestrian_grant_b = 1'b1;

        green_wave_start_a = 1'b0;
        green_wave_start_b = 1'b0;

        reset = 1'b1;

        $display("");
        $display("==============================================");
        $display("JUNCTION CONTROLLER TEST");
        $display("==============================================");

        // Reset
        repeat (2)
            @(posedge clk);

        reset = 1'b0;

        // ----------------------------------------------------
        // Check Junction A starts with all-red and then
        // enters NS green.
        // ----------------------------------------------------

        wait (a_state_code == S_NS_GREEN);
        #1;

        if (a_ns_green !== 1'b1 ||
            a_ew_red !== 1'b1 ||
            a_ns_yellow !== 1'b0 ||
            a_ew_green !== 1'b0) begin

            $display("ERROR: Junction A NS green outputs are incorrect");
            errors = errors + 1;

        end
        else begin
            $display("PASS: Junction A entered NS green");
        end

        // ----------------------------------------------------
        // Parameterization check for Junction A.
        // A uses GREEN_TIME = 4.
        // ----------------------------------------------------

        repeat (A_GREEN_TIME - 1)
            @(posedge clk);

        #1;

        if (a_state_code !== S_NS_GREEN) begin

            $display("ERROR: Junction A green phase changed too early");
            errors = errors + 1;

        end
        else begin
            $display("PASS: Junction A green timing matches parameter");
        end

        @(posedge clk);
        #1;

        if (a_state_code !== S_NS_YELLOW) begin

            $display("ERROR: Junction A did not move to NS yellow");
            errors = errors + 1;

        end
        else begin
            $display("PASS: Junction A NS green -> yellow");
        end

        // ----------------------------------------------------
        // Continue normal sequence.
        // ----------------------------------------------------

        wait (a_state_code == S_ALL_RED_TO_EW);
        #1;

        if (a_ns_red !== 1'b1 ||
            a_ew_red !== 1'b1) begin

            $display("ERROR: Junction A first all-red state incorrect");
            errors = errors + 1;

        end
        else begin
            $display("PASS: Junction A entered all-red");
        end

        wait (a_state_code == S_EW_GREEN);
        #1;

        if (a_ns_red !== 1'b1 ||
            a_ew_green !== 1'b1) begin

            $display("ERROR: Junction A EW green outputs incorrect");
            errors = errors + 1;

        end
        else begin
            $display("PASS: Junction A entered EW green");
        end

        wait (a_state_code == S_EW_YELLOW);
        #1;

        if (a_ew_yellow !== 1'b1 ||
            a_ns_red !== 1'b1) begin

            $display("ERROR: Junction A EW yellow outputs incorrect");
            errors = errors + 1;

        end
        else begin
            $display("PASS: Junction A EW green -> yellow");
        end

        wait (a_state_code == S_ALL_RED_TO_NS);
        #1;

        if (a_ns_red !== 1'b1 ||
            a_ew_red !== 1'b1) begin

            $display("ERROR: Junction A second all-red state incorrect");
            errors = errors + 1;

        end
        else begin
            $display("PASS: Junction A completed first traffic cycle");
        end

        // ----------------------------------------------------
        // Junction B parameterization check.
        // Same controller, different GREEN_TIME.
        // ----------------------------------------------------

        wait (b_state_code == S_NS_GREEN);
        #1;

        $display("PASS: Junction B entered NS green using same RTL");

        repeat (B_GREEN_TIME - 1)
            @(posedge clk);

        #1;

        if (b_state_code !== S_NS_GREEN) begin

            $display("ERROR: Junction B green phase changed too early");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Junction B green timing matches its parameter");

        end

        // ----------------------------------------------------
        // Pedestrian request during yellow.
        // Move A through another NS green phase.
        // ----------------------------------------------------

        wait (a_state_code == S_NS_GREEN);

        wait (a_state_code == S_NS_YELLOW);

        $display("Applying pedestrian request during NS yellow");

        pedestrian_request_a = 1'b1;

        @(posedge clk);
        #1;

        pedestrian_request_a = 1'b0;

        // Request must remain pending after the pulse.
        if (a_ped_pending !== 1'b1) begin

            $display("ERROR: Pedestrian request was lost during yellow");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Pedestrian request was latched during yellow");

        end

        // Wait for the safety all-red state.
        wait (a_state_code == S_ALL_RED_TO_EW);
        #1;

        if (a_ns_red !== 1'b1 ||
            a_ew_red !== 1'b1) begin

            $display("ERROR: Pedestrian service did not wait for all-red");
            errors = errors + 1;

        end

        // ----------------------------------------------------
        // Wait for pedestrian phase.
        // ----------------------------------------------------

        wait (a_state_code == S_PEDESTRIAN);
        #1;

        if (!a_pedestrian_active ||
            !a_ns_red ||
            !a_ew_red) begin

            $display("ERROR: Pedestrian phase outputs are incorrect");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Pedestrian phase inserted correctly");

        end

        // ----------------------------------------------------
        // Wait for service completion and confirm request
        // was cleared.
        // ----------------------------------------------------

        wait (a_state_code == S_EW_GREEN);
        #1;

        if (a_ped_pending !== 1'b0) begin

            $display("ERROR: Pedestrian request was not cleared");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Pedestrian request cleared after service");

        end

        // ----------------------------------------------------
        // Confirm there is no duplicate service while the
        // original request remains low.
        // ----------------------------------------------------

        for (i = 0; i < 12; i = i + 1) begin

            @(posedge clk);
            #1;

            if (a_state_code == S_PEDESTRIAN) begin

                $display("ERROR: Pedestrian request serviced more than once");
                errors = errors + 1;

            end

        end

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================================");

        if (errors == 0)
            $display("PASS: junction_controller_tb completed with 0 errors");
        else
            $display("FAIL: junction_controller_tb found %0d errors", errors);

        $display("==============================================");
        $display("");

        #20;
        $finish;

    end

endmodule