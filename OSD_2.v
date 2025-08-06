`timescale 1ns / 1ps
module OSD_2_full_reenc_chd #(
  parameter integer N           = 64,
  parameter integer BIT_WIDTH   = 4,
  parameter integer IDX_W       = $clog2(N),
  parameter integer K           = 32,
  parameter integer TOTAL       = (K + (K*(K-1))/2),
  parameter integer V_WIDTH     = BIT_WIDTH,
  parameter integer SCORE_WIDTH = V_WIDTH + $clog2(K+1)
)(
  input  wire                   clk,
  input  wire                   rst,
  input  wire                   valid,
  input  wire [N*BIT_WIDTH-1:0] y,
  input  wire [K*N-1:0]         G_flat,

  output wire [N*BIT_WIDTH-1:0] sorted_y,
  output wire [N*IDX_W-1:0]     lambda1,
  output wire [N*IDX_W-1:0]     lambda2_flat,
  output wire [N*BIT_WIDTH-1:0] V_flat,
  output wire [N-1:0]           a_flat,
  output wire [K-1:0]           a1k_flat,
  output wire [TOTAL*K-1:0]     candidates,
  output wire [31:0]            candidate_count,

  output wire                   valid_out,
  output wire [K-1:0]           best_candidate,
  output wire signed [SCORE_WIDTH-1:0] best_score,

  output wire [N*IDX_W-1:0]     lambda1_inv_flat,
  output wire [N*IDX_W-1:0]     lambda2_inv_flat,
  output wire [N-1:0]           codeword_flat,
  output wire [N-1:0]           chd_flat      
);

  // 1) Bitonic soter
  wire sorter_done;
  bitonic_sorter_pipeline #(.N(N), .BIT_WIDTH(BIT_WIDTH), .INDEX_WIDTH(IDX_W)) u_sort (
    .clk    (clk), .rst(rst), .valid(valid),
    .y(y), .z(sorted_y), .lambda1(lambda1), .done(sorter_done)
  );

  // 2) Permuter
  wire [K*N-1:0] Gp_flat;
  permuter #(.N(N), .K(K), .IDX_W(IDX_W)) u_perm (
    .G_flat(G_flat), .lambda1(lambda1), .Gp_flat(Gp_flat)
  );

  // 3) Column Reorder: Generate λ2 & the second Permute
  wire [N*K-1:0] Gpp_flat;
  lambda2_generator #(.N(N), .K(K), .IDX_W(IDX_W)) u_l2 (
    .Gp_flat(Gp_flat), .Gpp_flat(Gpp_flat), .lambda2_flat(lambda2_flat)
  );

  // 4) Hard Decision
  va_Gen #(.N(N), .BIT_WIDTH(BIT_WIDTH), .IDX_W(IDX_W), .K(K)) u_va (
    .Z_flat(sorted_y), .lambda2_flat(lambda2_flat),
    .V_flat(V_flat), .a_flat(a_flat), .a1k_flat(a1k_flat)
  );

  // 5) Gaussian Eliminator
  wire ge_done_int;
  wire [K*N-1:0] G1_flat;
  GEtest1 #(.N(N), .K(K)) u_ge (
    .clk(clk), .rst(rst), .start(sorter_done),
    .Gpp_flat(Gpp_flat), .done(ge_done_int), .G1_flat(G1_flat)
  );

  // Flipping Control
  reg ge_d1, ge_d2;
  always @(posedge clk or posedge rst) begin
    if (rst) begin ge_d1<=0; ge_d2<=0; end
    else    begin ge_d1<=ge_done_int; ge_d2<=ge_d1; end
  end
  wire flip_start = ge_d1 & ~ge_d2;

  // 6) Flipping
  wire flip_done;
  flipping_component_top #(.K(K), .TOTAL(TOTAL)) u_flip (
    .clk(clk), .rst(rst), .start(flip_start),
    .a1k_flat(a1k_flat),
    .candidates(candidates), .candidate_count(candidate_count),
    .done(flip_done)
  );

  // 7) Selector
  candidate_selector_fsm #(
    .K(K), .TOTAL(TOTAL),
    .V_WIDTH(V_WIDTH), .SCORE_WIDTH(SCORE_WIDTH)
  ) u_sel (
    .clk(clk), .rst(rst), .start(flip_done),
    .candidates(candidates), .v_flat(V_flat),
    .valid_out(valid_out),
    .best_candidate(best_candidate),
    .best_score(best_score)
  );

  // 8) Depermuter: λ1⁻¹ / λ2⁻¹
  inverse_permutation #(.N(N), .WIDTH(IDX_W))
    u_inv1 (.lambda_flat(lambda1),      .lambda_inv_flat(lambda1_inv_flat));
  inverse_permutation #(.N(N), .WIDTH(IDX_W))
    u_inv2 (.lambda_flat(lambda2_flat), .lambda_inv_flat(lambda2_inv_flat));

  // 9) Re-encoder: best_candidate × G1 → codeword
  reencoder #(.K(K), .N(N))
    u_reenc (.best_candidate(best_candidate),
             .G1_flat(G1_flat),
             .codeword_flat(codeword_flat));

  // 10) Estimated codewords Calculator
  chd_cal #(.N(N), .W(IDX_W))
    u_chd (.codeword_flat     (codeword_flat),
           .lambda2_inv_flat  (lambda2_inv_flat),
           .lambda1_inv_flat  (lambda1_inv_flat),
           .chd_flat          (chd_flat));

endmodule
