`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////
module gotek_led(
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
	
	inout TP1,
	
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

	inout P50, // DATA
	output P73	// CLK
    );
/*
reg [15:0]CLK_DIV = 'd0;
always @( posedge CLK ) begin
	CLK_DIV[0] <= CLK_DIV[0];
	if( CLK_DIV[0] ) CLK_DIV[1] <= ~CLK_DIV[1];
	if( CLK_DIV[1] ) CLK_DIV[2] <= ~CLK_DIV[2];
	if( CLK_DIV[2] ) CLK_DIV[3] <= ~CLK_DIV[3];
	if( CLK_DIV[3] ) CLK_DIV[4] <= ~CLK_DIV[4];
	if( CLK_DIV[4] ) CLK_DIV[5] <= ~CLK_DIV[5];
	if( CLK_DIV[5] ) CLK_DIV[6] <= ~CLK_DIV[6];
	if( CLK_DIV[6] ) CLK_DIV[7] <= ~CLK_DIV[7];
	if( CLK_DIV[7] ) CLK_DIV[8] <= ~CLK_DIV[8];
	if( CLK_DIV[8] ) CLK_DIV[9] <= ~CLK_DIV[9];
	if( CLK_DIV[9] ) CLK_DIV[10] <= ~CLK_DIV[10];
	if( CLK_DIV[10] ) CLK_DIV[11] <= ~CLK_DIV[11];
	if( CLK_DIV[11] ) CLK_DIV[12] <= ~CLK_DIV[12];
	if( CLK_DIV[12] ) CLK_DIV[13] <= ~CLK_DIV[13];
	if( CLK_DIV[13] ) CLK_DIV[14] <= ~CLK_DIV[14];
	if( CLK_DIV[14] ) CLK_DIV[15] <= ~CLK_DIV[15];
end
*/

/* Demonstrate using a surplus Gotek LED with the dev board
*/
/*
reg [7:0] state = 'd0;

reg clk_in = 1'b0;
reg dio = 1'b0;
reg highz = 1'b1;

always @( posedge CLK_DIV[15] or negedge HALT ) begin
	
	if( state != 'd0 )
		state <= state + 'd1;
	
	
	if( ~HALT ) begin
		state <= 'd1;
		clk_in <= 1'b0;
		dio <= 1'b0;
		highz <= 1'b1;
	end
	else begin 	
		case(state)
			'd0: begin				// idle
				clk_in <= 1'b0;
				dio <= 1'b0;
				highz <= 1'b1;
			end
			'd1: begin				// d1,d2 = start
				clk_in <= 1'b1;
				dio <= 1'b1;
				highz <= 1'b0;
			end
			'd2: begin
				clk_in <= 1'b0;
				dio <= 1'b0;
			end
			
			'd3: begin				// write byte 'h44 start
				clk_in <= 1'b0;
				dio <= 'h44 & 'h1;
			end
			'd4: begin
				clk_in <= 1'b1;
			end
			'd5: begin				// write byte 'h44
				clk_in <= 1'b0;
				dio <= 'h44 & 'h2;
			end
			'd6: begin
				clk_in <= 1'b1;
			end
			'd7: begin				// write byte 'h44
				clk_in <= 1'b0;
				dio <= 'h44 & 'h4;
			end
			'd8: begin
				clk_in <= 1'b1;
			end
			'd9: begin				// write byte 'h44
				clk_in <= 1'b0;
				dio <= 'h44 & 'h8;
			end
			'd10: begin
				clk_in <= 1'b1;
			end
			'd11: begin				// write byte 'h44
				clk_in <= 1'b0;
				dio <= 'h44 & 'h10;
			end
			'd12: begin
				clk_in <= 1'b1;
			end
			'd13: begin				// write byte 'h44
				clk_in <= 1'b0;
				dio <= 'h44 & 'h20;
			end
			'd14: begin
				clk_in <= 1'b1;
			end
			'd15: begin				// write byte 'h44
				clk_in <= 1'b0;
				dio <= 'h44 & 'h40;
			end
			'd16: begin
				clk_in <= 1'b1;
			end
			'd17: begin				// write byte 'h44 end
				clk_in <= 1'b0;
				dio <= 'h44 & 'h80;
			end
			'd18: begin
				clk_in <= 1'b1;
			end
			
			'd19: begin				// write byte 'h44 end
				clk_in <= 1'b0;
				dio <= 'h44 & 'h80;
			end
			'd20: begin
				clk_in <= 1'b1;
			end
			
			'd21: begin				// expect for ACK
				clk_in <= 1'b0;
				dio <= 1'b1;
				highz <= 1'b1;
			end
			'd22: begin
				state <= dio ? 'd20 : 'd21; // wait for ACK
			end
			
			'd23: begin			// stop
				clk_in <= 1'b0;
				dio <= 1'b0;
				highz <= 1'b0;
			end
			'd24: begin
				clk_in <= 1'b1;
				dio <= 1'b1;
				highz <= 1'b0;
			end
		
			// start again
			'd25: begin				// start
				clk_in <= 1'b1;
				dio <= 1'b1;
				highz <= 1'b0;
			end
			'd26: begin
				clk_in <= 1'b0;
				dio <= 1'b0;
			end

			'd27: begin				// write byte 'hC0 start
				clk_in <= 1'b0;
				dio <= 'hc0 & 'h1;
			end
			'd28: begin
				clk_in <= 1'b1;
			end
			'd29: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'hc0 & 'h2;
			end
			'd30: begin
				clk_in <= 1'b1;
			end
			'd31: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'hc0 & 'h4;
			end
			'd32: begin
				clk_in <= 1'b1;
			end
			'd33: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'hc0 & 'h8;
			end
			'd34: begin
				clk_in <= 1'b1;
			end
			'd35: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'hc0 & 'h10;
			end
			'd36: begin
				clk_in <= 1'b1;
			end
			'd37: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'hc0 & 'h20;
			end
			'd38: begin
				clk_in <= 1'b1;
			end
			'd39: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'hc0 & 'h40;
			end
			'd40: begin
				clk_in <= 1'b1;
			end
			'd41: begin				// write byte  end
				clk_in <= 1'b0;
				dio <= 'hc0 & 'h80;
			end
			'd42: begin
				clk_in <= 1'b1;
			end
			
			'd43: begin				// expect for ACK
				clk_in <= 1'b0;
				dio <= 1'b1;
				highz <= 1'b1;
			end
			'd44: begin
				state <= dio ? 'd40 : 'd41; // wait for ACK
			end		
			
			// write digit ('h7f)
			'd45: begin				// write byte 'h7f start
				clk_in <= 1'b0;
				dio <= 'h7f & 'h1;
			end
			'd46: begin
				clk_in <= 1'b1;
			end
			'd47: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h7f & 'h2;
			end
			'd48: begin
				clk_in <= 1'b1;
			end
			'd49: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h7f & 'h4;
			end
			'd50: begin
				clk_in <= 1'b1;
			end
			'd51: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h7f & 'h8;
			end
			'd52: begin
				clk_in <= 1'b1;
			end
			'd53: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h7f & 'h10;
			end
			'd54: begin
				clk_in <= 1'b1;
			end
			'd55: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h7f & 'h20;
			end
			'd56: begin
				clk_in <= 1'b1;
			end
			'd57: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h7f & 'h40;
			end
			'd58: begin
				clk_in <= 1'b1;
			end
			'd59: begin				// write byte  end
				clk_in <= 1'b0;
				dio <= 'h7f & 'h80;
			end
			'd60: begin
				clk_in <= 1'b1;
			end		
		
			'd61: begin				// expect for ACK
				clk_in <= 1'b0;
				dio <= 1'b1;
				highz <= 1'b1;
			end
			'd62: begin
				state <= dio ? 'd58 : 'd59; // wait for ACK
			end		
		
			'd63: begin			// stop
				clk_in <= 1'b0;
				dio <= 1'b0;
				highz <= 1'b0;
			end
			'd64: begin
				clk_in <= 1'b1;
				dio <= 1'b1;
				highz <= 1'b0;
			end	


			// start again
			'd65: begin				// start
				clk_in <= 1'b1;
				dio <= 1'b1;
				highz <= 1'b0;
			end
			'd66: begin
				clk_in <= 1'b0;
				dio <= 1'b0;
			end

			'd67: begin				// write byte 'h8a start (display bright normal)
				clk_in <= 1'b0;
				dio <= 'h8a & 'h1;
			end
			'd68: begin
				clk_in <= 1'b1;
			end
			'd69: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h8a & 'h2;
			end
			'd70: begin
				clk_in <= 1'b1;
			end
			'd71: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h8a & 'h4;
			end
			'd72: begin
				clk_in <= 1'b1;
			end
			'd73: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h8a & 'h8;
			end
			'd74: begin
				clk_in <= 1'b1;
			end
			'd75: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h8a & 'h10;
			end
			'd76: begin
				clk_in <= 1'b1;
			end
			'd77: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h8a & 'h20;
			end
			'd78: begin
				clk_in <= 1'b1;
			end
			'd79: begin				// write byte 
				clk_in <= 1'b0;
				dio <= 'h8a & 'h40;
			end
			'd80: begin
				clk_in <= 1'b1;
			end
			'd81: begin				// write byte  end
				clk_in <= 1'b0;
				dio <= 'h8a & 'h80;
			end
			'd82: begin
				clk_in <= 1'b1;
			end
			
			'd83: begin				// expect for ACK
				clk_in <= 1'b0;
				dio <= 1'b1;
				highz <= 1'b1;
			end
			'd84: begin
				state <= dio ? 'd80 : 'd81; // wait for ACK
			end		

			'd85: begin			// stop
				clk_in <= 1'b0;
				dio <= 1'b0;
				highz <= 1'b0;
			end
			'd86: begin
				clk_in <= 1'b1;
				dio <= 1'b1;
				highz <= 1'b0;
			end

			'd87: begin
				clk_in <= 1'b0;
				dio <= 1'b1;
				highz <= 1'b1;
				state <= 'd0;
			end
		endcase		
	end
end


assign P50 = highz ? 1'bz : dio; // DATA
assign P73 = clk_in; // CLK
*/
/*
reg [7:0] mydata = 'h44;

tm1638 TM ( 
	.clk(CLK_DIV[15]),
	.rst(HALT),

	.data_latch( 1'b1 ),
	.data( mydata ),
	.rw( 1'b1 ),
	
	.busy( mybusy ),
	.sclk( P73 ),
	
	.dio_in( P50 ),
	.dio_out( P50 )
	);
*/

    wire clk = E;
    reg tm_cs = 1'b0;
    wire tm_clk = P73;
    wire tm_dio = P50;

    localparam 
        HIGH    = 1'b1,
        LOW     = 1'b0;

    localparam [6:0]
        S_1     = 7'b0000110,
        S_2     = 7'b1011011,
        S_3     = 7'b1001111,
        S_4     = 7'b1100110,
        S_5     = 7'b1101101,
        S_6     = 7'b1111101,
        S_7     = 7'b0000111,
        S_8     = 7'b1111111,
        S_BLK   = 7'b0000000;

    localparam [7:0]
        C_READ  = 8'b01000010,
        C_WRITE = 8'b01000000,
        C_DISP  = 8'b10001111,
        C_ADDR  = 8'b11000000;

    localparam CLK_DIV = 19; // speed of scanner

    reg rst = HIGH;

    reg [5:0] instruction_step;
    reg [7:0] keys;

    reg [7:0] larson;
    reg larson_dir;
    reg [CLK_DIV:0] counter;

    // set up tristate IO pin for display
    //   tm_dio     is physical pin
    //   dio_in     for reading from display
    //   dio_out    for sending to display
    //   tm_rw      selects input or output

	 reg tm_rw = 1'b1;
	wire dio_in = P50;

    // setup tm1638 module with it's tristate IO
    //   tm_in      is read from module
    //   tm_out     is written to module
    //   tm_latch   triggers the module to read/write display
    //   tm_rw      selects read or write mode to display
    //   busy       indicates when module is busy
    //                (another latch will interrupt)
    //   tm_clk     is the data clk
    //   dio_in     for reading from display
    //   dio_out    for sending to display
    //
    //   tm_data    the tristate io pin to module
    reg tm_latch;
	 wire busy;
    wire [7:0] tm_data, tm_in;
    reg [7:0] tm_out;

    assign tm_in = tm_data;
    assign tm_data = tm_rw ? tm_out : 8'hZZ;

    tm1638 u_tm1638 (
        .clk(clk),
        .rst(rst),
        .data_latch(tm_latch),
        .data(tm_data),
        .rw(tm_rw),
        .busy(busy),
        .sclk(tm_clk),
        .dio_in(dio_in),
        .dio_out(dio_out)
    );

    // handles displaying 1-8 on a display location
    // and animating the decimal point
    task display_digit;
        input [2:0] key;
        input [6:0] segs;

        begin
            tm_latch <= HIGH;

            if (keys[key])
                tm_out <= {1'b1, S_BLK[6:0]}; // decimal on
            else
                tm_out <= {1'b0, segs}; // decimal off
        end
    endtask

    // handles animating the LEDs 1-8
    task display_led;
        input [2:0] dot;

        begin
            tm_latch <= HIGH;
            tm_out <= {7'b0, larson[dot]};
        end
    endtask

    always @(posedge clk) begin
        if (rst) begin
            instruction_step <= 6'b0;
            tm_cs <= HIGH;
            tm_rw <= HIGH;
            rst <= LOW;

            counter <= 0;
            keys <= 8'b0;
            larson_dir <= 0;
            larson <= 8'b00010000;

        end else begin
            if (&counter) begin
                larson_dir <= larson[6] ? 0 : larson[1] ? 1 : larson_dir;

                if (larson_dir)
                    larson <= {larson[6:0], larson[7]};
                else
                    larson <= {larson[0], larson[7:1]};
            end

            if (counter[0] && ~busy) begin
                case (instruction_step)
                    // *** KEYS ***
                    1:  {tm_cs, tm_rw}     <= {LOW, HIGH};
                    2:  {tm_latch, tm_out} <= {HIGH, C_READ}; // read mode
                    3:  {tm_latch, tm_rw}  <= {HIGH, LOW};

                    //  read back keys S1 - S8
                    4:  {keys[7], keys[3]} <= {tm_in[0], tm_in[4]};
                    5:  {tm_latch}         <= {HIGH};
                    6:  {keys[6], keys[2]} <= {tm_in[0], tm_in[4]};
                    7:  {tm_latch}         <= {HIGH};
                    8:  {keys[5], keys[1]} <= {tm_in[0], tm_in[4]};
                    9:  {tm_latch}         <= {HIGH};
                    10: {keys[4], keys[0]} <= {tm_in[0], tm_in[4]};
                    11: {tm_cs}            <= {HIGH};

                    // *** DISPLAY ***
                    12: {tm_cs, tm_rw}     <= {LOW, HIGH};
                    13: {tm_latch, tm_out} <= {HIGH, C_WRITE}; // write mode
                    14: {tm_cs}            <= {HIGH};

                    15: {tm_cs, tm_rw}     <= {LOW, HIGH};
                    16: {tm_latch, tm_out} <= {HIGH, C_ADDR}; // set addr 0 pos

                    17: display_digit(3'd7, S_1); // Digit 1
                    18: display_led(3'd0);        // LED 1

                    19: display_digit(3'd6, S_2); // Digit 2
                    20: display_led(3'd1);        // LED 2

                    21: display_digit(3'd5, S_3); // Digit 3
                    22: display_led(3'd2);        // LED 3

                    23: display_digit(3'd4, S_4); // Digit 4
                    24: display_led(3'd3);        // LED 4

                    25: display_digit(3'd3, S_5); // Digit 5
                    26: display_led(3'd4);        // LED 5

                    27: display_digit(3'd2, S_6); // Digit 6
                    28: display_led(3'd5);        // LED 6

                    29: display_digit(3'd1, S_7); // Digit 7
                    30: display_led(3'd6);        // LED 7

                    31: display_digit(3'd0, S_8); // Digit 8
                    32: display_led(3'd7);        // LED 8

                    33: {tm_cs}            <= {HIGH};

                    34: {tm_cs, tm_rw}     <= {LOW, HIGH};
                    35: {tm_latch, tm_out} <= {HIGH, C_DISP}; // display on, full bright
                    36: {tm_cs, instruction_step} <= {HIGH, 6'b0};

                endcase

                instruction_step <= instruction_step + 1;

            end else if (busy) begin
                // pull latch low next clock cycle after module has been
                // latched
                tm_latch <= LOW;
            end

            counter <= counter + 1;
        end
    end

assign P50 = tm_rw ? dio_out : 1'bz;
assign P73 = tm_clk;
assign TP1 = 1'b0;

endmodule
