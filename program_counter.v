/*
- At every pos edge, this module will receive next_pc.
*/

module program_counter(
    input clock,
    input reset_n,
    input [31:0] next_pc,
    output reg [31:0] pc
);

always @(posedge clock or negedge reset_n) begin
    if (!reset_n)
        pc <= 32'd0;
    else
        pc <= next_pc;
end

endmodule