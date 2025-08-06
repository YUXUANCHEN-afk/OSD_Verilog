`timescale 1ns/1ps
module flipping_mask_generator_2bit #(
    parameter K = 8
)(
    input clk,
    input rst,
    input en,  // en signal
    output reg [K-1:0] flip_mask,
    output reg done
);

    reg [$clog2(K)-1:0] i;
    reg [$clog2(K)-1:0] j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i <= 0;
            j <= 1;
            done <= 0;
        end else if(en) begin
            if ((i == K-2) && (j == K-1))
                done <= 1;
            else begin
                if (j < K-1)
                    j <= j + 1;
                else begin
                    i <= i + 1;
                    j <= i + 2;  // right side old i
                end
            end
        end
    end

    always @(*) begin
        flip_mask = (1'b1 << i) | (1'b1 << j);
    end

endmodule
