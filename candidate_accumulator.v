`timescale 1ns/1ps
module candidate_accumulator #(
    parameter K = 8,
    parameter TOTAL = (K + (K*(K-1))/2)
)(
    input clk,
    input rst,
    // 1-bit candidate inputs
    input [K-1:0] candidate_1bit,
    input valid_1bit,
    // 2-bit candidate inputs
    input [K-1:0] candidate_2bit,
    input valid_2bit,
    input done_2bit,  // 2bit done
    // output the flat data, each K means a candidate
    output reg [(TOTAL*K)-1:0] candidates,
    // number of candidates
    output reg [31:0] candidate_count,
    // done
    output reg done
);

    // for state machine, do 2bit after 1 bit done
    localparam STATE_ACC_1BIT = 0, STATE_ACC_2BIT = 1, STATE_DONE = 2;
    reg [1:0] state;
    reg [31:0] index;  // numbers of candidates stored "now"

always @(posedge clk or posedge rst) begin
  if (rst) begin
    state           <= STATE_ACC_1BIT;
    index           <= 0;
    candidate_count <= 0;
    candidates      <= {(TOTAL*K){1'b0}};
    done            <= 1'b0;
  end else begin
    case (state)
      STATE_ACC_1BIT: begin
        // only do 1 bit when index < K 
        if (valid_1bit && index < K) begin
          candidates[((index+1)*K)-1 -: K] <= candidate_1bit;
          index <= index + 1;
        end
        // if next index would be K，go to 2 bit
        if (index + 1 == K) begin
          state <= STATE_ACC_2BIT;
        end
      end

      STATE_ACC_2BIT: begin
        if (valid_2bit) begin
          candidates[((index+1)*K)-1 -: K] <= candidate_2bit;
          index <= index + 1;
        end
        if (done_2bit) begin
          candidate_count <= index;
          state <= STATE_DONE;
        end
      end

      STATE_DONE: done <= 1'b1;
    endcase
  end
end

endmodule
