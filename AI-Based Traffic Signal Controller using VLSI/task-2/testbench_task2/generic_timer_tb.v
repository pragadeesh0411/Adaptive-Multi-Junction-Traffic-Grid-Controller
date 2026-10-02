`timescale 1ns/1ps

// Generic Timer Testbench
// Three different COUNTER_WIDTH configurations

module generic_timer_tb;

    reg clk;
    reg reset;
    reg start;

    reg [3:0] target_4;
    reg [4:0] target_5;
    reg [5:0] target_6;

    wire done_4;
    wire done_5;
    wire done_6;

    wire [3:0] count_4;
    wire [4:0] count_5;
    wire [5:0] count_6;

    integer cycle;
    integer errors;

    generic_timer #(
        .COUNTER_WIDTH(4)
    ) timer_4bit (
        .clk(clk),
        .reset(reset),
        .start(start),
        .count_target(target_4),
        .done(done_4),
        .count(count_4)
    );


    generic_timer #(
        .COUNTER_WIDTH(5)
    ) timer_5bit (
        .clk(clk),
        .reset(reset),
        .start(start),
        .count_target(target_5),
        .done(done_5),
        .count(count_5)
    );


    generic_timer #(
        .COUNTER_WIDTH(6)
    ) timer_6bit (
        .clk(clk),
        .reset(reset),
        .start(start),
        .count_target(target_6),
        .done(done_6),
        .count(count_6)
    );


    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin

        errors = 0;

        reset = 1'b1;
        start = 1'b0;

        target_4 = 4'd3;
        target_5 = 5'd5;
        target_6 = 6'd9;

        // Hold reset for two clock cycles
        repeat (2)
            @(posedge clk);

        reset = 1'b0;
        start = 1'b1;

        $display("");
        $display("============================");
        $display("GENERIC TIMER PARAMETER TEST");
        $display("============================");
        $display("Timer 1: WIDTH=4, TARGET=3");
        $display("Timer 2: WIDTH=5, TARGET=5");
        $display("Timer 3: WIDTH=6, TARGET=9");
        $display("");


        for (cycle = 1; cycle <= 9; cycle = cycle + 1) begin

            @(posedge clk);
            #1;

            $display("Cycle=%0d | C4=%0d D4=%b | C5=%0d D5=%b | C6=%0d D6=%b",
                     cycle,
                     count_4, done_4,
                     count_5, done_5,
                     count_6, done_6);

            // Timer 1 should finish exactly at cycle 3
            if (cycle == 3 && done_4 !== 1'b1) begin
                $display("ERROR: 4-bit timer did not assert done at target 3");
                errors = errors + 1;
            end

            if (cycle != 3 && done_4 === 1'b1) begin
                $display("ERROR: 4-bit timer asserted done at wrong cycle");
                errors = errors + 1;
            end

            // Timer 2 should finish exactly at cycle 5
            if (cycle == 5 && done_5 !== 1'b1) begin
                $display("ERROR: 5-bit timer did not assert done at target 5");
                errors = errors + 1;
            end

            if (cycle != 5 && done_5 === 1'b1) begin
                $display("ERROR: 5-bit timer asserted done at wrong cycle");
                errors = errors + 1;
            end

            // Timer 3 should finish exactly at cycle 9
            if (cycle == 9 && done_6 !== 1'b1) begin
                $display("ERROR: 6-bit timer did not assert done at target 9");
                errors = errors + 1;
            end

            if (cycle != 9 && done_6 === 1'b1) begin
                $display("ERROR: 6-bit timer asserted done at wrong cycle");
                errors = errors + 1;
            end

        end

        target_4 = 4'd6;

        @(posedge clk);
        #1;

        @(posedge clk);
        #1;

        reset = 1'b1;

        @(posedge clk);
        #1;

        if (count_4 !== 4'd0 || done_4 !== 1'b0) begin
            $display("ERROR: Timer did not reset correctly during counting");
            errors = errors + 1;
        end

        reset = 1'b0;

        start = 1'b0;

        @(posedge clk);
        #1;

        if (count_4 !== 4'd0 || done_4 !== 1'b0) begin
            $display("ERROR: Timer did not clear when start was low");
            errors = errors + 1;
        end


        target_4 = 4'd0;
        start = 1'b1;

        @(posedge clk);
        #1;

        if (done_4 !== 1'b1) begin
            $display("ERROR: count_target=0 did not produce immediate done");
            errors = errors + 1;
        end

        $display("");

        if (errors == 0)
            $display("PASS: generic_timer_tb completed with 0 errors");
        else
            $display("FAIL: generic_timer_tb found %0d errors", errors);

        $display("");

        $finish;

    end

endmodule
