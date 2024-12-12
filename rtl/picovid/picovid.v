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
	output DTACK,
	input BERR,
	
	input [2:0] IPL,
	
	input VPA,
	input VMA,
	input E,
	
	input [23:1] A,
	input [15:0] D,
	
	input TP1,
	
	output P50, // byte ID[1]
	
	output P52, // byte ID[2]
	input P53,
	input P54,
	input P55,
	input P56,
	
	input P58,
	input P59,
	input P60,
	input P61,	// OSC
	
	output P63, // DATA OUT
	output P64, // DATA OUT
	output P65, // DATA OUT
	output P66, // DATA OUT
	output P67, // DATA OUT
	output P68, // DATA OUT
	
	output P70, // DATA OUT 
	output P71, // DATA OUT
	output P72, 	// RTS (out)
	output P73 	// byte ID[0]
    );

wire OSC = P61;

reg [23:0] a_in;
reg [15:0] d_in;

reg [7:0] d = 'd1;

wire [2:0] padd = { P52, P50, P73 };

wire base = ( A[18:15] == 4'b1111 );

//wire address = ( A[23:20] == { 4'h3 } ) & ~AS & ~(UDS&LDS);

reg address;
reg [1:0] ds_in;
always @( posedge CLK ) begin
	address <= 1'b0;
	if( ~RW && ( base ) & ~AS & ~(UDS&LDS) ) begin
		address <= 1'b1;
		ds_in <= { UDS, LDS };
	end
end

reg trig = 1'b0;
reg ack = 1'b0;
reg clkout = 1'b0;
reg _dtack_in = 1'b1;

always @( posedge address ) begin
	d_in <= D[15:0];
	a_in <= {A[23:1],1'b0};					
	trig <= ~trig;
end

reg [3:0] cycle = 'd0;
reg active = 1'b0;
reg [2:0] type;
always @(posedge OSC) begin

	case(cycle)
		'd0: begin
			if( trig ^ ack )
				cycle <= 'd1;
			clkout <= 1'b0;
			active <= 1'b0;
			_dtack_in <= 1'b1;
			type <= 'd0;
		end
		'd1: begin
			ack <= ~ack;
			d <= a_in[23:16];
			type <= 'd1;
			active <= 1'b1;
			clkout <= 1'b0;
			cycle <= 'd2;			
		end
		'd3: begin
			d <= a_in[15:8];
			type <= 'd2;
			active <= 1'b1;
			clkout <= 1'b0;
			cycle <= 'd4;			
		end
		'd5: begin
			d <= a_in[7:0];
			type <= 'd3;
			active <= 1'b1;
			clkout <= 1'b0;
			cycle <= 'd6;
		end
		'd7:  begin
			d <= d_in[15:8];
			type <= ds_in[0] ? 'd5 : 'd4;
			active <= 1'b1;
			clkout <= ds_in[1] ? 1'b1 : 1'b0;
			cycle <= 'd8;
		end
		'd9: begin
			d <= d_in[7:0];
			type <= 'd6;
			active <= 1'b1;
			clkout <= ds_in[0] ? 1'b1 : 1'b0;
			cycle <= 'd10;			
		end
		'd11: begin
			active <= 1'b0;
			type <= 'd0;
			clkout <= 1'b0;
			_dtack_in <= 1'b0;
			cycle <= 'd12;
		end
		'd12: begin
			if( AS ) begin
				_dtack_in <= 1'b1;
				cycle <= 'd0;
			end
		end
		default:	begin
			active <= 1'b1;
			clkout <= 1'b1;
			cycle <= cycle + 'd1;			
		end
	endcase
 

end

// data lines
assign P63 = active ? d[0]: 1'bz;
assign P64 = active ? d[1]: 1'bz;
assign P65 = active ? d[2]: 1'bz;
assign P66 = active ? d[3]: 1'bz;
assign P67 = active ? d[4]: 1'bz;
assign P68 = active ? d[5]: 1'bz;
assign P70 = active ? d[6]: 1'bz;
assign P71 = active ? d[7]: 1'bz;

assign P72 = clkout;

assign P73 	= type[0];
assign P50  = type[1];
assign P52  = type[2];



assign DTACK = 1'bz;//_dtack_in ? 1'bz : 1'b0;
//assign DTACK = address ? 1'b0 : 1'bz;

endmodule
