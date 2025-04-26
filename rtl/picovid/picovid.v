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
	input TP4,
	
	

	input OSC48,	// OSC
	
	output [7:0] PICOD,
/*
	output P63, // DATA OUT
	output P64, // DATA OUT
	output P65, // DATA OUT
	output P66, // DATA OUT
	output P67, // DATA OUT
	output P68, // DATA OUT
	output P70, // DATA OUT 
	output P71, // DATA OUT
*/
	output PICOCLK,
	output PICOA0,
	output PICOA1,
	output PICOA2 // byte ID[2]

    );

reg [23:0] a_in;
reg [15:0] d_in;

reg [7:0] d = 'd1;

reg mode = 1'b0;

//wire [2:0] padd = { P52, P50, P73 };

//wire base = ( A[18:15] == 4'b1111 );

reg address;
reg uds_in;
reg lds_in;
always @( posedge CLK ) begin
	address <= 1'b0;
	if( ~RW & ~AS & ~(UDS&LDS) ) begin
		address <= 1'b1;
		uds_in <= UDS;
		lds_in <= LDS;
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
always @(posedge OSC48) begin

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

// data lines
/*assign P63 = active ? d[0]: 1'bz;
assign P64 = active ? d[1]: 1'bz;
assign P65 = active ? d[2]: 1'bz;
assign P66 = active ? d[3]: 1'bz;
assign P67 = active ? d[4]: 1'bz;
assign P68 = active ? d[5]: 1'bz;
assign P70 = active ? d[6]: 1'bz;
assign P71 = active ? d[7]: 1'bz;
*/
assign PICOD = active ? d : 8'bz;

assign PICOCLK = clkout;

assign PICOA0 	= type[0];
assign PICOA1  = type[1];
assign PICOA2  = type[2];


assign VSYNC_OUT = mode ? PICOVSYNC : VSYNC;
assign HSYNC_OUT = mode ? PICOHSYNC : HSYNC;
assign BLANK_OUT = mode ? 1'b1 : BLANK;

assign SHIFTEREN = mode;
assign PICOEN = !mode;


wire reg_access = ( A[23:4] == 20'hF1DDB ) && !UDS && !LDS && !AS;
wire falpal_reg_access = ( A[23:10] == 14'h3fe6 ) && !UDS && !LDS && !AS; // Falcon pallete

//always @(posedge reg_access) begin
//	mode <= !mode;
//end

//assign DTACK = 1'bz;//_dtack_in ? 1'bz : 1'b0;
assign DTACK = (reg_access|falpal_reg_access) ? 1'b0 : 1'bz;

/* switch mode every N vsyncs so I can see what's going on */
reg [8:0] vsync_counter = 'd0;
always @( negedge VSYNC ) begin
	vsync_counter <= vsync_counter + 'd1;
	mode <= vsync_counter[8];
end


endmodule
