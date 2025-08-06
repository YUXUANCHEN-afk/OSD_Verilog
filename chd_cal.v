// File: chd_cal.v
`timescale 1ns / 1ps
module chd_cal #(
  parameter integer N     = 64,          
  parameter integer W     = $clog2(N)        
)(
  input  wire [N-1:0]       codeword_flat,       
  input  wire [N*W-1:0]     lambda2_inv_flat,   
  input  wire [N*W-1:0]     lambda1_inv_flat,   
  output wire [N-1:0]       chd_flat           
);

  genvar i;
  wire [W-1:0] lam2_arr [0:N-1];
  wire [W-1:0] lam1_arr [0:N-1];
  generate
    for (i = 0; i < N; i = i + 1) begin : UNPACK_LAM2
      assign lam2_arr[i] = lambda2_inv_flat[i*W +: W];
    end
    for (i = 0; i < N; i = i + 1) begin : UNPACK_LAM1
      assign lam1_arr[i] = lambda1_inv_flat[i*W +: W];
    end
  endgenerate

  //tmp[j] = codeword_flat[ lam2_arr[j] ]
  wire tmp [0:N-1];
  generate
    for (i = 0; i < N; i = i + 1) begin : APPLY_LAM2_INV
      assign tmp[i] = codeword_flat[ lam2_arr[i] ];
    end
  endgenerate

  //chd_flat[i] = tmp[ lam1_arr[i] ] —— 
  generate
    for (i = 0; i < N; i = i + 1) begin : APPLY_LAM1_INV
      assign chd_flat[i] = tmp[ lam1_arr[i] ];
    end
  endgenerate

endmodule
