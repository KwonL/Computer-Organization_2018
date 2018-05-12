`define WORD_SIZE 16
`define s 4

`include "opcodes.v"

module Branch_predictor (
    input clk,

    input [`WORD_SIZE-1:0] PC,

    input send_addr_sig,
    input [`WORD_SIZE-1:0] PC_prev,
    input [`WORD_SIZE-1:0] Actual_address,
    
    output taken,
    output [`WORD_SIZE-1:0] target_addr
);

    integer recorded_num = 0;
    integer correct = 0;
    integer incorrect = 0;
    
    reg [`WORD_SIZE-1:0] BTB [0:2**`s-1];
    reg [`WORD_SIZE-`s-1:0] tag [0:2**`s-1];
    reg [1:0] state [0:2**`s-1];
    
    // initialize predictor
    integer i;
    initial begin
        for (i = 0; i < 2**`s; i = i + 1) begin
            BTB[i] <= 0;
            tag[i] <= 0;
            state[i] <= 2'b10;
        end
    end

    wire taken = 0;
    wire [`WORD_SIZE-1:0] target_addr = 0;

    wire [`s-1:0] index; 
    assign index = PC[`s-1:0];
    wire [`WORD_SIZE-`s-1:0] tag_in;
    assign tag_in = PC[`WORD_SIZE-1:`s];

    wire [`s-1:0] index_prev;
    assign index_prev = PC_prev[`s-1:0];
    wire [`WORD_SIZE-`s-1:0] tag_prev;
    assign tag_prev = PC_prev[`WORD_SIZE-1:`s];

    // // 
    // always @ (index) begin
    //     if ((BTB[index] != 0) && (tag[index] == tag_in) && (state[index] >= 2'b10)) begin
    //         taken = 1;
    //         target_addr = BTB[index];
    //     end
    //     else begin
    //         taken = 0;
    //         target_addr = 0;
    //     end
    // end
    assign taken = (BTB[index] != 0 && tag[index] == tag_in && state[index] >= 2'b10) ?
                    1 :
                    0;
    assign target_addr = (BTB[index] != 0 && tag[index] == tag_in && state[index] >= 2'b10) ?
                    BTB[index] :
                    0;

    always @ (posedge clk) begin
        if (send_addr_sig) begin
            if (BTB[index_prev] == 0) begin
                if (Actual_address != PC_prev + 1) begin
                    BTB[index_prev] <= Actual_address;
                    tag[index_prev] <= tag_prev;

                    recorded_num <= recorded_num + 1;
                end
            end
            else if (tag[index_prev] == tag_prev && (BTB[index_prev] != Actual_address)) begin
                state[index_prev] <= state[index_prev] - 1;
                if (Actual_address != PC_prev + 1) begin
                    BTB[index_prev] <= Actual_address;
                    tag[index_prev] <= tag_prev;

                    recorded_num <= recorded_num + 1;
                    incorrect <= incorrect + 1;
                end
            end
            else if (tag[index_prev] == tag_prev && (BTB[index_prev] == Actual_address)) begin
                state[index_prev] <= state[index_prev] + 1;

                correct <= correct + 1;
            end
            else begin
                BTB[index_prev] <= Actual_address;
                tag[index_prev] <= tag_prev;

                recorded_num <= recorded_num + 1;
                incorrect <= incorrect + 1;
            end
        end
    end

endmodule 