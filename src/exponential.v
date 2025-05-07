`timescale 1ns / 1ps


module exponential #(
    parameter BITWIDTH = 32, 
    parameter INPUTMAX = 5
) (
    input 	wire 			           	Clock,
    input 	wire           				Reset,
    input   wire                        Start,
    input	wire    [BITWIDTH-1:0] 	    Datain,
    output reg                          Ack,
    output reg      [BITWIDTH-1:0]	    DataOut	
);

wire [BITWIDTH-1:0] one, oversix, half;
reg [BITWIDTH-1:0] Count;
reg [BITWIDTH-1:0]	T0;
wire [BITWIDTH-1:0] T1,T2,Ts,Td,Tc,To,Tsh;

wire wa_add_1,wb_add_1,wz_add_1;
wire wa_add_2,wb_add_2,wz_add_2;
wire wa_add_3,wb_add_3,wz_add_3;
wire wa_mul_1,wb_mul_1,wz_mul_1;
wire wa_mul_2,wb_mul_2,wz_mul_2;
wire wa_sh_1,wb_sh_1,wz_sh_1;
wire wa_div_1,wb_div_1,wz_div_1;

assign one = 32'h3f800000;
assign oversix = 32'h3e2aaaab ;
assign half = 32'h3f000000;

adder A1 (        
    one,
    T0,
    Start,
    Start,
    Start,
    Clock,
    Reset,
    T1,
    wz_add_1,
    wa_add_1,
    wb_add_1
);

multiplier Ms (        
    T0,
    T0,
    wa_add_1,
    wb_add_1,
    wz_add_1,
    Clock,
    Reset,
    Ts,
    wz_mul_1,
    wa_mul_1,
    wb_mul_1
);

multiplier Msh (
    half,
    Ts,
    wa_mul_1,
    wb_mul_1,
    wz_mul_1,
    Clock,
    Reset,
    Tsh,
    wz_sh_1,
    wa_sh_1,
    wb_sh_1
);

adder A2 (        
    T1,
    Tsh,
    wa_sh_1,
    wb_sh_1,
    wz_sh_1,
    Clock,
    Reset,
    T2,
    wz_add_2,
    wa_add_2,
    wb_add_2
);

multiplier Mc (        
    Ts,
    Ts,
    wa_add_2,
    wb_add_2,
    wz_add_2,
    Clock,
    Reset,
    Tc,
    wz_mul_2,
    wa_mul_2,
    wb_mul_2
);

multiplier Dm (
    Tc,
    oversix,
    wa_mul_2,
    wb_mul_2,
    wz_mul_2,
    Clock,
    Reset,
    Td,
    wz_div_1,
    wa_div_1,
    wb_div_1
);

adder A3 (        
    Td,
    T2,
    wa_div_1,
    wb_div_1,
    wz_div_1,
    Clock,
    Reset,
    To,
    wz_add_3,
    wa_add_3,
    wb_add_3
);

always @(posedge Clock) begin 
	if(Reset) begin
        T0 <= 0;
        DataOut <= 0;
        Ack <= 0;
        Count <= 0;
	end else begin
        if (Start) begin
    		T0 <= Datain;
            DataOut <= To;
            if (Count == 140)
                Ack <= 1;
            Count <= Count +1;
        end
        else 
            T0 <= 32'h00000000;
	end
end

endmodule
