//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/03/15 00:43:22
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define	OP_ADD  4'b0000
`define	OP_SUB	4'b0001
//  Bitwise Boolean operation
`define	OP_ID	4'b0010
`define	OP_NAND	4'b0011
`define	OP_NOR	4'b0100
`define	OP_XNOR	4'b0101
`define	OP_NOT	4'b0110
`define	OP_AND	4'b0111
`define	OP_OR	4'b1000
`define	OP_XOR	4'b1001
// Shifting
`define	OP_LRS	4'b1010
`define	OP_ARS	4'b1011
`define	OP_RR	4'b1100
`define	OP_LLS	4'b1101
`define	OP_ALS	4'b1110
`define	OP_RL	4'b1111


module ALU(
    input [15:0] A,
    input [15:0] B,
    input Cin,
    input [3:0] OP,
    output reg Cout,
    output reg [15:0] C
    );
    reg[16:0] temp;
    
    always @(*) begin
        case (OP)
            //OP_ADD and OP_SUB need one more bit to caculate overflow bit
            `OP_ADD : begin
                temp = A + B + {15'b0, Cin};
                C = temp[15:0];
                Cout = temp[16];
            end

            `OP_SUB : begin
                //using two's complement
                temp = Cin ? A + ~B : A + ~B + 16'b1;
                //Carry is overflow bit
                Cout = temp[16];
                C = temp[15:0];
            end

            `OP_ID : begin
                C = A;
                Cout = 0;
            end

            `OP_NAND : begin
                C = ~(A & B);
                Cout = 0;
            end

            `OP_NOR : begin
                C = ~(A | B);
                Cout = 0;
            end

            `OP_XNOR : begin
                C = ~(A ^ B);
                Cout = 0;
            end

            `OP_NOT : begin
                C = ~A;
                Cout = 0;
            end

            `OP_AND : begin
                C = A & B;
                Cout = 0;
            end

            `OP_OR : begin
                C = A | B;
                Cout = 0;
            end
            `OP_XOR : begin 
                C = A ^ B;
                Cout = 0;
            end

            `OP_LRS : begin
                C = A >> 1;
                Cout = 0;
            end

            `OP_ARS : begin
                //add 1 to MSB if A's MSB is 1
                //C = A[15] ? ((A >> 1) | 16'h8000) : (A >> 1);
                C = (A >> 1) | {A[15], 15'b0};
                Cout = 0;
            end

            `OP_RR : begin
                //add 1 to MSB if A's LSB is 1
                //C = A[0] ? ((A >> 1) | 16'h8000) : A >> 1;
                C = (A >> 1) | {A[0], 15'b0};
                Cout = 0;
            end

            `OP_LLS : begin 
                C = A << 1;
                Cout = 0;
            end

            //ALS = LLS..
            `OP_ALS :  begin
                C = A <<< 1;
                Cout = 0;
            end

            `OP_RL : begin
                //add 1 to LSB if A's MSB is 1
                //C = A[15] ? ((A << 1) | 16'b1) : A << 1;
                C = (A << 1) | {15'b0, A[15]};
                Cout = 0;
            end

            default : begin
                C = A;
                Cout = 0;
            end
        endcase
    end
endmodule
