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
	
	input P50, // POLL ADDRESS
	
	input P52, // POLL ADDRESS
	input P53,
	input P54,
	input P55,
	input P56,
	
	input P58,
	input P59,
	input P60,
	input P61,
	
	output P63, // DATA OUT
	output P64, // DATA OUT
	output P65, // DATA OUT
	output P66, // DATA OUT
	output P67, // DATA OUT
	output P68, // DATA OUT
	
	output P70, // DATA OUT 
	output P71, // DATA OUT
	output P72, 	// RTS (out)
	input P73 	// POLL ADDRESS
    );

reg [23:0] a_in;
reg [15:0] d_in;

reg [7:0] d = 'd1;
reg _rts = 1'b1;
//reg [3:0] strobestate = 'd0;

//wire rst = ( A[23:20] == 'h2 );
wire [2:0] padd = { P52, P50, P73 };


//wire write = ( {A[23:15]} == 9'b000001111 ) && ~RW && ~DTACK;
wire write = ( A[23:20] == { 4'h3 } ) && ~RW && ( ~DTACK );
//wire ack = ~_rts & (padd != padd_rts);
wire ack = ~_rts & (padd == 'd0);


always @( posedge write or posedge ack ) begin
	if( ack )
		_rts <= 1'b1;
	else if( write & _rts) begin
		d_in <= D[15:0];
		a_in <= {A[23:1],1'b0};
		_rts <= 1'b0;
	end		
end
/*
wire strobe = P73;


always @(negedge strobe or posedge rst ) begin
//	d_in <= D[15:0];
//	a_in <= {A[23:1],1'b0};

	if( rst )
		strobestate <= 'd0;
	else begin
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
end
*/

always @( padd ) begin
	case(padd)
		'd0: d <= a_in[23:16];
		'd1: d <= a_in[15:8];
		'd2: d <= a_in[7:0];
		'd3: d <= d_in[15:8];
		'd4: d <= d_in[7:0];
		default: 	d <= { 5'd0, padd };
	endcase
end
	


wire oe = ( padd == 'd7 );

// data lines
assign P63 = oe ? 1'bz : d[0];
assign P64 = oe ? 1'bz : d[1];
assign P65 = oe ? 1'bz : d[2];
assign P66 = oe ? 1'bz : d[3];
assign P67 = oe ? 1'bz : d[4];
assign P68 = oe ? 1'bz : d[5];
assign P70 = oe ? 1'bz : d[6];
assign P71 = oe ? 1'bz : d[7];

assign P72 = _rts ? 1'bz: 1'b0;

endmodule
