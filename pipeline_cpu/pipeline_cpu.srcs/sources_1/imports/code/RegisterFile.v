//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/03/20 20:50:29
// Design Name: 
// Module Name: RegisterFile
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


module RegisterFile(
    input [1:0] addr1,
    input [1:0] addr2,
    input [1:0] addr3,
    input [15:0] data3,
    input write,
    input clk,
    input reset_n,
    output [15:0] data1,
    output [15:0] data2
    );
    //addr is 2-bit, so register # is 4 = 2^2
    reg [15:0] register[0:3];
    
    //initialize register
    initial begin
        register[0] <= 0;
        register[1] <= 0;
        register[2] <= 0;
        register[3] <= 0;        
    end
    
    //output is always data of register which is selected
    assign data1 = register[addr1];
    assign data2 = register[addr2];
    
    //Write data at positive clk if enable is 1
    always @(negedge clk) begin   
        if (write == 1) begin
            register[addr3] <= data3;
        end
    end
    
    // reset all register to 0
    always @(*) begin
        if (reset_n == 0) begin
            register[0] <= 0;
            register[1] <= 0;
            register[2] <= 0;
            register[3] <= 0;
        end
    end

endmodule
