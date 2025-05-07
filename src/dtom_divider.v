//IEEE Floating Point Divider (Single Precision)
//Copyright (C) Jonathan P Dawson 2013
//2013-12-12
//
module dtom_divider (
    dividend,
    divisor,
    dividend_strb,
    divisor_strb,
    output_z_ack,
    clk,
    rst,
    output_z,
    output_z_strb
);
    input     clk;
    input     rst;  

    input     [31:0] dividend;
    input     dividend_strb;
    input     [31:0] divisor;
    input     divisor_strb;

    output reg    [31:0] output_z;
    output reg           output_z_strb;
    
    input     output_z_ack;
    
    wire [31:0] decoder_out;
    wire decoder_out_vld;
    
    wire [31:0] multiplier_out;
    wire multiplier_out_vld;
    wire mul_in_a_ack;
    wire mul_in_b_ack;

    reg [31:0] shifter_out;
    reg shifter_out_vld;
    wire is_r_shift;

    // Convert divisor to 1/m + 1/(2^n) form
    // 1. Get divisor's 1/m from decoder
    decoder div_decoder_u (
        clk,
        rst,
        divisor_strb,
        divisor[22:20],
        decoder_out_vld,
        decoder_out
    );

    // 2. Multiply dividend by 1/m
    multiplier div_multiplier_u (
        dividend,
        decoder_out,
        dividend_strb,
        decoder_out_vld,
        output_z_ack,
        clk,
        rst,
        multiplier_out,
        multiplier_out_vld,
        mul_in_a_ack,
        mul_in_b_ack
    );

    // 3. Shift resulting dividend by -n bits
    //    to multiply 1/(2^n)
    assign is_r_shift = (divisor[30:23] > 8'h7f)? 1'b1 : 1'b0;
    always @(posedge clk) begin
        if (rst == 1) begin
            shifter_out <= 0;
            shifter_out_vld <= 0;
        end else begin
            if (multiplier_out_vld == 1) begin
                // keep sign bit
                shifter_out[31] <= multiplier_out[31];

                // shift exponent
                if (is_r_shift == 1) begin
                    shifter_out[30:23] <= multiplier_out[30:23] - (divisor[30:23] - 8'h7f);
                end else begin
                    shifter_out[30:23] <= multiplier_out[30:23] + (8'h7f - divisor[30:23]);
                end
                
                // keep mantissa
                shifter_out[22:0] <= multiplier_out[22:0];
                
                shifter_out_vld <= 1;
            end
        end
    end


    always @(posedge clk) begin
        if (rst == 1) begin
            output_z <= 0;
            output_z_strb <= 0;
        end else begin
            output_z <= shifter_out;
            output_z_strb <= shifter_out_vld;
        end
    end

endmodule

