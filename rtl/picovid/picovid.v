`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////
module picovid (
	input CLK,

	input RESET,
	input RW,
	input AS,
	input LDS,
	input UDS,
	output DTACK,

	output VSYNC_OUT,
	output HSYNC_OUT,
	output BLANK_OUT,
	
	input HSYNC,
	input VSYNC,
	input BLANK,
	
	input PICOVSYNC,
	input PICOHSYNC,
	
	output SHIFTEREN,
	output PICOEN,

	input [23:1] A,
	input [15:0] D,
	
	input TP1,
	input TP2,
	output TP3,
	output TP4, // VSYNC ORIG

	input OSC48,	// OSC
	
	output [7:0] PICOD,

	output PICOCLK,
	output [2:0] PICOA
    );

reg [23:0] a0;
reg [15:0] d0;
reg [23:0] a1;
reg [15:0] d1;

reg [7:0] d_out = 'd1;

reg displaymode = 1'b1;
reg [18:0] scrcounter = 'd0;

//wire [2:0] padd = { P52, P50, P73 };

//wire base = ( A[18:15] == 4'b1111 );

reg uds0;
reg lds0;
reg uds1;
reg lds1;
wire idle;
wire LOAD = TP1;


reg trig0 = 1'b0;
reg trig1 = 1'b0;
reg ack0 = 1'b0;
reg ack1 = 1'b0;
reg clkout = 1'b0;
reg _dtack_in = 1'b1;


reg [1:0] AS_S;
reg [1:0] RW_S;
reg [1:0] UDS_S;
reg [1:0] LDS_S;

always @( posedge OSC48 ) begin
	AS_S <= {AS_S[0], AS};
	RW_S <= {RW_S[0], RW};
	UDS_S <= {UDS_S[0], UDS};
	LDS_S <= {LDS_S[0], LDS};
end

reg address_trigger = 1'b0;
always @( posedge OSC48 ) begin
	address_trigger <= ( !RW && !AS && !(UDS&LDS) && LOAD );
end


always @( posedge address_trigger ) begin
   a1 <= {A[23:1],1'b0};					
	d1 <= D[15:0];
	uds1 <= UDS;
	lds1 <= LDS;
	trig1 <= ~trig1;
end

reg [3:0] cycle = 'd0;
reg active = 1'b0;
reg [2:0] type;
assign idle = cycle == 'd0; // perhaps duplicating active?
/*
always @( posedge LOAD or negedge VSYNC ) begin

	scrcounter <= scrcounter + 'd2;
	
	if( !VSYNC )
		scrcounter <= 'h78000;
	else 
	begin
		if( idle ) begin // if a transmission is already in play, we'll have to skip this one.
			d0 <= D[15:0];
			a0 <= scrcounter;
			trig0 <= ~trig0;
			
			uds0 <= 1'b0;
			lds0 <= 1'b0;
		end
	end
end*/

reg uds_composite = 'd1;
reg lds_composite = 'd1;

reg cmode = 1'b1;
always @(posedge OSC48 ) begin
	case(cycle)
		'd0: begin
			
			if( trig1 ^ ack1 ) begin
				cmode <= 1'b1;
				uds_composite <= UDS;//uds1;
				lds_composite <= LDS;//lds1;
				cycle <= 'd1;
			end
			/*
			if( trig0 ^ ack0 ) begin
				cmode <= 1'b0;
				uds_composite <= uds0;
				lds_composite <= lds0;
				cycle <= 'd1;
			end
			*/
			clkout <= 1'b0;
			active <= 1'b0;
			_dtack_in <= 1'b1;
			type <= 'd0;
		end
		'd1: begin
			ack0 <= trig0;
			ack1 <= trig1;
			d_out <= cmode ? a1[23:16] : a0[23:16];
			type <= 'd1;
			active <= 1'b1;
			clkout <= 1'b0;
			cycle <= 'd2;			
		end
		'd3: begin
			d_out <= cmode ? a1[15:8] : a0[15:8];
			type <= 'd2;
			active <= 1'b1;
			clkout <= 1'b0;
			cycle <= 'd4;			
		end
		'd5: begin
			d_out <= cmode ? a1[7:0] : a0[7:0];
			type <= 'd3;
			active <= 1'b1;
			clkout <= 1'b0;
			cycle <= 'd6;
		end
		'd7:  begin
			d_out <= cmode ? d1[15:8] : d0[15:8];
			type <= lds_composite ? 'd5 : 'd4; // if LDS is coming type = 4, else let's finish with type = 5
			active <= 1'b1;
			clkout <= uds_composite ? 1'b1 : 1'b0;
			cycle <= 'd8;
		end
		'd9: begin
			d_out <= cmode ? d1[7:0] : d0[7:0];
			type <= 'd6;
			active <= 1'b1;
			clkout <= lds_composite ? 1'b1 : 1'b0;
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

assign PICOD = active ? d_out : 8'bz;
assign PICOCLK = clkout;
assign PICOA 	= type;

assign VSYNC_OUT = displaymode ? PICOVSYNC : VSYNC;
assign HSYNC_OUT = displaymode ? PICOHSYNC : HSYNC;
assign BLANK_OUT = displaymode ? 1'b1 : BLANK;

assign SHIFTEREN = displaymode;
assign PICOEN = !displaymode;


wire reg_access 		= ( A[23:4] == 20'hF1DDB ) && !UDS && !LDS && !AS;
wire altreg_access 	= ( A[23:4] == 20'h00030 ) && !UDS && !LDS && !AS;
wire falpal_reg_access = ( A[23:10] == 14'h3fe6 ) && !UDS && !LDS && !AS; // Falcon pallete


//assign DTACK = 1'bz;//_dtack_in ? 1'bz : 1'b0;
assign DTACK = (reg_access|falpal_reg_access|altreg_access) ? 1'b0 : 1'bz;

/* reset held timer (using vsync) to switch modes */
/* can't fit
always @( negedge VSYNC ) begin
	if( !RESET )
		vsync_counter <= vsync_counter + 'd1;
	else
		vsync_counter <= 'd0;
end

wire modereg = altreg_access & ( A[3:1] == 3'd7 ) & ~RW & address;
wire modechange = ( vsync_counter[7] | modereg );
always @( posedge modechange ) begin
	displaymode <= ~displaymode;
end
*/

always @(posedge OSC48 ) begin
	displaymode <= TP2; // normally displaymode
end

assign TP3 = address_trigger;
assign TP4 = VSYNC;

endmodule
