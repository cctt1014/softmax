`timescale 1ns / 1ps
`define IDLE 			3'b000
`define INPUTSTREAM 	3'b001
`define EXP				3'b010
`define ADD				3'b011
`define DIV				3'b100
`define OUTPUTSTREAM    3'b101

module dtom_softmax # (
	parameter BITWIDTH = 32,
	parameter INPUTMAX = 2
)(
	input wire 						Clock,
	input wire 						Reset,
	input wire						Start,
	input wire 	[BITWIDTH-1:0] 		Datain,
	input wire	[INPUTMAX:0]		N,
	output reg  [BITWIDTH-1:0] 		Dataout,
	output wire 					Dataout_vld
);


reg [BITWIDTH-1:0] 	InputBuffer[2**INPUTMAX - 1:0];
reg [BITWIDTH-1:0] 	DivBuffer[2**INPUTMAX - 1:0];

reg [BITWIDTH-1:0] 	OutputBuffer[2**INPUTMAX -1 :0];
reg [BITWIDTH-1:0]	Acc;
reg [BITWIDTH-1:0]	Arg;

wire [BITWIDTH-1:0]	Acc_w;
wire [BITWIDTH-1:0] Acc_shifted;
wire [BITWIDTH-1:0] Acc_float;

reg  [2**INPUTMAX-1:0] EXP_Start;

wire [BITWIDTH-1:0] 	InputBuffer_w[2**INPUTMAX -1 :0];
wire [BITWIDTH-1:0] 	OutputBuffer_w[2**INPUTMAX -1 :0];

wire 					[2**INPUTMAX-1:0] EXP_out_vld;
reg 					Str_Add_a;
reg 					Str_Add_b;
reg 					Str_Add_z;
wire 					Ack_add1;
wire 					Ack_add2;
wire 					Ack_add3;
reg 					Ack_div1;
reg 					Ack_div2;
reg 					Ack_div3;
wire 					[3:0]Ack_div_a;
wire 					[3:0]Ack_div_b;
wire 					[3:0]div_z_strb;

reg [INPUTMAX:0] 	Counter;
reg [INPUTMAX:0] 	C,C_add;

reg [2:0] 			NextState;

assign Dataout_vld = (NextState == `OUTPUTSTREAM) ? 1 : 0;


genvar i;
generate
for (i = 0; i < 2**INPUTMAX; i++) begin
	shifter shifter_u (
		Clock,
		Reset,
		EXP_Start[i],
		InputBuffer[i],
		EXP_out_vld[i],
		InputBuffer_w[i]
	);
end
endgenerate


adder add (
	Arg,
	Acc,
	Str_Add_a,
	Str_Add_b,
	Str_Add_z,
	Clock,
	Reset,
	Acc_w,
	Ack_add3,
	Ack_add1,
	Ack_add2
);


genvar k;
generate
for (k = 0; k < 2**INPUTMAX; k++) begin 
dtom_divider div (
	DivBuffer[k],
	Acc,
	Ack_div1,
	Ack_div2,
	Ack_div3,
	Clock,
	Reset,
	OutputBuffer_w[k],
	div_z_strb[k]
);
end
endgenerate


always @(posedge Clock) begin
	if (Reset) begin
		// reset
		Counter <= 0;
		C <= 0;
		Arg <= 0;
		C_add <= 0;
		Dataout <= 0;
		Acc <= 0;
		EXP_Start <= 0;
		Ack_div1 <=0;
		Ack_div2 <=0;
		Ack_div3 <=0;
		Str_Add_a <= 0;
		Str_Add_b <= 0;
		Str_Add_z <= 0;
		NextState <= `IDLE;

	end else begin
		case(NextState)

			`IDLE: begin
			if (Start)
				NextState <= `INPUTSTREAM;	
			else
				NextState <= `IDLE;
			end

			`INPUTSTREAM: begin
				if (Counter <= N) begin
					Counter <= Counter + 1;
					NextState <= `INPUTSTREAM;
				end else begin
					NextState <= `EXP;
					EXP_Start <= 4'b1111;
				end		
			end

			`EXP: begin
				if(EXP_out_vld == 4'b1111) begin     	       			
		     		NextState <= `ADD;
		     		Str_Add_a <= 1 ;
		      		Str_Add_b <= 1 ;
		     		Str_Add_z <= 1 ;
    	        end else begin
    	       		NextState <= `EXP;
    	        end
			end

    	    `ADD: begin        	
    	    	if (Ack_add2 || Ack_add1 || Ack_add3) begin
    	    		C_add <= C_add + 1;
    	    	end
    	    	if (C < 2**INPUTMAX+1) begin
    	    		Arg <= DivBuffer[C];
    	    		if (C_add == 4) begin
    		    		Acc <= Acc_w;
  						C <= C+1;
  						C_add <= 0;
  					end

    	    		NextState <= `ADD;
  				end else begin
    		 		Str_Add_a <= 1 ;
		      		Str_Add_b <= 1 ;
		     		Str_Add_z <= 1 ;

					NextState <= `DIV;
    			end 
			end

			`DIV: begin
    			Ack_div1 <= 1;
    			Ack_div2 <= 1;
    			Ack_div3 <= 0;
				if (div_z_strb == 4'b1111) begin
					NextState <= `OUTPUTSTREAM;
					Ack_div3  <= 1;
				end else begin
					NextState <= `DIV;
					Ack_div3 <= 0;
				end
			end

			`OUTPUTSTREAM: begin
				Counter <= Counter - 1;
				if (Counter != 0) begin
					Dataout <= OutputBuffer[Counter];
					NextState <= `OUTPUTSTREAM;
				end else begin
					NextState <= `IDLE;				
				end
			end

			default: begin
				NextState <= `IDLE;
			end

		endcase
	end
end


genvar m;
generate
for (m = 0; m < 2**INPUTMAX; m++) begin
	always @(posedge Clock) begin
		if (Reset) begin
			InputBuffer[m] <= 0;
			OutputBuffer[m] <= 0;
			DivBuffer[m] <= 0;
		end else begin
			case(NextState)
				`INPUTSTREAM: begin
					if ((Counter <= N) && (m == Counter)) begin
						InputBuffer[Counter] <= Datain;
					end
				end
				`EXP: begin
					if(EXP_out_vld == 4'b1111) begin 
						DivBuffer[m] <= InputBuffer_w[m];
					end
				end
				`DIV: begin
					if (div_z_strb == 4'b1111) begin
						OutputBuffer[m] <=  OutputBuffer_w[m];
					end
				end
			endcase
		end
	end
end
endgenerate
	
endmodule
