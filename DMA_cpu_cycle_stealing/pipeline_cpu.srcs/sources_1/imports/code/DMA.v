`define WORD_SIZE 16
/*************************************************
* DMA module (DMA.v)
* input: clock (CLK), bus request (BR) signal, 
*        data from the device (edata), and DMA command (cmd)
* output: bus grant (BG) signal 
*         READ signal
*         memory address (addr) to be written by the device, 
*         offset device offset (0 - 2)
*         data that will be written to the memory
*         interrupt to notify DMA is end
* You should NOT change the name of the I/O ports and the module name
* You can (or may have to) change the type and length of I/O ports 
* (e.g., wire -> reg) if you want 
* Do not add more ports! 
*************************************************/

module DMA (
    input CLK, BG,
    input [4 * `WORD_SIZE - 1 : 0] edata,
    // cmd = size(upper 4-bit) + address(lower 16-bit)
    input [`WORD_SIZE-1+4:0] cmd,
    output reg BR, 
    output READ,
    output [`WORD_SIZE - 1 : 0] addr, 
    output [4 * `WORD_SIZE - 1 : 0] data,
    output reg [1:0] offset,
    output reg interrupt
);

    // internel registers
    reg [`WORD_SIZE-1:0] temp_addr;
    reg [3:0] temp_size;
    reg [4*`WORD_SIZE-1:0] temp_data;

    /* Implement your own logic */
    always @ (posedge CLK) begin
        // if CPU send cmd
        if (cmd == {4'd12, 16'h01f4}) begin
            BR <= 1;
            interrupt <= 0;
            temp_addr <= cmd[`WORD_SIZE-1:0];
            temp_size <= cmd[`WORD_SIZE-1+4:`WORD_SIZE];
        end
        // not finished yet
        else if (offset < 3 && offset > 0) begin
            BR <= 1;
        end
        // Bus granted, send data
        if (BG == 1) begin
            // count offset and yield BUS to CPU
            if (offset < 2) begin
                offset <= offset + 1;
                BR <= 0;
            end
            // as initialize offset, yield BUS
            else begin
                offset <= 0;
                BR <= 0;
                interrupt <= 1;
            end
        end
    end

    initial begin
        BR <= 0;
        offset <= 0;
        interrupt <= 0;
    end

    // if Bus grnated then read memory
    // else, float READ port
    assign READ = BG ? (BR ? 1 : 0) : 1'bz;
    assign addr = BG ? temp_addr + 4*offset : 16'bz;
    assign data = BG ? edata : 64'bz;

endmodule


