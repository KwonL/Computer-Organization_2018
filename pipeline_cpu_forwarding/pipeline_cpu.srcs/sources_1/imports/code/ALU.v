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
`define	OP_ORR	4'b0010
`define	OP_NOT	4'b0011
`define	OP_TCP	4'b0100
`define	OP_SHL	4'b0101
`define	OP_SHR	4'b0110
`define	OP_ADI	4'b0111
`define	OP_ORI	4'b1000
`define	OP_LHI	4'b1001
// branch
`define	OP_BNE	4'b1010
`define	OP_BEQ	4'b1011
`define	OP_BGZ	4'b1100
`define	OP_BLZ	4'b1101
`define OP_AND  4'b1110
`define OP_ID   4'b1111


module ALU(
    input [15:0] A,
    input [15:0] B,
    input [3:0] OP,
    output reg [15:0] C,
    output reg Zero
    );
    
    always @(*) begin
        case (OP)
            `OP_ADD : begin
                Zero = 0;
                C = A + B;
            end

            `OP_SUB : begin
                Zero = 0;
                C = A - B;
            end

            `OP_AND : begin
                Zero = 0;
                C = A & B;
            end

            `OP_ORR : begin
                C = A | B;
                Zero = 0;
            end

            `OP_NOT : begin
                Zero = 0;
                C = ~A;
            end

            `OP_TCP : begin
                Zero = 0;
                C = ~A + 1;
            end

            `OP_SHL : begin
                Zero = 0;
                C = A << 1;
            end

            `OP_SHR : begin
                Zero = 0;
                C = {A[15], A[15:1]};
            end

            `OP_ADI : begin
                Zero = 0;
                C = A + B;
            end

            `OP_ORI : begin
                Zero = 0;
                C = A | {8'b0, B};
            end

            `OP_LHI : begin 
                Zero = 0;
                C = {B[7:0], 8'b0};
            end

            `OP_BNE : begin
                Zero = (A != B);
            end

            `OP_BEQ : begin
                Zero = (A == B);
            end

            `OP_BGZ : begin 
                if (A != 0) Zero = ~A[15];
                else Zero = 0;
            end

            `OP_BLZ : begin
                Zero = A[15];
            end
            
            `OP_ID : begin
                Zero = 0;
                C = A;
            end
        endcase
    end
endmodule
