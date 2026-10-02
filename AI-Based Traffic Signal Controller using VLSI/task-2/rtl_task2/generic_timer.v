// Generic Reusable Timer
// Task 2 - Parameterized RTL Module Design

module generic_timer #(
    parameter integer COUNTER_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     start,
    input  wire [COUNTER_WIDTH-1:0] count_target,
    output reg                      done,
    output reg [COUNTER_WIDTH-1:0]  count
);

always @(posedge clk) begin

    if (reset) begin
        count <= {COUNTER_WIDTH{1'b0}};
        done  <= 1'b0;
    end

    else if (!start) begin
        count <= {COUNTER_WIDTH{1'b0}};
        done  <= 1'b0;
    end

    // A target of zero is treated as an immediately
    // completed timing interval.
    else if (count_target == {COUNTER_WIDTH{1'b0}}) begin
        count <= {COUNTER_WIDTH{1'b0}};
        done  <= 1'b1;
    end

    // Complete the timing interval after count_target
    // enabled clock cycles.
    else if (count >= (count_target - 1'b1)) begin
        count <= {COUNTER_WIDTH{1'b0}};
        done  <= 1'b1;
    end

    else begin
        count <= count + 1'b1;
        done  <= 1'b0;
    end

end

endmodule
