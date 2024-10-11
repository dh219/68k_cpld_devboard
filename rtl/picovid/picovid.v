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
	
	output P50, // RTS
	
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
	input P73	// strobe
    );

reg [23:0] a_in;
reg [15:0] d_in;

reg [7:0] d = 'd1;
reg rts = 1'b1;
reg [3:0] strobestate = 'd0;


wire write = ( {A[23:15]} == 9'b000001111 ) && ~RW && ~DTACK;
//wire write = ( {A[23:15]} == { 4'h6, 4'h0, 1'b0 } ) && ~RW && ( ~DTACK );
wire ack = ( strobestate == 'd5 );

always @( posedge write or posedge ack ) begin
	if( ack )
		rts <= 1'b1;
	else if( write & rts ) begin
		d_in <= D[15:0];
		a_in <= {A[23:1],1'b0};
		rts <= 1'b0;
	end		
end

wire strobe = P73;


always @(negedge strobe ) begin
//	d_in <= D[15:0];
//	a_in <= {A[23:1],1'b0};
	case( strobestate )
		'd0: begin
			d <= a_in[23:16];
			strobestate <= 'd1;
		end
		'd1: begin
			d <= a_in[15:8];
			strobestate <= 'd2;
		end
		'd2: begin
			d <= a_in[7:0];
			strobestate <= 'd3;			
		end
		'd3: begin
			d <= d_in[15:8];
			strobestate <= 'd4;
		end
		'd4: begin
			d <= d_in[7:0];
			strobestate <= 'd5;
		end
		'd5: begin // blank strobe to end
			strobestate <= 'd0;
		end
	endcase
		
end


wire oe = (strobestate == 'd0);

// data lines
assign P63 = oe ? 1'bz : d[0];
assign P64 = oe ? 1'bz : d[1];
assign P65 = oe ? 1'bz : d[2];
assign P66 = oe ? 1'bz : d[3];
assign P67 = oe ? 1'bz : d[4];
assign P68 = oe ? 1'bz : d[5];
assign P70 = oe ? 1'bz : d[6];
assign P71 = oe ? 1'bz : d[7];

assign P50 = rts ? 1'bz: 1'b0;

endmodule
