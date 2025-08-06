`timescale 1ns / 1ps

module flipping_component_top #(
    parameter integer K     = 8,
    // TOTAL = K + K*(K-1)/2
    parameter integer TOTAL = (K + (K*(K-1))/2)
)(
    input  wire               clk,        
    input  wire               rst,          
    input  wire               start,        
    input  wire [K-1:0]       a1k_flat,       

    output wire [(TOTAL*K)-1:0] candidates,    
    output wire [31:0]          candidate_count,
    output wire                done          
);

  wire internal_rst = rst | start;

  // 1-bit 
  wire [K-1:0] mask1;
  wire         done1;
  flipping_mask_generator_1bit #(.K(K)) gen1 (
    .clk       (clk),
    .rst       (internal_rst),
    .flip_mask (mask1),
    .done      (done1)
  );

  // 2-bit 
  wire [K-1:0] mask2;
  wire         done2;
  flipping_mask_generator_2bit #(.K(K)) gen2 (
    .clk       (clk),
    .rst       (internal_rst),
    .en        (done1),
    .flip_mask (mask2),
    .done      (done2)
  );

  // candidate = MRI ^ mask
  wire [K-1:0] cand1 = a1k_flat ^ mask1;
  wire [K-1:0] cand2 = a1k_flat ^ mask2;

  // 1-bit & 2-bit accumulate
  candidate_accumulator #(
    .K(K),
    .TOTAL(TOTAL)
  ) acc (
    .clk            (clk),
    .rst            (internal_rst),
    .candidate_1bit (cand1),
    .valid_1bit     (1'b1),
    .candidate_2bit (cand2),
    .valid_2bit     (done1),
    .done_2bit      (done2),
    .candidates     (candidates),
    .candidate_count(candidate_count),
    .done           (done)
  );

endmodule
