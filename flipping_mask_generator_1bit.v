`timescale 1ns/1ps
module flipping_mask_generator_1bit #(
    parameter K = 8  
)(
    input clk,
    input rst,
    output reg [K-1:0] flip_mask, 
    output reg done
);
    // range 0 to k-1
    reg [$clog2(K)-1:0] pos;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pos <= 0;
            done <= 0;
        end else begin
            if (pos == K-1)
                done <= 1;
            else
                pos <= pos + 1;
        end
    end

    // 1 go left "pos" bit
    always @(*) begin
        flip_mask = (1'b1 << pos);
    end

endmodule
