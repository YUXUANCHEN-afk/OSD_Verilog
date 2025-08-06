`timescale 1ns / 1ps
module tb_OSD_2_with_reenc_chd_large;
  //—— 参数 ——//
  localparam integer N           = 64;
  localparam integer BIT_WIDTH   = 6;                    
  localparam integer IDX_W       = $clog2(N);            
  localparam integer K           = 32;
  localparam integer TOTAL       = (K + (K*(K-1))/2);     
  localparam integer V_WIDTH     = BIT_WIDTH;
  localparam integer SCORE_WIDTH = V_WIDTH + $clog2(K+1);  

  reg                       clk, rst, valid;
  reg  [N*BIT_WIDTH-1:0]    y;
  reg  [K*N-1:0]            G_flat;

  wire [N*BIT_WIDTH-1:0]    sorted_y;
  wire [N*IDX_W-1:0]        lambda1;
  wire [N*IDX_W-1:0]        lambda2_flat;
  wire [N*BIT_WIDTH-1:0]    V_flat;
  wire [N-1:0]              a_flat;
  wire [K-1:0]              a1k_flat;
  wire [(TOTAL*K)-1:0]      candidates;
  wire [31:0]               candidate_count;
  wire                      valid_out;
  wire [K-1:0]              best_candidate;
  wire signed [SCORE_WIDTH-1:0] best_score;
  wire [N*IDX_W-1:0]        lambda1_inv_flat;
  wire [N*IDX_W-1:0]        lambda2_inv_flat;
  wire [N-1:0]              codeword_flat;
  wire [N-1:0]              chd_flat;

  OSD_2_full_reenc_chd #(
    .N(N), .BIT_WIDTH(BIT_WIDTH), .IDX_W(IDX_W),
    .K(K), .TOTAL(TOTAL),
    .V_WIDTH(V_WIDTH), .SCORE_WIDTH(SCORE_WIDTH)
  ) dut (
    .clk              (clk),
    .rst              (rst),
    .valid            (valid),
    .y                (y),
    .G_flat           (G_flat),
    .sorted_y         (sorted_y),
    .lambda1          (lambda1),
    .lambda2_flat     (lambda2_flat),
    .V_flat           (V_flat),
    .a_flat           (a_flat),
    .a1k_flat         (a1k_flat),
    .candidates       (candidates),
    .candidate_count  (candidate_count),
    .valid_out        (valid_out),
    .best_candidate   (best_candidate),
    .best_score       (best_score),
    .lambda1_inv_flat (lambda1_inv_flat),
    .lambda2_inv_flat (lambda2_inv_flat),
    .codeword_flat    (codeword_flat),
    .chd_flat         (chd_flat)
  );

  integer i, j;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    //—— 1) random G_flat ——//
    rst   = 1;
    valid = 0;
    for (i = 0; i < K; i = i + 1)
      for (j = 0; j < N; j = j + 1)
        G_flat[i*N + j] = (j < K) ? (j==i) : ($random & 1);
    #20 rst = 0;

    //—— 2) Test: descending y ——//
    for (i = 0; i < N; i = i + 1)
      y[i*BIT_WIDTH +: BIT_WIDTH] = - (N - i);
    #10 valid = 1;
    #10 valid = 0;

    //—— 3) wait for selector  ——//
    wait(valid_out);

    $display("\n-- Large-Scale Test (N=%0d,K=%0d) --", N, K);
    $display("best_candidate  = %b", best_candidate);
    $display("best_score      = %0d", best_score);
    $display("lambda1_inv_flat= %b", lambda1_inv_flat);
    $display("lambda2_inv_flat= %b", lambda2_inv_flat);
    $display("codeword_flat   = %b", codeword_flat);
    $display("chd_flat        = %b", chd_flat);

    $finish;
  end

endmodule
