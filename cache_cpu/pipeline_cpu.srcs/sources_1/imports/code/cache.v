`define WORD_SIZE 16
/*
 *
 */
module cache_unit(
    input clk,
    input reset_n,
    // instruction cache part
    // communication with CPU
    input i_readC,
    input [`WORD_SIZE-1:0] i_address_to_C,
    output reg [`WORD_SIZE-1:0] i_data,
    output reg i_hit,
    
    // communication with Memory
    input i_send_data,
    output [`WORD_SIZE-1:0] i_address,
    output reg i_readM,
    input [4*`WORD_SIZE-1:0] i_data_block,
    
    // data cache part
    // communication with CPU
    input d_readC,
    input d_writeC,
    input [`WORD_SIZE-1:0] d_address_to_C,
    inout [`WORD_SIZE-1:0] d_data,
    output reg d_hit,

    // communication with Memory
    input d_send_data,
    output [`WORD_SIZE-1:0] d_address,
    output reg d_readM,
    output reg d_writeM,
    inout [4*`WORD_SIZE-1:0] d_data_block
);

    // i-cache
    // one line consists of four word
    reg [`WORD_SIZE-1:0] i_cache [0:3][0:3];
    reg [11:0] i_tag [0:3];

    wire [11:0] i_input_tag = i_address_to_C[15:4];
    wire [1:0] i_input_index = i_address_to_C[3:2];
    wire [1:0] i_input_offset = i_address_to_C[1:0];

    integer i;
    // wire for forwarding i_data from memory
    wire [`WORD_SIZE-1:0] i_temp_data [3:0];
    assign i_temp_data[0] = i_data_block[4*`WORD_SIZE-1:3*`WORD_SIZE];
    assign i_temp_data[1] = i_data_block[3*`WORD_SIZE-1:2*`WORD_SIZE];
    assign i_temp_data[2] = i_data_block[2*`WORD_SIZE-1:`WORD_SIZE];
    assign i_temp_data[3] = i_data_block[`WORD_SIZE-1:0];
    ///////////////////////////////////////////

    // send address
    assign i_address = {i_address_to_C[`WORD_SIZE-1:2], 2'b00};

    // i_hit block
    always @ (posedge clk) begin
        // reset cache
        if (reset_n == 0) begin
            i_hit <= 0;
            for (i = 0; i < 4; i = i+1) begin
                i_tag[i] <= -1;
            end
            i_readM <= 1;
        end
        else begin
            // if cache hit occur
            if (i_readC && (i_input_tag == i_tag[i_input_index])) begin
                i_hit <= 1;
                i_data <= i_cache[i_input_index][i_input_offset];
                i_readM <= 0;
            end
            // read miss, send data request to memory
            else if (i_readC) begin
                i_hit <= 0;
                i_readM <= 1;
            end 
            else begin
                i_hit <= 0;
                i_readM <= 0;
            end
            if (i_send_data) begin
                i_cache[i_input_index][0] <= i_data_block[4*`WORD_SIZE-1:3*`WORD_SIZE];
                i_cache[i_input_index][1] <= i_data_block[3*`WORD_SIZE-1:2*`WORD_SIZE];
                i_cache[i_input_index][2] <= i_data_block[2*`WORD_SIZE-1:`WORD_SIZE];
                i_cache[i_input_index][3] <= i_data_block[`WORD_SIZE-1:0];
                i_tag[i_input_index] <= i_input_tag;
                // send data to CPU
                i_hit <= 1;
                i_data <= i_temp_data[i_input_offset];
            end
        end
    end


    reg d_data_internel;
    assign d_data = d_readC ? d_data_internel : 16'bz;
    // d-cache
    // one line consists of four word
    reg [`WORD_SIZE-1:0] d_cache [0:3][0:3];
    reg [11:0] d_tag [0:3];
    wire [11:0] d_input_tag = d_address_to_C[15:4];
    wire [1:0] d_input_index = d_address_to_C[3:2];
    wire [1:0] d_input_offset = d_address_to_C[1:0];

    // wire for forwarding d_data from memory
    wire [`WORD_SIZE-1:0] d_temp_data [3:0];
    assign d_temp_data[0] = d_data_block[4*`WORD_SIZE-1:3*`WORD_SIZE];
    assign d_temp_data[1] = d_data_block[3*`WORD_SIZE-1:2*`WORD_SIZE];
    assign d_temp_data[2] = d_data_block[2*`WORD_SIZE-1:`WORD_SIZE];
    assign d_temp_data[3] = d_data_block[`WORD_SIZE-1:0];
    ///////////////////////////////////////////

    // send address
    assign d_address = {d_address_to_C[`WORD_SIZE-1:2], 2'b00};

    // d_hit block
    always @ (posedge clk) begin
        // reset cache
        if (reset_n == 0) begin
            d_hit <= 0;
            for (i = 0; i < 4; i = i+1) begin
                d_tag[i] <= -1;
            end
            d_readM <= 0;
            d_writeM <= 0;
        end
        else begin
            // if cache hit occur
            if (d_readC && (d_input_tag == d_tag[d_input_index])) begin
                d_hit <= 1;
                d_data_internel <= d_cache[d_input_index][d_input_offset];
                d_readM <= 0;
            end
            // read miss, send data request to memory
            else if (d_readC) begin
                d_hit <= 0;
                d_readM <= 1;
            end 
            else begin
                d_hit <= 0;
                d_readM <= 0;
            end
            if (d_send_data) begin
                d_cache[d_input_index][0] <= d_data_block[4*`WORD_SIZE-1:3*`WORD_SIZE];
                d_cache[d_input_index][1] <= d_data_block[3*`WORD_SIZE-1:2*`WORD_SIZE];
                d_cache[d_input_index][2] <= d_data_block[2*`WORD_SIZE-1:`WORD_SIZE];
                d_cache[d_input_index][3] <= d_data_block[`WORD_SIZE-1:0];
                d_tag[d_input_index] <= d_input_tag;
                // send data to CPU
                d_hit <= 1;
                d_data_internel <= d_temp_data[d_input_offset];
            end
        end
    end


endmodule