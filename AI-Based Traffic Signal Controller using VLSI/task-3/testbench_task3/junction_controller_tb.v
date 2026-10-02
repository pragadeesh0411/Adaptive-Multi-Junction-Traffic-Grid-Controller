`timescale 1ns/1ps

module junction_controller_tb;

    localparam integer GREEN_A  = 4;
    localparam integer GREEN_B  = 6;
    localparam integer YELLOW   = 2;
    localparam integer RED      = 2;
    localparam integer PED      = 2;
    localparam integer WIDTH    = 4;

    localparam [2:0] S_NS_GREEN      = 3'b000;
    localparam [2:0] S_NS_YELLOW     = 3'b001;
    localparam [2:0] S_ALL_RED_TO_EW = 3'b010;
    localparam [2:0] S_EW_GREEN      = 3'b011;
    localparam [2:0] S_EW_YELLOW     = 3'b100;
    localparam [2:0] S_ALL_RED_TO_NS = 3'b101;
    localparam [2:0] S_PEDESTRIAN    = 3'b110;

    reg clk;
    reg reset;
    reg emergency_override;

    reg ped_request_a;
    reg ped_request_b;

    reg ped_grant_a;
    reg ped_grant_b;

    reg wave_a;
    reg wave_b;

    wire a_ns_red;
    wire a_ns_yellow;
    wire a_ns_green;

    wire a_ew_red;
    wire a_ew_yellow;
    wire a_ew_green;

    wire a_pedestrian_active;

    wire [2:0] a_state;
    wire [WIDTH-1:0] a_timer_target;

    wire a_ped_pending;
    wire a_ped_service_done;

    wire b_ns_red;
    wire b_ns_yellow;
    wire b_ns_green;

    wire b_ew_red;
    wire b_ew_yellow;
    wire b_ew_green;

    wire b_pedestrian_active;

    wire [2:0] b_state;
    wire [WIDTH-1:0] b_timer_target;

    wire b_ped_pending;
    wire b_ped_service_done;

    integer errors;

    // --------------------------------------------------------
    // Junction A
    // --------------------------------------------------------

    junction_controller #(
        .GREEN_TIME(GREEN_A),
        .YELLOW_TIME(YELLOW),
        .RED_TIME(RED),
        .PED_TIME(PED),
        .COUNTER_WIDTH(WIDTH),
        .USE_GREEN_WAVE(0)
    ) junction_a (
        .clk(clk),
        .reset(reset),
        .emergency_override(emergency_override),

        .pedestrian_request(ped_request_a),
        .pedestrian_grant(ped_grant_a),

        .green_wave_start(wave_a),

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
        .ped_service_done(a_ped_service_done)
    );

    // --------------------------------------------------------
    // Junction B
    // Same RTL, different GREEN_TIME
    // --------------------------------------------------------

    junction_controller #(
        .GREEN_TIME(GREEN_B),
        .YELLOW_TIME(YELLOW),
        .RED_TIME(RED),
        .PED_TIME(PED),
        .COUNTER_WIDTH(WIDTH),
        .USE_GREEN_WAVE(0)
    ) junction_b (
        .clk(clk),
        .reset(reset),
        .emergency_override(emergency_override),

        .pedestrian_request(ped_request_b),
        .pedestrian_grant(ped_grant_b),

        .green_wave_start(wave_b),

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
        .ped_service_done(b_ped_service_done)
    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    // --------------------------------------------------------
    // Safety monitor
    // --------------------------------------------------------

    always @(posedge clk) begin

        #1;

        if (!reset) begin

            if (a_ns_green && a_ew_green) begin
                $display("ERROR: A NS and EW green together");
                errors = errors + 1;
            end

            if (b_ns_green && b_ew_green) begin
                $display("ERROR: B NS and EW green together");
                errors = errors + 1;
            end

            if (a_pedestrian_active &&
                (!a_ns_red || !a_ew_red)) begin

                $display("ERROR: A pedestrian phase not all-red");
                errors = errors + 1;

            end

            if (b_pedestrian_active &&
                (!b_ns_red || !b_ew_red)) begin

                $display("ERROR: B pedestrian phase not all-red");
                errors = errors + 1;

            end

        end

    end

    // --------------------------------------------------------
    // Main test
    // --------------------------------------------------------

    initial begin

        errors = 0;

        reset = 1'b1;
        emergency_override = 1'b0;

        ped_request_a = 1'b0;
        ped_request_b = 1'b0;

        ped_grant_a = 1'b1;
        ped_grant_b = 1'b1;

        wave_a = 1'b0;
        wave_b = 1'b0;

        repeat (2)
            @(posedge clk);

        reset = 1'b0;

        // Wait for normal NS green.
        wait (a_state == S_NS_GREEN);
        #1;

        if (a_ns_green &&
            a_ew_red) begin

            $display("PASS: A NS green");

        end
        else begin

            $display("ERROR: A NS green outputs");
            errors = errors + 1;

        end

        // Complete normal sequence.
        wait (a_state == S_NS_YELLOW);

        if (!a_ns_yellow) begin
            $display("ERROR: A NS yellow");
            errors = errors + 1;
        end

        wait (a_state == S_ALL_RED_TO_EW);

        if (!a_ns_red || !a_ew_red) begin
            $display("ERROR: A all-red");
            errors = errors + 1;
        end

        wait (a_state == S_EW_GREEN);

        if (!a_ns_red || !a_ew_green) begin
            $display("ERROR: A EW green");
            errors = errors + 1;
        end

        wait (a_state == S_EW_YELLOW);

        if (!a_ns_red || !a_ew_yellow) begin
            $display("ERROR: A EW yellow");
            errors = errors + 1;
        end

        wait (a_state == S_ALL_RED_TO_NS);

        $display("PASS: A complete traffic sequence");

        // ----------------------------------------------------
        // Pedestrian request during yellow
        // ----------------------------------------------------

        wait (a_state == S_NS_YELLOW);

        ped_request_a = 1'b1;

        @(posedge clk);
        #1;

        ped_request_a = 1'b0;

        if (!a_ped_pending) begin

            $display("ERROR: Pedestrian request lost");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Pedestrian request latched");

        end

        wait (a_state == S_PEDESTRIAN);
        #1;

        if (!a_pedestrian_active ||
            !a_ns_red ||
            !a_ew_red) begin

            $display("ERROR: Pedestrian phase incorrect");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Pedestrian phase");
        end

        wait (a_state == S_EW_GREEN);
        #1;

        if (a_ped_pending) begin

            $display("ERROR: Pedestrian request not cleared");
            errors = errors + 1;

        end

        // ----------------------------------------------------
        // Emergency test
        // ----------------------------------------------------

        repeat (4)
            @(posedge clk);

        emergency_override = 1'b1;

        @(posedge clk);
        #1;

        if (!a_ns_red ||
            !a_ew_red ||
            !b_ns_red ||
            !b_ew_red) begin

            $display("ERROR: Emergency did not produce all-red");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Emergency all-red response");
        end

        emergency_override = 1'b0;

        repeat (8)
            @(posedge clk);

        // ----------------------------------------------------
        // Final
        // ----------------------------------------------------

        if (errors == 0)
            $display("PASS: junction_controller_tb completed with 0 errors");
        else
            $display("FAIL: junction_controller_tb found %0d errors", errors);

        $finish;

    end

endmodule