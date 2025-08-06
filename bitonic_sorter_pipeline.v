`timescale 1ns / 1ps
module bitonic_sorter_pipeline #(
    parameter integer N           = 64,
    parameter integer BIT_WIDTH   = 32,
    parameter integer INDEX_WIDTH = 3 
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire                      valid,
    input  wire [N*BIT_WIDTH-1:0]    y,
    output reg  [N*BIT_WIDTH-1:0]    z,
    output reg  [N*INDEX_WIDTH-1:0]  lambda1,
    output reg                       done
);

  localparam [1:0] IDLE    = 2'b00,
                   RUN     = 2'b01,
                   DONE_ST = 2'b10;
  reg [1:0] state;

  // storage for values and their indices
  reg signed [BIT_WIDTH-1:0]   data_array  [0:N-1];
  reg signed [BIT_WIDTH-1:0]   temp_data   [0:N-1];
  reg        [INDEX_WIDTH-1:0] index_array [0:N-1];
  reg        [INDEX_WIDTH-1:0] temp_index  [0:N-1];

  // absolute‐value array for sorting by |y|
  reg [BIT_WIDTH-1:0] abs_data [0:N-1];

  reg [31:0] curr_k;
  reg [31:0] curr_j;

  integer i, l2;

  // combinational stage: compute absolute values, then compare‐swap
  always @(*) begin
    // 1) compute |data_array[i]|
    for (i = 0; i < N; i = i + 1) begin
      if (data_array[i][BIT_WIDTH-1] == 1'b1)
        abs_data[i] = ~data_array[i] + 1'b1;
      else
        abs_data[i] = data_array[i];
    end

    // 2) initialize temp_data/index
    for (i = 0; i < N; i = i + 1) begin
      temp_data[i]  = data_array[i];
      temp_index[i] = index_array[i];
    end

    // 3) bitonic compare‐and‐swap on absolute values
    for (i = 0; i < N; i = i + 1) begin
      l2 = i ^ curr_j;
      if (l2 > i) begin
        // ascending when (i&k)==0, descending otherwise
        if (((i & curr_k) == 0 && abs_data[i] > abs_data[l2]) ||
            ((i & curr_k) != 0 && abs_data[i] < abs_data[l2])) begin
          temp_data[i]   = data_array[l2];
          temp_data[l2]  = data_array[i];
          temp_index[i]  = index_array[l2];
          temp_index[l2] = index_array[i];
        end
      end
    end
  end

  // sequential stage: drive the pipeline & control FSM
  always @(posedge clk) begin
    if (rst) begin
      state   <= IDLE;
      done    <= 1'b0;
      curr_k  <= 32'd2;
      curr_j  <= 32'd1;
      for (i = 0; i < N; i = i + 1) begin
        data_array[i]  <= {BIT_WIDTH{1'b0}};
        index_array[i] <= i[INDEX_WIDTH-1:0];
      end
    end else begin
      case (state)
        IDLE: begin
          done <= 1'b0;
          if (valid) begin
            // load inputs into array
            for (i = 0; i < N; i = i + 1) begin
              data_array[i]  <= y[i*BIT_WIDTH +: BIT_WIDTH];
              index_array[i] <= i[INDEX_WIDTH-1:0];
            end
            curr_k <= 32'd2;
            curr_j <= 32'd1;
            state  <= RUN;
          end
        end

        RUN: begin
          // commit the compare‐swap results
          for (i = 0; i < N; i = i + 1) begin
            data_array[i]  <= temp_data[i];
            index_array[i] <= temp_index[i];
          end
          // update k and j
  if (curr_j > 1) begin
    curr_j <= curr_j >> 1;
  end else if (curr_k < N) begin
    curr_k <= curr_k << 1;
    curr_j <= curr_k;        
  end else begin
            state <= DONE_ST;
          end
        end

        DONE_ST: begin
          // output sorted array z and permutation lambda1
          for (i = 0; i < N; i = i + 1) begin
            z    [i*BIT_WIDTH   +: BIT_WIDTH]   <= data_array[N-1-i];
            lambda1[i*INDEX_WIDTH +: INDEX_WIDTH] <= index_array[N-1-i];
          end
          done  <= 1'b1;
          state <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
