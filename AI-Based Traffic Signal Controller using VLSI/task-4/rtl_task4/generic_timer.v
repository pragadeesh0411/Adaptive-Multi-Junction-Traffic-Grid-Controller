`timescale 1ns/1ps

// ============================================================
// Generic Reusable Timer
// Task 2 / Task 3
// ============================================================

module generic_timer #(
    parameter integer COUNTER_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     start,
    input  wire [COUNTER_WIDTH-1:0] count_target,
    output wire                     done,
    output reg  [COUNTER_WIDTH-1:0] count
);

    // --------------------------------------------------------
    // Counter operation
    //
    // The timer counts from 0 to count_target.
    // When start is low, the counter returns to zero.
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            count <= {COUNTER_WIDTH{1'b0}};

        end
        else if (!start) begin

            count <= {COUNTER_WIDTH{1'b0}};

        end
        else if (count_target == {COUNTER_WIDTH{1'b0}}) begin

            count <= {COUNTER_WIDTH{1'b0}};

        end
        else if (count < count_target) begin

            count <= count + 1'b1;

        end
        else begin

            count <= count;

        end

    end

    // --------------------------------------------------------
    // Done indication
    //
    // For a zero target the timer is immediately complete.
    // --------------------------------------------------------

    assign done =
        start &&
        (
            (count_target == {COUNTER_WIDTH{1'b0}}) ||
            (count >= count_target)
        );

endmodule