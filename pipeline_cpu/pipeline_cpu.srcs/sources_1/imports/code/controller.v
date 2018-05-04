`include "opcodes.v"
`include "ALU.v"

module control_unit (
    input reset_n,
    input clk,
    input [3:0] opcode,
    input [5:0] func_code,

    output MemRead,
    output MemWrite,

    output RegDst,
    output Jump,
    output Branch,
    output MemtoReg,
    output [3:0] ALUOp,
    output ALUsrc,
    output RegWrite,
    
    output isWWD,
    output isHalt
);
    /* Redef of output fegister */
    reg MemRead = 0;
    reg MemWrite = 0;
    reg RegDst = 0;
    reg Jump = 0;
    reg Branch = 0;
    reg MemtoReg = 0;
    reg [3:0] ALUOp = 0;
    reg ALUsrc = 0;
    reg RegWrite = 0;
    reg isWWD = 0;
    reg isHalt = 0;
    //////////////////////////////////

    always @ (opcode or func_code) begin
        case (opcode)
            // R-type instruction
            4'hf : begin
                // this is more simillar to JMP instruciton
                if (func_code == `FUNC_JPR | func_code == `FUNC_JRL) begin

                end
                // HLT..
                else if (func_code == `FUNC_HLT) begin

                end
                // WWD..
                else if (func_code == `FUNC_WWD) begin

                end
                // ALUOp alloc
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
                // control signal that set up correct path
                MemRead = 0;
                MemWrite = 0;
                RegDst = 1;
                Jump = 0;
                Branch = 0;
                MemtoReg = 0;
                ALUsrc = 0;
                RegWrite = 1;
                isWWD = 0;
                isHalt = 0;
            end
            // for I-type normal instruction
            (`OPCODE_ADI, `OPCODE_ORI, `OPCODE_LHI) : begin
                case (opcode) 
                    `OPCODE_ADI : ALUOp = `OP_ADI;
                    `OPCODE_ORI : ALUOp = `OP_ORI;
                    `OPCODE_LHI : ALUOp = `OP_LHI;
                endcase
                // control signal
                MemRead = 0;
                MemWrite = 0;
                RegDst = 0;
                Jump = 0;
                Branch = 0;
                MemtoReg = 0;
                ALUsrc = 1;
                RegWrite = 1;
                isWWD = 0;
                isHalt = 0;
            end
            // for memory instruction
            (`OPCODE_LWD, `OPCODE_SWD) : begin
                ALUOp = `OP_ADD;
                // control singal
                // LWD instruction reads data from mem
                if (opcode == `OPCODE_LWD) begin
                    MemRead = 1;
                    MemWrite = 0;
                    RegWrite = 1;
                // SWD instruction write data to mem
                end else begin
                    MemRead = 0;
                    MemWrite = 1;
                    RegWrite = 0;
                end
                RegDst = 0;
                Jump = 0;
                Branch = 0;
                MemtoReg = 1;
                ALUsrc = 1;
                isWWD = 0;
                isHalt = 0;
            end
            // for branch instruction
            (`OPCODE_BNE, `OPCODE_BEQ, `OPCODE_BGZ, `OPCODE_BLZ) : begin
                case (opcode)
                    `OPCODE_BEQ : ALUOp = `OP_BEQ;
                    `OPCODE_BNE : ALUOp = `OP_BNE;
                    `OPCODE_BGZ : ALUOp = `OP_BGZ;
                    `OPCODE_BLZ : ALUOp = `OP_BLZ;
                endcase
                MemRead = 0;
                MemWrite = 0;
                RegDst = 0;
                Jump = 0;
                Branch = 1;
                MemtoReg = 0;
                ALUsrc = 0;
                RegWrite = 0;
                isWWD = 0;
                isHalt = 0;
            end
            // for jump instruction
            (`OPCODE_JMP, `OPCODEJAL) : begin
                // need to implement..
            end
        endcase
    end

endmodule
