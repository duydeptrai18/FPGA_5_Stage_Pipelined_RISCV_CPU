/*
- Output immediate value based on immediate_type and instruction.
- All immediate values will be sign extended.
*/

module immediate_generator(
    input      [31:0] instruction,
    input      [2:0]  immediate_type,
    output reg [31:0] immediate
);

localparam IMM_I = 3'b000;
localparam IMM_S = 3'b001;
localparam IMM_B = 3'b010;
localparam IMM_U = 3'b011;
localparam IMM_J = 3'b100;

always @(*) begin
    case (immediate_type)

        IMM_I: begin
            immediate = {{20{instruction[31]}},instruction[31:20]};
        end

        IMM_S: begin
            immediate = {{20{instruction[31]}},instruction[31:25],instruction[11:7]};
        end

        IMM_B: begin
            immediate = {
                {19{instruction[31]}},
                instruction[31],
                instruction[7],
                instruction[30:25],
                instruction[11:8],
                1'b0
            };
        end

        IMM_U: begin
            immediate = {instruction[31:12],12'b0};
        end

        IMM_J: begin
            immediate = {
                {11{instruction[31]}},
                instruction[31],
                instruction[19:12],
                instruction[20],
                instruction[30:21],
                1'b0
            };
        end

        default: begin
            immediate = 32'd0;
        end

    endcase
end

endmodule