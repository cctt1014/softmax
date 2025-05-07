`timescale 1ns / 1ps


module decoder #(
    parameter BITWIDTH = 32
) (
    input 	wire 			           	Clock,
    input 	wire           				Reset,
    input   wire                        Start,
    input	wire    [2:0] 	            Datain,
    output reg                          DataOut_vld,
    output reg      [BITWIDTH-1:0]	    DataOut
);


always @(posedge Clock) begin 
	if (Reset) begin
        DataOut <= 0;
        DataOut_vld <= 0;
	end else begin
        if (Start) begin
            DataOut_vld <= 1;
            case (Datain)
                3'b000: DataOut <= 32'h3f800000; // 1/1 = 1
                3'b001: DataOut <= 32'h3f638e39; // 1/1.125 = 0.888888895511627197265625
                3'b010: DataOut <= 32'h3f4ccccd; // 1/1.25 = 0.800000011920928955078125
                3'b011: DataOut <= 32'h3f3a2e8c; // 1/1.375 = 0.7272727489471435546875
                3'b100: DataOut <= 32'h3f2aaaab; // 1/1.5 = 0.666666686534881591796875
                3'b101: DataOut <= 32'h3f1d89d9; // 1/1.625 = 0.615384638309478759765625
                3'b110: DataOut <= 32'h3f124925; // 1/1.75 = 0.571428596973419189453125
                3'b111: DataOut <= 32'h3f088889; // 1/1.875 = 0.5333333616943359375
                default: DataOut <= 32'hFFFFFFFF; // ERROR
            endcase
        end else begin
            DataOut <= 32'h00000000;
            DataOut_vld <= 0;
        end
	end
end

endmodule
