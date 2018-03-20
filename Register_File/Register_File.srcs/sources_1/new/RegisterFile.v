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
    input [1:0] Addr1,
    input [1:0] Addr2,
    input [1:0] Addr3,
    input [15:0] Data3,
    input Write,
    input Clock,
    input reset_n,
    output [15:0] Data1,
    output [15:0] Data2
    );
    reg [15:0] Data1, Data2;
    reg [15:0] register[0:3];
    
    //initialize register
    initial begin
        
    end
    
    //output is always data of register which is selected
    always @(posedge Clock) begin
        Data1 <= register[Addr1];
        Data2 <= register[Addr2];
    end
    
    //Write data at positive clock if enable is 1
    always @(posedge Clock) begin   
        if (Write == 1) begin
            register[Addr3] <= Data3;
        end
    end

    always @(reset_n) begin
        if (reset_n == 1) begin
            register[0] <= 0;
            register[1] <= 0;
            register[2] <= 0;
            register[3] <= 0;
        end
    end

endmodule
