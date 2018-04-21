`include "opcode.v"

module control_unit (
    input reset_n,
    input clk,
    input [3:0] opcode,
    input [5:0] func_code,

    output PCWriteCond,
    output PCWrite,
    output IorD,
    output MemRead,
    output MemWrite,
    output MemtoReg,
    output IRWrite,

    output PCSource,
    output [3:0] ALUOp,
    output [1:0] ALUSrcB,
    output ALUSrcA,
    output RegWrite,
    output RegDst
);
    /* Redef of output fegister */
    reg PCWriteCond = 0;
    reg PCWrite = 0;
    reg IorD = 0;
    reg MemRead = 0;
    reg MemWrite = 0;
    reg MemtoReg = 0;
    reg IRWrite = 0;

    reg PCSource = 0;
    reg [3:0] ALUOp = 0;
    reg [1:0] ALUSrcB = 0;
    reg ALUSrcA = 0;
    reg RegWrite = 0;
    reg RegDst = 0;
    //////////////////////////////////

    // register for state
    reg [2:0] state;
    reg [2:0] next_state;

    // initialize state
    initial begin
        state <= 0;
        next_state <= 1;
    end

    // block for state
    always @ (state) begin
        case (state)
            // IF stage -> ID stage
            0 : begin
                next_state = state + 1;
            end
            // ID stage -> EX stage
            1 : begin
                next_state = state + 1;
            end
            // EX stage -> ?
            2 : begin
                // only LWD and SWD instruction go to MEM stage
                if (opcode == `OPCODE_LWD | opocde == `OPCODE_SWD)
                    next_state = state + 1;
                else
                    next_state = state + 2;
            end
            // MEM stage
            3 : begin
                if (opcode == `OPCODE_LWD) next_state = state + 1;
                // SWD instruction goto IF
                else next_state = 0;
            end
            // WB stage
            4 : begin
                next_state = next_state + 1;
            end
        endcase
    end

    // update state
    always @ (posedge clk) state <= next_state;

    // block for output
    always @ (state or opcode or func_code) begin
        case (state)
            // IF stage
            0 : begin
                // PC = PC + 4
                RegWrite = 0;
                MemWrite = 0;
                PCWrite = 1;
                PCSource = 0;
                ALUSrcA = 0;
                ALUSrcB = 1;
                // insturction fetching
                IRWrite = 1;
                MemRead = 1;
            end
            // ID stage
            1 : begin
                // turn off signals
                PCWrite = 0;
                IRWrite = 0;
                MemRead = 0;
                // R-type
                if (opcode == 15)
                    RegDst = 1;
                else
                    RegDst = 0;
            end
            // EX stage
            2 : begin
                // R-type
                if (opcode == 15) begin
                    ALUSrcA = 1;
                    ALUSrcB = 0;
                    // select ALU operation
                    case (func_code) 
                        default : ALUOp = 0;
                    endcase
                end
                // branch or jump
                // need to add
                else if (opcode == `OPCODE_BEQ
                        |opcode == `OPCODE_BNE
                        |opcode == `OPCODE_BGZ
                        |opcode == `OPCODE_BLZ
                        |opcode == `OPCODE_JMP
                        |opcode == `OPCODE_JAL) begin
                    ALUSrcB = 3;
                    ALUSrcA = 0;
                    // add ALUOp...implementation..
                    case (opcode)
                    endcase
                end
                // SWD, LWD
                else begin
                    ALUSrcA = 1;
                    ALUSrcB = 2;
                    ALUOp = 0;
                end
            end
            // MEM stage
            3 : begin
                // read from alu out
                IorD = 1;
                if (opcode == `OPCODE_LWD) begin
                    MemRead = 1;
                    MemWrite = 0;
                end
                else begin
                    MemRead = 0;
                    MemWrite = 1;
                end
            end
            // WB stage
            4 : begin
                MemRead = 0;
                RegWrite = 1;
                if (opcode == `OPCODE_LWD) begin
                    MemtoReg = 1;
                end
                else begin
                    MemtoReg = 0;
                end
            end
        endcase
    end

endmodule
