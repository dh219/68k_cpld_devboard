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


wire [2:0] padd = { P52, P50, P73 };

wire address = ( A[23:20] == { 4'hd } ) & ~AS;
reg write = 1'b0;

reg [2:0] state = 'd0;
//wire idle = (state == 'd0);
wire idle = (padd == 'd7);
reg _dtack_in = 1'b1;
reg uds_in;

// I'm controlling dtack_in, state and _rts here
always @( posedge CLK or negedge RESET ) begin

	if( ~RESET ) begin
		state <= 'd0;
		_dtack_in <= 1'b1;
		_rts <= 1'b1;
	end
	else begin
		uds_in <= UDS;
		case( state )
			'd0: begin
				_rts <= 1'b1;
				_dtack_in <= 1'b1;
				if( ~uds_in && address /*& ~RW */ && padd == 'd7 ) begin // if padd progression ongoing, wait before latching
					_rts <= 1'b0;
					d_in <= D[15:0];
					a_in <= {A[23:1],1'b0};					
					state <= 'd2;
				end
			end
			'd1: begin
				if( padd == 'd7 ) begin		
					_rts <= 1'b0;
					d_in <= D[15:0];
					a_in <= {A[23:1],1'b0};					
					state <= 'd4;
				end
				else if( uds_in )					// need an out if we miss a cycle
					state <= 'd0;
			end
			'd2: begin		// assert dtack, wait for PADD progression to start or DS to rise
				_dtack_in <= 1'b0;
				if( uds_in ) begin
					state <= 'd3;
					_dtack_in <= 1'b1;
				end
				else if( padd != 'd7 )
					state <= 'd4;
			end
			'd3: begin					// DS has deasserted, wait for padd to go active
				_dtack_in <= 1'b1;	// deassert dtack
				if( padd != 'd7 )
					state <= 'd5;		// go to waiting for padd to finish
			end
			'd4: begin					// padd has gone active but DS still asserted
				_rts <= 1'b1;			// deassert rts
				if( uds_in ) begin
					_dtack_in <= 1'b1;	// deassert DTACK
					state <= 'd5;			// go to waiting for padd to finish
				end
			end
			'd5: begin					// DTACK cycle complete, padd may or may not be complete, wait for that
				_rts <= 1'b1;
				_dtack_in <= 1'b1;
				if( padd == 'd7 )
					state <= 'd0;
			end
			default:
				state <= 'd0;
		endcase					
	end

end


//wire write = ( A[23:20] == { 4'hc } ) && ~RW && ( ~UDS );
//wire ack = ~_rts & (padd == 'd0);
/*

always @( posedge write or posedge ack ) begin
	if( ack )
		_rts <= 1'b1;
	else if( write & _rts) begin
		d_in <= D[15:0];
		a_in <= {A[23:1],1'b0};
		_rts <= 1'b0;
	end		
end
*/

/*
always @( negedge CLK ) begin
	d <= d + 'd1;
end
*/

always @( padd ) begin
	case(padd)
		'd0: d <= a_in[23:16];
		'd1: d <= a_in[15:8];
		'd2: d <= a_in[7:0];
		'd3: d <= d_in[15:8];
		'd4: d <= d_in[7:0];

		default: 	d <= { 5'd0, state };
	endcase
end


// data lines
assign P63 = idle ? 1'bz : d[0];
assign P64 = idle ? 1'bz : d[1];
assign P65 = idle ? 1'bz : d[2];
assign P66 = idle ? 1'bz : d[3];
assign P67 = idle ? 1'bz : d[4];
assign P68 = idle ? 1'bz : d[5];
assign P70 = idle ? 1'bz : d[6];
assign P71 = idle ? 1'bz : d[7];

assign P72 = _rts ? 1'bz: 1'b0;

assign DTACK = _dtack_in ? 1'bz : 1'b0;

endmodule
