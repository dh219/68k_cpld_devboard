`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////
module picovid (
	input CLK,

	input RESET,
	input HALT,

	input BR,
	input BG,
	input BGACK,
	
	input [2:0] FC,
	input RW,
	input AS,
	input LDS,
	input UDS,
	input DTACK,
	input BERR,
	
	input [2:0] IPL,
	
	input VPA,
	input VMA,
	input E,
	
	input [23:1] A,
	input [15:0] D,
	
	input TP1,
	
	input P50,
	
	input P52,
	input P53,
	input P54,
	input P55,
	input P56,
	
	input P58,
	input P59,
	input P60,
	input P61,
	
	output P63,
	output P64,
	output P65,
	output P66,
	output P67,
	output P68,
	
	output P70,
	output P71,
	input P72,
	input P73
    );

/*
reg [22:0] clk_d = 'd0;
wire tick = clk_d[10];

always @(posedge P50) begin
	clk_d <= clk_d + 'd1;
end
*/
reg [7:0] d = 'd1;

always @( posedge P50 or negedge RESET ) begin
	if( ~RESET )
		d <= 'd1;
	else begin
		d <= d << 1;
		if( d == 'd0 )
			d <= 'd1;
	end
end

wire oe = P73;
//reg oe = 1'b1;

// data lines
assign P63 = oe ? 1'bz : d[0];
assign P64 = oe ? 1'bz : d[1];
assign P65 = oe ? 1'bz : d[2];
assign P66 = oe ? 1'bz : d[3];
assign P67 = oe ? 1'bz : d[4];
assign P68 = oe ? 1'bz : d[5];
assign P70 = oe ? 1'bz : d[6];
assign P71 = oe ? 1'bz : d[7];


endmodule
