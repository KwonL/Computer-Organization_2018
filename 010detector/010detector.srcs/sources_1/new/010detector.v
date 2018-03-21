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
    reg [1:0] nextState;

    initial begin
        state <= 0;
        out <= 0;
    end

    //my fsm diagram is in report
    /*
     * this fsm is mealy machine, and to simplify code, 
     * there is no next state. (maybe need some bug testing..?)
     */
    always @(posedge clk) begin

        case (state)
        0 : begin
            out <= 0;
            state <= (in == 0) ? 1 : 0;
        end

        1 : begin
            out <= 0;
            state <= (in == 1) ? 2 : 1;
        end

        2 : begin
            out <= (in == 0) ? 1 : 0;
            state <= (in == 0) ? 1 : 0;
        end

        endcase

    end
endmodule
