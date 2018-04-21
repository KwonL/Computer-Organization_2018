`include "opcodes.v"
`include "ALU.v"

module control_unit (
    input reset_n,
    input clk,
    input [3:0] opcode,
    input [5:0] func_code,

    output PCWriteCond,
    output PCWrite,
    output PCWrite_t,
    output IorD,
    output MemRead,
    output MemWrite,
    output MemtoReg,
    output IRWrite,

    output [1:0] PCSource,
    output [3:0] ALUOp,
    output [1:0] ALUSrcB,
    output ALUSrcA,
    output RegWrite,
    output RegDst,
    output isWWD
);
    /* Redef of output fegister */
    reg PCWriteCond = 0;
    reg PCWrite = 0;
    reg IorD = 0;
    reg MemRead = 0;
    reg MemWrite = 0;
    reg MemtoReg = 0;
    reg IRWrite = 0;

    reg [1:0] PCSource = 0;
    reg [3:0] ALUOp = 0;
    reg [1:0] ALUSrcB = 0;
    reg ALUSrcA = 0;
    reg RegWrite = 0;
    reg RegDst = 0;
    reg isWWD = 0;
    reg PCWrite_t = 0;
    //////////////////////////////////

    // register for state
    reg [2:0] state;
    reg [2:0] next_state;

    // initialize state
    initial begin
        state <= -1;
        next_state <= 0;
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
                if (opcode == `OPCODE_LWD | opcode == `OPCODE_SWD)
                    next_state = state + 1;
                else if (opcode == `OPCODE_JMP 
                        |opcode == `OPCODE_JAL
                        |opcode == `OPCODE_BEQ
                        |opcode == `OPCODE_BGZ
                        |opcode == `OPCODE_BLZ
                        |opcode == `OPCODE_BNE)
                    next_state = 0;
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
                next_state = 0;
            end
        endcase
    end

    // update state
    always @ (posedge clk) begin
        if (reset_n == 0) begin
            state <= -1;
            next_state <= 0;
        end
        else
            state <= next_state;
    end

    // block for output
    always @ (state or opcode or func_code) begin
        case (state)
            // IF stage
            0 : begin
                isWWD = 0;
                IorD = 0;
                // PC = PC + 4 to the PC_4_temp
                RegWrite = 0;
                MemWrite = 0;
                PCWrite_t = 1;
                PCWrite = 0;
                PCSource = 0;
                ALUSrcA = 0;
                ALUSrcB = 1;
                ALUOp = `OP_ADD;
                // insturction fetching
                IRWrite = 1;
                MemRead = 1;
            end
            // ID stage
            1 : begin
                // turn off signals
                PCWrite_t = 0;
                IRWrite = 0;
                MemRead = 0;
                // ALUout <= PC + (sign extend(imm))
                ALUSrcA = 0;
                ALUSrcB = 2;
            end
            // EX stage
            2 : begin
                // R-type
                if (opcode == 15) begin
                    ALUSrcA = 1;
                    ALUSrcB = 0;
                    RegDst = 1;
                    // select ALU operation
                    case (func_code) 
                        `FUNC_ADD : ALUOp = `OP_ADD;
                        `FUNC_SUB : ALUOp = `OP_SUB;
                        `FUNC_AND : ALUOp = `OP_AND;
                        `FUNC_ORR : ALUOp = `OP_ORR;
                        `FUNC_NOT : ALUOp = `OP_NOT;
                        `FUNC_TCP : ALUOp = `OP_TCP;
                        `FUNC_SHL : ALUOp = `OP_SHL;
                        `FUNC_SHR : ALUOp = `OP_SHR;
                    endcase
                    // WWD
                    if (func_code == 28) begin
                        isWWD = 1;
                    end
                end
                // branch
                else if (opcode == `OPCODE_BEQ
                        |opcode == `OPCODE_BNE
                        |opcode == `OPCODE_BGZ
                        |opcode == `OPCODE_BLZ) begin
                    ALUSrcB = 0;
                    ALUSrcA = 0;
                    PCSource = 1;
                    case (opcode)
                        `OPCODE_BEQ : ALUOp = `OP_BEQ;
                        `OPCODE_BNE : ALUOp = `OP_BNE;
                        `OPCODE_BGZ : ALUOp = `OP_BGZ;
                        `OPCODE_BLZ : ALUOp = `OP_BLZ;
                    endcase
                end
                // jump instruction
                else if (opcode == `OPCODE_JMP | opcode == `OPCODE_JAL) begin
                    PCWrite = 1;
                    PCSource = 2;
                end
                // SWD, LWD, or I-type
                else begin
                    ALUSrcA = 1;
                    ALUSrcB = 2;
                    RegDst = 0;
                    case (opcode)
                        `OPCODE_ORI : ALUOp = `OP_ORI;
                        `OPCODE_LHI : ALUOp = `OP_LHI;
                        default : ALUOp = `OP_ADD;
                    endcase
                end
            end
            // MEM stage
            3 : begin
                // turn off signal
                isWWD = 0;
                // read from alu out
                IorD = 1;
                if (opcode == `OPCODE_LWD) begin
                    MemRead = 1;
                    MemWrite = 0;
                end
                else begin
                    MemRead = 0;
                    MemWrite = 1;
                    // next pc
                    PCSource = 0;
                    PCWrite = 1;
                end
            end
            // WB stage
            4 : begin
                // turn off signal
                isWWD = 0;
                // nop or WWD
                if (opcode == 0 | func_code == 6'h1c) begin
                    MemRead = 0;
                    MemWrite = 0;
                    RegWrite = 0;
                end else begin
                    MemRead = 0;
                    MemWrite = 0;
                    RegWrite = 1;
                    if (opcode == `OPCODE_LWD) begin
                        MemtoReg = 1;
                    end
                    else begin
                        MemtoReg = 0;
                    end
                end
                // next pc
                PCSource = 0;
                PCWrite = 1;
            end
        endcase
    end

endmodule
