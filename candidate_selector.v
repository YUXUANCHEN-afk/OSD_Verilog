`timescale 1ns / 1ps
module candidate_selector_fsm #(
  parameter integer K           = 32,
  parameter integer N           = 64, 
  parameter integer V_WIDTH     = 6,
  parameter integer SCORE_WIDTH = V_WIDTH + $clog2(N+1),
  // Total number = 1 bit + 2 bit
  parameter integer TOTAL       = (K + K*(K-1)/2)
)(
  input  wire                     clk,
  input  wire                     rst,   
  input  wire                     start,    
  input  wire [K*N-1:0]           G1_flat,   
  input  wire signed [V_WIDTH*N-1:0] v_flat, 
  input  wire [TOTAL*K-1:0]       candidates, 

  output reg                      valid_out,     
  output reg [K-1:0]             best_candidate, 
  output reg signed [SCORE_WIDTH-1:0] best_score 
);

  // 1) v_flat → v_array[0..N-1]
  wire signed [V_WIDTH-1:0] v_array [0:N-1];
  genvar gi;
  generate
    for (gi = 0; gi < N; gi = gi + 1) begin : UNPACK_V
      assign v_array[gi] = v_flat[(gi+1)*V_WIDTH-1 -: V_WIDTH];
    end
  endgenerate

  // 2)  u_array = G1 * v_array^T
  reg signed [SCORE_WIDTH-1:0] u_array [0:K-1];
  integer ii, jj;
  always @(*) begin
    for (ii = 0; ii < K; ii = ii + 1) begin
      u_array[ii] = 0;
      for (jj = 0; jj < N; jj = jj + 1) begin
        if (G1_flat[ii*N + jj])
          u_array[ii] = u_array[ii] + v_array[jj];
      end
    end
  end

  // 3) FSM do comparition
  localparam S_IDLE = 0, S_RUN = 1, S_DONE = 2;
  reg [1:0] state;
  reg [$clog2(TOTAL+1)-1:0] idx;
  reg [K-1:0] cand_buf;
  reg signed [SCORE_WIDTH-1:0] score_i;

  integer j;
  always @(posedge clk) begin
    if (rst) begin
      state          <= S_IDLE;
      idx            <= 0;
      best_score     <= -{ {(SCORE_WIDTH-1){1'b0}}, 1'b1 };
      best_candidate <= {K{1'b0}};
      valid_out      <= 1'b0;
    end else begin
      case (state)
        S_IDLE: begin
          if (start) begin
            state          <= S_RUN;
            idx            <= 0;
            best_score     <= -{ {(SCORE_WIDTH-1){1'b0}}, 1'b1 };
            valid_out      <= 1'b0;
          end
        end

        S_RUN: begin
          if (idx < TOTAL) begin
            // the idx th candidate a
            cand_buf = candidates[idx*K +: K];
            // Calculate the score with u_array : score = Σ (1-2*a[j]) * u_array[j]
            score_i = 0;
            for (j = 0; j < K; j = j + 1) begin
              score_i = score_i + (cand_buf[j] ? -u_array[j] : u_array[j]);
            end
            // update the best
            if (score_i > best_score) begin
              best_score     <= score_i;
              best_candidate <= cand_buf;
            end
            idx <= idx + 1;
          end else begin
            state     <= S_DONE;
            valid_out <= 1'b1;
          end
        end

        S_DONE: begin
          valid_out <= 1'b0;
          state     <= S_IDLE;
        end
      endcase
    end
  end

endmodule
