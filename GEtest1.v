`timescale 1ns / 1ps
module GEtest1 #(
  parameter integer N = 8,  
  parameter integer K = 4  
)(
  input  wire           clk,
  input  wire           rst,
  input  wire           start,
  input  wire [K*N-1:0] Gpp_flat, 
  output reg            done,
  output reg [K*N-1:0]  G1_flat     
);

  // FSM
  localparam IDLE=0, LOAD=1, FIND=2, SWAP=3, ELIM=4, NEXT=5, DONE=6;
  reg [2:0] state, next_state;

  // Internal matrix
  reg [N-1:0] mat[0:K-1], temp;
  reg [$clog2(K)-1:0] piv, sidx, erow;
  integer i, j;

  always @(*) begin
    next_state = state;
    case(state)
      IDLE: if(start)       next_state = LOAD;
      LOAD:                  next_state = FIND;
      FIND: if(mat[piv][piv]) next_state=ELIM;
            else if(piv+sidx+1<K && mat[piv+sidx+1][piv]) next_state=SWAP;
            else               next_state=NEXT;
      SWAP:                  next_state=ELIM;
      ELIM: if(erow==K-1)    next_state=NEXT;
      NEXT: if(piv<K-1)      next_state=FIND;
            else              next_state=DONE;
      DONE:                  next_state=DONE;
    endcase
  end

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      state<=IDLE; done<=0; piv<=0; sidx<=0; erow<=0; temp<=0;
      for(i=0;i<K;i=i+1) mat[i]<=0;
    end else begin
      state<=next_state;
      case(state)
        IDLE: done<=0;
        LOAD: begin
          for(i=0;i<K;i=i+1)
            mat[i] <= Gpp_flat[i*N +: N];
          piv<=0; sidx<=0; erow<=0;
        end
        FIND: if(!mat[piv][piv] && piv+sidx+1<K) sidx<=sidx+1;
        SWAP: begin
          temp           = mat[piv];
          mat[piv]       = mat[piv+sidx+1];
          mat[piv+sidx+1] = temp;
          sidx<=0;
        end
        ELIM: begin
          if(erow<K) begin
            if(erow!=piv && mat[erow][piv])
              mat[erow] <= mat[erow]^mat[piv];
            erow<=erow+1;
          end
        end
        NEXT: begin
          piv<=piv+1; sidx<=0; erow<=0;
        end
        DONE: done<=1;
      endcase
    end
  end

  always @(*) begin
    for(i=0;i<K;i=i+1)
      G1_flat[i*N +: N] = mat[i];
  end

endmodule
