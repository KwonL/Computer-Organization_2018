`define WORD_SIZE 16
`define s 4

`include "opcodes.v"

/*
 * this module is branch predictor.
 * predicting logic is quite simple. 
 * 
 * it has 2-bit state register. if prediction correct then ++
 * and if not, -- state. state's description below
 * 
 * state
 *          0: strongly not taken
 *          1: weakly not taken
 *          2: weakly taken
 *          3: strongly taken
 *
 */
// module Branch_predictor (
//     input clk,
//     input prev_taken,

//     input [`WORD_SIZE-1:0] PC,

//     input send_addr_sig,
//     input [`WORD_SIZE-1:0] PC_prev,
//     input [`WORD_SIZE-1:0] Actual_address,
    
//     output taken,
//     output [`WORD_SIZE-1:0] target_addr
// );

//     integer recorded_num = 0;
//     integer correct = 0;
//     integer incorrect = 0;
    
//     reg [`WORD_SIZE-1:0] BTB [0:2**`s-1];
//     reg [`WORD_SIZE-`s-1:0] tag [0:2**`s-1];
//     reg [1:0] state [0:2**`s-1];
    
//     // initialize predictor
//     integer i;
//     initial begin
//         for (i = 0; i < 2**`s; i = i + 1) begin
//             BTB[i] <= 0;
//             tag[i] <= 0;
//             state[i] <= 2'b10;
//         end
//     end

//     wire taken = 0;
//     wire [`WORD_SIZE-1:0] target_addr = 0;

//     wire [`s-1:0] index; 
//     assign index = PC[`s-1:0];
//     wire [`WORD_SIZE-`s-1:0] tag_in;
//     assign tag_in = PC[`WORD_SIZE-1:`s];

//     wire [`s-1:0] index_prev;
//     assign index_prev = PC_prev[`s-1:0];
//     wire [`WORD_SIZE-`s-1:0] tag_prev;
//     assign tag_prev = PC_prev[`WORD_SIZE-1:`s];

//     // this is failed
//     // // 
//     // always @ (index) begin
//     //     if ((BTB[index] != 0) && (tag[index] == tag_in) && (state[index] >= 2'b10)) begin
//     //         taken = 1;
//     //         target_addr = BTB[index];
//     //     end
//     //     else begin
//     //         taken = 0;
//     //         target_addr = 0;
//     //     end
//     // end

//     // taken is logical output, if BTB is not null and tag match and state >= 2, then 1
//     assign taken = (BTB[index] != 0 && tag[index] == tag_in && state[index] >= 2'b10) ?
//                     1 :
//                     0;
//     // same with taken, output is predicted address
//     assign target_addr = (BTB[index] != 0 && tag[index] == tag_in && state[index] >= 2'b10) ?
//                     BTB[index] :
//                     0;

//     always @ (posedge clk) begin
//         if (send_addr_sig) begin
//             // if BTB is null, then init BTB
//             if (BTB[index_prev] == 0) begin
//                 if (Actual_address != PC_prev + 1) begin
//                     BTB[index_prev] <= Actual_address;
//                     tag[index_prev] <= tag_prev;

//                     recorded_num <= recorded_num + 1;
//                 end
//             end
//             // if tag match and prediction wrong, then rewrite BTB and -- state
//             else if (tag[index_prev] == tag_prev && (BTB[index_prev] != Actual_address)) begin
//                 state[index_prev] <= state[index_prev] - 1;
//                 // if Actual address is just PC + 1, then do not record it
//                 if (Actual_address != PC_prev + 1) begin
//                     BTB[index_prev] <= Actual_address;
//                     tag[index_prev] <= tag_prev;

//                     recorded_num <= recorded_num + 1;
//                     // only count for predicted result
//                     if (prev_taken) incorrect <= incorrect + 1;
//                 end
//             end
//             // if tag match and prediction correct, then ++ state
//             else if (tag[index_prev] == tag_prev && (BTB[index_prev] == Actual_address)) begin
//                 state[index_prev] <= state[index_prev] + 1;

//                 // only count for predicted result
//                 if (prev_taken) correct <= correct + 1;
//             end
//             // rewrite BTB for new PC <= collision occured
//             else begin
//                 BTB[index_prev] <= Actual_address;
//                 tag[index_prev] <= tag_prev;
//                 state[index_prev] <= 2'b10;

//                 recorded_num <= recorded_num + 1;
//                 // only count for predicted result
//                 if (prev_taken) incorrect <= incorrect + 1;
//             end
//         end
//     end

// endmodule 


// this is for comparision.
// always taken module
// 띠용~ 이게 더 빠르네 ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ
module Branch_predictor (
    input clk,
    input prev_taken,

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
    
    // initialize predictor
    integer i;
    initial begin
        for (i = 0; i < 2**`s; i = i + 1) begin
            BTB[i] <= 0;
            tag[i] <= 0;
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

    // taken is logical output, if BTB is not null and tag match and state >= 2, then 1
    assign taken = (BTB[index] != 0 && tag[index] == tag_in) ?
                    1 :
                    0;
    // same with taken, output is predicted address
    assign target_addr = (BTB[index] != 0 && tag[index] == tag_in) ?
                    BTB[index] :
                    0;

    always @ (posedge clk) begin
        if (send_addr_sig) begin
            // if BTB is null, then init BTB
            if (BTB[index_prev] == 0) begin
                if (Actual_address != PC_prev + 1) begin
                    BTB[index_prev] <= Actual_address;
                    tag[index_prev] <= tag_prev;

                    recorded_num <= recorded_num + 1;
                end
            end
            // if tag match and prediction wrong, then rewrite BTB and -- state
            else if (tag[index_prev] == tag_prev && (BTB[index_prev] != Actual_address)) begin
                // if Actual address is just PC + 1, then do not record it
                if (Actual_address != PC_prev + 1) begin
                    BTB[index_prev] <= Actual_address;
                    tag[index_prev] <= tag_prev;

                    recorded_num <= recorded_num + 1;
                    // only count for predicted result
                    if (prev_taken) incorrect <= incorrect + 1;
                end
            end
            // if tag match and prediction correct, then ++ state
            else if (tag[index_prev] == tag_prev && (BTB[index_prev] == Actual_address)) begin

                // only count for predicted result
                if (prev_taken) correct <= correct + 1;
            end
            // rewrite BTB for new PC <= collision occured
            else begin
                BTB[index_prev] <= Actual_address;
                tag[index_prev] <= tag_prev;

                recorded_num <= recorded_num + 1;
                // only count for predicted result
                if (prev_taken) incorrect <= incorrect + 1;
            end
        end
    end

endmodule 