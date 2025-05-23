`timescale 1ns / 1ps


module shifter #(
    parameter BITWIDTH = 32, 
    parameter INPUTMAX = 5
) (
    input 	wire 			           	Clock,
    input 	wire           				Reset,
    input   wire                        Start,
    input	wire    [BITWIDTH-1:0] 	    Datain, // u_int32
    output reg                          DataOut_vld,
    output reg      [BITWIDTH-1:0]	    DataOut	
);

wire [BITWIDTH-1:0] result;

// Shift and convert from integer to IEEE 754 floating point format
assign result = {1'b0, 8'h7f + Datain, 23'h000000};

always @(posedge Clock) begin 
	if (Reset) begin
        DataOut <= 0;
        DataOut_vld <= 0;
	end else begin
        if (Start) begin
            DataOut <= result;
            DataOut_vld <= 1;
        end else begin
            DataOut <= 32'h00000000;
            DataOut_vld <= 0;
        end
	end
end

endmodule
