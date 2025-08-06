`timescale 1ns / 1ps
module permuter #(
  parameter integer N     = 8,             
  parameter integer K     = 4,              
  parameter integer IDX_W = $clog2(N)
)(
  input  wire [K*N-1:0]         G_flat,     
  input  wire [N*IDX_W-1:0]     lambda1,    
  output wire [K*N-1:0]         Gp_flat       
);

  genvar r, c;
  generate
    for (r = 0; r < K; r = r + 1) begin : ROWS
      for (c = 0; c < N; c = c + 1) begin : COLS
        // orginal index
        wire [IDX_W-1:0] col = lambda1[c*IDX_W +: IDX_W];
        assign Gp_flat[r*N + c] = G_flat[r*N + col];
      end
    end
  endgenerate

endmodule
