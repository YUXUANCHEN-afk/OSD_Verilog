`timescale 1ns / 1ps
module reencoder #(
  parameter integer K = 4,
  parameter integer N = 8
)(
  input  wire [K-1:0]      best_candidate,        // hard decisions a[0..K-1]
  input  wire [K*N-1:0]    G1_flat,   
  output wire [N-1:0]      codeword_flat  
);

  genvar i, j;
  generate
    for (i = 0; i < N; i = i + 1) begin : COL
      // for coloum i: c[i] = ⊕_j ( a[j] & G1[j,i] )
      wire [K-1:0] ands;
      for (j = 0; j < K; j = j + 1) begin : ROW
        assign ands[j] = best_candidate[j] & G1_flat[j*N + i];
      end
      assign codeword_flat[i] = ^ands;
    end
  endgenerate

endmodule
