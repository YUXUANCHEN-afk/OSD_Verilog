`timescale 1ns / 1ps
module va_Gen #(
  parameter integer N         = 8,
  parameter integer BIT_WIDTH = 6,
  parameter integer IDX_W     = $clog2(N),
  parameter integer K         = 4
)(
  input  wire [N*BIT_WIDTH-1:0]      Z_flat,       
  input  wire [N*IDX_W-1:0]          lambda2_flat, 
  output wire [N*BIT_WIDTH-1:0]      V_flat,       
  output wire [N-1:0]                a_flat,       
  output wire [K-1:0]                a1k_flat    
);

  wire signed [BIT_WIDTH-1:0] Z [0:N-1];
  wire        [IDX_W-1:0]     L2[0:N-1];
  genvar i;
  generate
    for (i = 0; i < N; i = i + 1) begin : UNPACK
      assign Z[i]   = Z_flat[i*BIT_WIDTH +: BIT_WIDTH];
      assign L2[i]  = lambda2_flat[i*IDX_W   +: IDX_W];
    end
  endgenerate

  // reorder and hard decision
  genvar j;
  generate
    for (j = 0; j < N; j = j + 1) begin : COMPUTE
      wire signed [BIT_WIDTH-1:0] v = Z[ L2[j] ];
      assign V_flat[j*BIT_WIDTH +: BIT_WIDTH] = v;
      assign a_flat[j] = v[BIT_WIDTH-1];
    end
  endgenerate

  // first K
  generate
    for (j = 0; j < K; j = j + 1) begin : EXTRACT
      assign a1k_flat[j] = a_flat[j];
    end
  endgenerate

endmodule
