/*
- Test asynchronous reset
- Test pc advances by 4 at every posedge
*/

`timescale 1ns/1ps

module program_counter_tb;

reg clock;
reg reset_n;

wire [31:0] next_pc;
wire [31:0] pc;

integer errors;

assign next_pc = pc + 32'd4;

program_counter program_counter_dut(
    .clock   (clock),
    .reset_n (reset_n),
    .next_pc (next_pc),
    .pc      (pc)
);


// 10 ns clock period
initial begin
    clock = 1'b0;

    forever begin
        #5 clock = ~clock;
    end
end


task clock_and_check;
    input [31:0] expected_pc;

    begin
        @(posedge clock);

        
        #1; //allow dut to settle.

        if (pc !== expected_pc) begin
            errors = errors + 1;
            $display(
                "FAILED: pc=%0d expected=%0d",
                pc, expected_pc
            );
        end
        else begin
            $display(
                "PASSED: pc=%0d expected=%0d",
                pc, expected_pc
            );
        end
    end
endtask


task check_pc;
    input [31:0] expected_pc;

    begin
        if (pc !== expected_pc) begin
            errors = errors + 1;
            $display(
                "FAILED: pc=%0d expected=%0d",
                pc, expected_pc
            );
        end
        else begin
            $display(
                "PASSED: pc=%0d expected=%0d",
                pc, expected_pc
            );
        end
    end
endtask


initial begin
    errors  = 0;
    reset_n = 1'b1;

    // Assert asynchronous reset
    #1;
    reset_n = 1'b0;

    // PC should reset immediately, no clock edge required
    #1;
    check_pc(32'd0);

    
    reset_n = 1'b1;

    // PC advances on each rising edge
    clock_and_check(32'd4);
    clock_and_check(32'd8);
    clock_and_check(32'd12);

    // No clock edge has occurred, so PC remains 12
    check_pc(32'd12);

    // Test asynchronous reset again
    #1;
    reset_n = 1'b0;
    #1;
    check_pc(32'd0);

    if (errors == 0)
        $display("ALL PC TESTS PASSED");
    else
        $display("%0d PC TESTS FAILED", errors);

    $finish;
end

endmodule