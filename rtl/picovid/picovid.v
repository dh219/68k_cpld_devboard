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
	input TP3,
	output TP4, // VSYNC ORIG

	input OSC48,	// OSC
	
	output [7:0] PICOD,

	output PICOCLK,
	output [2:0] PICOA
    );

reg [23:0] a_in;
reg [15:0] d_in;

reg [7:0] d = 'd1;

reg mode = 1'b1;

reg [15:0] scrcounter = 'd0;

//wire [2:0] padd = { P52, P50, P73 };

//wire base = ( A[18:15] == 4'b1111 );

reg address;
reg uds_in;
reg lds_in;
wire idle;
/*
always @( negedge CLK ) begin
	address <= 1'b0;
	if( ~RW & ~AS & ~(UDS&LDS) && ~TP4 && idle ) begin
		address <= 1'b1;
		uds_in <= UDS;
		lds_in <= LDS;
	end
end
*/
reg trig = 1'b0;
reg ack = 1'b0;
reg clkout = 1'b0;
reg _dtack_in = 1'b1;

reg [7:0] vsync_counter = 'd0;


/*
always @( posedge address ) begin
	d_in <= D[15:0];
	a_in <= {A[23:1],1'b0};					
	trig <= ~trig;
end
*/

reg [3:0] cycle = 'd0;
reg active = 1'b0;
reg [2:0] type;
assign idle = cycle == 'd0; // perhaps duplicating active?
wire LOAD = TP1;

// Use LOAD as a clock for capturing the bus and for nothing else!
reg [15:0] Data;
always @( posedge LOAD)
	Data <= D[15:0];
	
reg syncedVsync;
reg vsync1;
reg vsync2;
reg onVsync;
reg syncLoad;
reg load1;
reg load2;

reg invert;

always @( negedge OSC48) begin
	syncedVsync <= VSYNC;
	vsync1 <= syncedVsync;
	vsync2 <= vsync1;
	onVsync <= !vsync1 & !vsync2;	// You can use a larger glitch filter
	
	syncLoad <= LOAD;
	load1 <= syncLoad;
	load2 <= load1;

	
	if( onVsync) begin
		scrcounter <= 'd0;
		invert <= ~invert;
	end
	// Raising edge
	else if( !load2 & load1 ) begin
		scrcounter <= scrcounter + 'd2;
		
		if( idle /*&& vsync_counter[4:0] == 'd0 */ /*&& scrcounter == 'd0 */) begin
			d_in <= Data;		// Depending on the rest of the code, you might not need this synchronization step
			a_in <= { 8'h0, scrcounter[15:0]};
		
			uds_in <= 1'b0;
			lds_in <= 1'b0;
			trig <= ~trig;
		end
	end
end

/*
always @( posedge LOAD or negedge VSYNC ) begin

	scrcounter <= scrcounter + 'd2;
	
	if( !VSYNC )
		scrcounter <= 'd0;
	else 
	begin
		if( idle ) begin // if a transmission is already in play, we'll have to skip this one.
			d_in <= D[15:0];
//			d_in <= scrcounter;

	//		a_in <= { 8'h07, 1'b1, scrcounter, 1'b0 }; // srcounter = 14 bits => 8+1+14+1 = 24 bits
//			a_in <= { 9'h0, scrcounter[13:0], 1'b0 };
			a_in <= scrcounter;
			trig <= ~trig;
			
			uds_in <= 1'b0;
			lds_in <= 1'b0;
		end
	end
end
*/

always @(posedge OSC48 ) begin
	case(cycle)
		'd0: begin
			if( trig ^ ack ) begin
				cycle <= 'd1;
			end
			clkout <= 1'b0;
			active <= 1'b0;
			_dtack_in <= 1'b1;
			type <= 'd0;
		end
		'd1: begin
			//ack <= ~ack;
			ack <= trig;
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
			type <= lds_in ? 'd5 : 'd4; // if LDS is coming type = 4, else let's finish with type = 5
			active <= 1'b1;
			clkout <= uds_in ? 1'b1 : 1'b0;
			cycle <= 'd8;
		end
		'd9: begin
			d <= d_in[7:0];
			type <= 'd6;
			active <= 1'b1;
			clkout <= lds_in ? 1'b1 : 1'b0;
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

assign PICOD = active ? d : 8'bz;
assign PICOCLK = clkout;
assign PICOA 	= type;

assign VSYNC_OUT = mode ? PICOVSYNC : VSYNC;
assign HSYNC_OUT = mode ? PICOHSYNC : HSYNC;
assign BLANK_OUT = mode ? 1'b1 : BLANK;

assign SHIFTEREN = mode;
assign PICOEN = !mode;


wire reg_access 		= ( A[23:4] == 20'hF1DDB ) && !UDS && !LDS && !AS;
wire altreg_access 	= ( A[23:4] == 20'h00030 ) && !UDS && !LDS && !AS;
wire falpal_reg_access = ( A[23:10] == 14'h3fe6 ) && !UDS && !LDS && !AS; // Falcon pallete


//assign DTACK = 1'bz;//_dtack_in ? 1'bz : 1'b0;
assign DTACK = (reg_access|falpal_reg_access|altreg_access) ? 1'b0 : 1'bz;

/* reset held timer (using vsync) to switch modes */

always @( negedge VSYNC ) begin
/*
	if( !RESET )
		vsync_counter <= vsync_counter + 'd1;
	else
		vsync_counter <= 'd0;
		*/
		vsync_counter <= vsync_counter + 'd1;
end
/*
wire modereg = altreg_access & ( A[3:1] == 3'd7 ) & ~RW & address;
wire modechange = ( vsync_counter[7] | modereg );
always @( posedge modechange ) begin
	mode <= ~mode;
end
*/

always @(posedge OSC48 ) begin
	mode <= TP2;
end

assign TP4 = VSYNC;

endmodule
