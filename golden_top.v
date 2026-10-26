// ============================================================================
// Copyright (c) 2025 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development
//   Kits made by Terasic.  Other use of this code, including the selling
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use
//   or functionality of this code.
//
// ============================================================================
//
//  Terasic Technologies Inc
//  No.80, Fenggong Rd., Hukou Township, Hsinchu County 303035. Taiwan
//
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// ============================================================================
//Date:  Mon Aug 18 13:47:53 2025
// ============================================================================

module golden_top(

      ///////// CLOCK /////////
      input              CLOCK0_50,
      input              CLOCK1_50,

      ///////// KEY /////////
      input    [ 3: 0]   KEY, //BUTTON is Low-Active

      ///////// SW /////////
      input    [ 9: 0]   SW,

      ///////// LED /////////
      output  reg [ 9: 0]   LEDR, //LED is Low-Active

      ///////// Seg7 /////////
      output   reg [ 6: 0]   HEX0,
      output   reg [ 6: 0]   HEX1,
      output   reg [ 6: 0]   HEX2,
      output   reg [ 6: 0]   HEX3,
      output   reg [ 6: 0]   HEX4,
      output   reg [ 6: 0]   HEX5,

      ///////// SDRAM /////////
      output             DRAM_CLK,
      output             DRAM_CKE,
      output   [12: 0]   DRAM_ADDR,
      output   [ 1: 0]   DRAM_BA,
      inout    [31: 0]   DRAM_DQ,
      output             DRAM_CS_n,
      output             DRAM_WE_n,
      output             DRAM_CAS_n,
      output             DRAM_RAS_n,
      output   [ 3: 0]   DRAM_DQM,

      ///////// HDMI /////////
      output             HDMI_TX_CLK,
      output             HDMI_TX_HS,
      output             HDMI_TX_VS,
      output   [23: 0]   HDMI_TX_D,
      output             HDMI_TX_DE,
      input              HDMI_TX_INT,
      inout              HDMI_LRCLK,
      inout              HDMI_MCLK,
      inout              HDMI_SCLK,
      inout              HDMI_I2S0,

      ///////// UART /////////
      output             UART_TX,
      input              UART_RX,

      ///////// I2C for HDMI and ADC /////////
      inout              I2C_SCL,
      inout              I2C_SDA,

      ///////// GPIO /////////
      inout    [35: 0]   GPIO_D

);


//=======================================================
//  REG/WIRE declarations
//=======================================================
//pll declaration:
wire locked;
wire cpu_clock;

wire ninit_done;

wire reset_request_n = KEY[0] & ~ninit_done;

reg reset_sync_1;
reg reset_sync_2;

wire debug_write_register_enable;
wire [4:0] debug_rd;
wire [31:0] debug_register_write_data;
wire debug_write_memory_enable;
wire [31:0] debug_memory_address;
wire [31:0] debug_memory_write_data;
wire [31:0] debug_pc;

wire cpu_reset_request_n = reset_sync_2 & locked;
reg cpu_reset_sync_1;
reg cpu_reset_sync_2;

always @(posedge CLOCK0_50 or negedge reset_request_n) begin
    if (!reset_request_n) begin
        reset_sync_1 <= 1'b0;
        reset_sync_2 <= 1'b0;
    end
	 
    else begin
        reset_sync_1 <= 1'b1;
        reset_sync_2 <= reset_sync_1;
    end
end

always @(posedge cpu_clock or negedge cpu_reset_request_n) begin
    if (!cpu_reset_request_n) begin
        cpu_reset_sync_1 <= 1'b0;
        cpu_reset_sync_2 <= 1'b0;
    end
	 
    else begin
        cpu_reset_sync_1 <= 1'b1;
        cpu_reset_sync_2 <= cpu_reset_sync_1;
    end
end


//=======================================================
//  Structural coding
//=======================================================
reset_release reset_release_unit(
	.ninit_done(ninit_done)
);


cpu_pll cpu_pll_unit(
	.refclk(CLOCK0_50),
	.locked(locked),
	.rst(!reset_sync_2),
	.outclk_0(cpu_clock)
);

cpu_top cpu_top_unit(
    .clock(cpu_clock),
    .reset_n(cpu_reset_sync_2),
    .debug_write_register_enable(debug_write_register_enable),
    .debug_rd(debug_rd),
    .debug_register_write_data(debug_register_write_data),
    .debug_write_memory_enable(debug_write_memory_enable),
    .debug_memory_address(debug_memory_address),
    .debug_memory_write_data(debug_memory_write_data),
    .debug_pc(debug_pc)
);
localparam SEG_F = 7'b0001110;
localparam SEG_A = 7'b0001000;
localparam SEG_I = 7'b1111001; 
localparam SEG_L = 7'b1000111;
localparam SEG_P = 7'b0001100;
localparam SEG_S = 7'b0010010; 

always @(*) begin
    HEX5 = 7'b1111111;
    HEX4 = 7'b1111111;
    HEX3 = 7'b1111111;
    HEX2 = 7'b1111111;
    HEX1 = 7'b1111111;
    HEX0 = 7'b1111111;

    if (debug_pc[9:7] == 3'b100) begin // FAIL
        HEX3 = SEG_F;
        HEX2 = SEG_A;
        HEX1 = SEG_I;
        HEX0 = SEG_L;
    end
    else if (debug_pc[9:7] == 3'b111) begin // PASS
        HEX3 = SEG_P;
        HEX2 = SEG_A;
        HEX1 = SEG_S;
        HEX0 = SEG_S;
    end
end

always @(*) begin
	//LEDR = 10'b1111111111;
	LEDR = 10'd0;
	case(SW[7:5])

	3'd0: LEDR[0] = ~debug_write_register_enable;
   3'd1:  LEDR[4:0] = ~debug_rd;
	3'd2: LEDR[9:0] = ~debug_register_write_data[9:0];
	3'd3: LEDR[0] = ~debug_write_memory_enable;
	3'd4: LEDR[9:0] = ~debug_memory_address[9:0];
	3'd5: LEDR[9:0] = ~debug_memory_write_data[9:0];
	3'd6: LEDR[9:0] = ~debug_pc[9:0];
	endcase
	
end

endmodule
