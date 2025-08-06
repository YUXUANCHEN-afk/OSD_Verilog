`timescale 1ns / 1ps
module lambda2_generator #(
  parameter integer N     = 8,
  parameter integer K     = 4,
  parameter integer IDX_W = $clog2(N)
)(
  input  wire [K*N-1:0]     Gp_flat,    
  output reg  [K*N-1:0]     Gpp_flat,    
  output reg  [N*IDX_W-1:0] lambda2_flat  
);

  reg [K-1:0]     cols      [0:N-1];  
  reg [K-1:0]     basis     [0:K-1];
  reg [IDX_W-1:0] chosen    [0:K-1];
  reg [IDX_W-1:0] pivot_idx [0:K-1];
  reg             used      [0:N-1];
  reg [IDX_W-1:0] perm      [0:N-1];

  integer i, j, p, bit, idx;
  reg [K-1:0] cand;
  reg found;

  always @(*) begin
    for (i = 0; i < N; i = i + 1) begin
      for (j = 0; j < K; j = j + 1) begin
        cols[i][j] = Gp_flat[j*N + i];
      end
    end

    for (i = 0; i < N; i = i + 1)
      used[i] = 1'b0;
    for (p = 0; p < K; p = p + 1) begin
      basis[p]     = {K{1'b0}};
      chosen[p]    = {IDX_W{1'b0}};
      pivot_idx[p] = {IDX_W{1'b0}};
    end

    //  picking first K independent
    for (p = 0; p < K; p = p + 1) begin
      found = 1'b0;
      for (i = 0; i < N; i = i + 1) begin
        if (!used[i] && !found) begin
          cand = cols[i];
          // elimination
          for (j = 0; j < p; j = j + 1)
            if (cand[pivot_idx[j]])
              cand = cand ^ basis[j];
          if (cand != {K{1'b0}}) begin
            found        = 1'b1;
            basis[p]     = cand;
            chosen[p]    = i[IDX_W-1:0];
            used[i]      = 1'b1;
            // record pivot
            for (bit = K-1; bit >= 0; bit = bit - 1)
              if (cand[bit])
                pivot_idx[p] = bit[IDX_W-1:0];
          end
        end
      end
    end

    //  perm = [chosen0…chosenK-1, other coloum]
    idx = 0;
    for (p = 0; p < K; p = p + 1) begin
      perm[idx] = chosen[p];
      idx = idx + 1;
    end
    for (i = 0; i < N; i = i + 1) begin
      if (!used[i]) begin
        perm[idx] = i[IDX_W-1:0];
        idx = idx + 1;
      end
    end

    //output λ₂ and Gpp
    for (i = 0; i < N; i = i + 1) begin
      lambda2_flat[i*IDX_W +: IDX_W] = perm[i];
      for (j = 0; j < K; j = j + 1)
        Gpp_flat[j*N + i] = cols[ perm[i] ][j];
    end
  end

endmodule
