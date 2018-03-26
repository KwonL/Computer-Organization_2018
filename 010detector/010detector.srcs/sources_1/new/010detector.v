//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/03/20 20:46:10
// Design Name: 
// Module Name: 010detector
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


module detector(
    input in,
    input clk,
    output out
    );
    reg out;
    reg [1:0] state;
    reg [1:0] nextstate;

    //initializing state
    initial begin
        state <= 0;
    end

    //always block for state alloc
    always @(posedge clk) begin
        state <= nextstate;    
    end

    //always block for next state
    always @(in or state) begin
        case (state)
            0 : nextstate <= (in == 0) ? 1 : 0;
            1 : nextstate <= (in == 1) ? 2 : 1;
            2 : nextstate <= (in == 0) ? 3 : 0;
            3 : nextstate <= (in == 0) ? 1 : 2;
        endcase
    end

    //alwyas block for output logic
    always @(state) begin
        case (state) 
            0 : out <= 0;
            1 : out <= 0;
            2 : out <= 0;
            3 : out <= 1;
            default : out <= 0;
        endcase
    end

endmodule