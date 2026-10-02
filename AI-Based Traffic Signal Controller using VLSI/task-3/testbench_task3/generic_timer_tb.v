`timescale 1ns/1ps

module generic_timer_tb;

    reg clk;
    reg reset;
    reg start;

    reg [3:0] target_a;
    reg [4:0] target_b;
    reg [5:0] target_c;

    wire done_a;
    wire done_b;
    wire done_c;

    wire [3:0] count_a;
    wire [4:0] count_b;
    wire [5:0] count_c;

    integer errors;

    // --------------------------------------------------------
    // Three parameter configurations
    // --------------------------------------------------------

    generic_timer #(
        .COUNTER_WIDTH(4)
    ) timer_a (
        .clk(clk),
        .reset(reset),
        .start(start),
        .count_target(target_a),
        .done(done_a),
        .count(count_a)
    );

    generic_timer #(
        .COUNTER_WIDTH(5)
    ) timer_b (
        .clk(clk),
        .reset(reset),
        .start(start),
        .count_target(target_b),
        .done(done_b),
        .count(count_b)
    );

    generic_timer #(
        .COUNTER_WIDTH(6)
    ) timer_c (
        .clk(clk),
        .reset(reset),
        .start(start),
        .count_target(target_c),
        .done(done_c),
        .count(count_c)
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
    // Test
    // --------------------------------------------------------

    initial begin

        errors = 0;

        reset = 1'b1;
        start = 1'b0;

        target_a = 4'd3;
        target_b = 5'd5;
        target_c = 6'd8;

        repeat (2)
            @(posedge clk);

        reset = 1'b0;
        start = 1'b1;

        $display("");
        $display("==============================================");
        $display("GENERIC TIMER TEST");
        $display("==============================================");

        // ----------------------------------------------------
        // Wait until target values are reached
        // ----------------------------------------------------

        wait (done_a);
        #1;

        if (count_a != target_a) begin

            $display("ERROR: Timer A target mismatch");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Timer A reached target %0d", target_a);

        end

        wait (done_b);
        #1;

        if (count_b != target_b) begin

            $display("ERROR: Timer B target mismatch");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Timer B reached target %0d", target_b);

        end

        wait (done_c);
        #1;

        if (count_c != target_c) begin

            $display("ERROR: Timer C target mismatch");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Timer C reached target %0d", target_c);

        end

        // ----------------------------------------------------
        // Reset while running
        // ----------------------------------------------------

        target_a = 4'd6;

        @(posedge clk);
        @(posedge clk);

        reset = 1'b1;

        @(posedge clk);
        #1;

        if (count_a != 4'd0 ||
            done_a != 1'b0) begin

            $display("ERROR: Timer reset during counting failed");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Timer reset during counting");
            
        end

        reset = 1'b0;

        // ----------------------------------------------------
        // start = 0
        // ----------------------------------------------------

        start = 1'b0;

        @(posedge clk);
        #1;

        if (count_a != 4'd0 ||
            done_a != 1'b0) begin

            $display("ERROR: Timer did not clear when start=0");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Timer start/stop behavior");
            
        end

        // ----------------------------------------------------
        // count_target = 0
        // ----------------------------------------------------

        target_a = 4'd0;
        start = 1'b1;

        #1;

        if (done_a != 1'b1) begin

            $display("ERROR: Zero target did not assert done");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Zero target behavior");
            
        end

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");

        if (errors == 0)
            $display("PASS: generic_timer_tb completed with 0 errors");
        else
            $display("FAIL: generic_timer_tb found %0d errors", errors);

        $display("==============================================");

        $finish;

    end

endmodule