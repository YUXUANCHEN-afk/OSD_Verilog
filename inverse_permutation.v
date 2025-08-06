// inverse_permutation.v
`timescale 1ns / 1ps
module inverse_permutation #(
  parameter integer N      = 8,              
  parameter integer WIDTH  = $clog2(N)     
)(
  input  wire [N*WIDTH-1:0]     lambda_flat,    
  output wire [N*WIDTH-1:0]     lambda_inv_flat 
);

  wire [WIDTH-1:0] lam_arr [0:N-1];
  genvar i, j;
  generate
    for (i = 0; i < N; i = i + 1) begin : UNPACK_IN
      assign lam_arr[i] = lambda_flat[i*WIDTH +: WIDTH];
    end
  endgenerate

  generate
    for (i = 0; i < N; i = i + 1) begin : BUILD_INV
      wire [WIDTH-1:0] sel   [0:N-1];
      wire [WIDTH-1:0] or_stage [0:N];
      assign or_stage[0] = {WIDTH{1'b0}};
      for (j = 0; j < N; j = j + 1) begin : SEL_AND_OR
        assign sel[j]       = (lam_arr[j] == i[WIDTH-1:0])
                              ? j[WIDTH-1:0]
                              : {WIDTH{1'b0}};
        assign or_stage[j+1] = or_stage[j] | sel[j];
      end
      //  OR result is inv[i]
      assign lambda_inv_flat[i*WIDTH +: WIDTH] = or_stage[N];
    end
  endgenerate

endmodule
