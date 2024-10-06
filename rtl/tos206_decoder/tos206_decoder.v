`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////
module tos206_decoder(
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
	output DTACK,
	input BERR,
	
	input [2:0] IPL,
	
	input VPA,
	input VMA,
	input E,
	
	input [23:1] A,
	input [15:0] D,
	
	inout TP1,
	
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
	
	input P63,
	input P64,
	input P65,
	input P66,
	input P67,
	input P68,
	
	input P70,
	input P71,
	input P72,
	output P73
    );

/* This implementation presumes there's a pull-high on the board DTACK line but ROM_CE can take a totem pole driver.
/* It will drive DTACK high for once clock cycle after DS is deasserted then go high-z.
/* A ROM_CE with a pull-high but no diode-OR circuit can be trivially supported by modifying the _CE line to behave
/* like that of the DTACK line below
*/

wire TOS206_decode =  AS | ~( A[23:19] == 5'b11100 ); // assert is low
wire FIRST8 = AS | ~( A[23:3] == 'h0 ); // map first 8 to ROM
wire TOS206_CE = (UDS&LDS) | ( TOS206_decode & FIRST8 ); // low only when both AS and the address decode are

reg [1:0] TOS206_DTACK = 2'b11;
always @( posedge CLK ) begin
	TOS206_DTACK[1] <= TOS206_DTACK[0];
	TOS206_DTACK[0] <= TOS206_CE;		
end

assign P73 = TOS206_CE;								// driven low when active, driven high when not
// driven when current TOS206 decoding is low, or current decoding is high but it was low last cycle, otherwise high-z
assign DTACK = ( ( TOS206_DTACK[0] == 1'b1 && TOS206_DTACK[1] == 1'b0 ) || TOS206_DTACK[0] == 1'b0 ) ? TOS206_DTACK[0] : 1'bz;
assign TP1 = 1'b0;

endmodule
