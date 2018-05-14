`include "opcodes.v"
`include "ALU.v"

/*
 * This is controller for 16-bit TSC pipeline cycle cpu.
 * Each instruction can be implemented via data transfer between registers. 
 * Therefore, the CPU can be implemented by the sending correct signal to MUX.
 * I implemented this as a schematic in the Lab06 PDF.
 */
 
module control_unit (
    input reset_n,
    input clk,
    input [3:0] opcode,
    input [5:0] func_code,

    input stall,

    output MemRead,
    output MemWrite,

    output [1:0] RegDst,
    output Jump,
    output Jump_R,
    output Branch,
    output MemtoReg,
    output [3:0] ALUOp,
    output ALUSrc1,
    output ALUSrc2,
    output RegWrite,
    
    output isWWD,
    output isHalt
);
    /* Redef of output fegister */
    reg MemRead = 0;
    reg MemWrite = 0;
    reg [1:0] RegDst = 0;
    reg Jump = 0;
    reg Jump_R = 0;
    reg Branch = 0;
    reg MemtoReg = 0;
    reg [3:0] ALUOp = 0;
    reg ALUSrc1 = 0;
    reg ALUSrc2 = 0;
    reg RegWrite = 0;
    reg isWWD = 0;
    reg isHalt = 0;
    //////////////////////////////////

    always @ (opcode or func_code or stall) begin
        // if stall, turn off write signal.
        if (stall) begin
            MemWrite = 0;
            RegWrite = 0;
            isWWD = 0;
            isHalt = 0;
        end else begin
        // nop
        if (opcode == 0 & func_code == 0) begin
            MemRead = 0;
            MemWrite = 0;
            RegDst = 0;
            Jump = 0;
            Jump_R = 0;
            Branch = 0;
            MemtoReg = 0;
            ALUOp = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 0;
            RegWrite = 0;
            isWWD = 0;
            isHalt = 0;
        end
        // R-type instruction
        else if (opcode == 4'hf) begin
            // this is more simillar to JMP instruciton
            if (func_code == `FUNC_JPR | func_code == `FUNC_JRL) begin
                ALUOp = `OP_ID;
                MemRead = 0;
                MemWrite = 0;
                // write to #2 reg
                RegDst = 2;
                Jump = 0;
                Jump_R = 1;
                Branch = 0;
                MemtoReg = 0;
                ALUSrc1 = 1;
                ALUSrc2 = 0;
                isWWD = 0;
                isHalt = 0;
                if (func_code == `FUNC_JPR) RegWrite = 0;
                else RegWrite = 1;
            end
            // HLT..
            else if (func_code == `FUNC_HLT) begin
                MemRead = 0;
                MemWrite = 0;
                Branch = 0;
                Jump = 0;
                Jump_R = 0;
                RegWrite = 0;
                isHalt = 1;
                isWWD = 0;
            end
            // WWD..
            else if (func_code == 6'd28) begin
                MemRead = 0;
                MemWrite = 0;
                Branch = 0;
                Jump = 0;
                Jump_R = 0;
                RegWrite = 0;
                ALUSrc1 = 0;
                ALUSrc2 = 1;
                ALUOp = `OP_ID;
                MemtoReg = 0;
                isWWD = 1;
                isHalt = 0;
            // Other R-type instructions
            end else begin
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
                Jump_R = 0;
                Branch = 0;
                MemtoReg = 0;
                ALUSrc1 = 0;
                ALUSrc2 = 0;
                RegWrite = 1;
                isWWD = 0;
                isHalt = 0;
            end
        end
        // for I-type normal instruction
        else if (opcode == `OPCODE_ADI
                |opcode == `OPCODE_ORI 
                |opcode == `OPCODE_LHI) begin
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
            Jump_R = 0;
            Branch = 0;
            MemtoReg = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 1;
            RegWrite = 1;
            isWWD = 0;
            isHalt = 0;
        end
        // for memory instruction
        else if (opcode == `OPCODE_LWD
                |opcode == `OPCODE_SWD) begin
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
            Jump_R = 0;
            Branch = 0;
            MemtoReg = 1;
            ALUSrc1 = 0;
            ALUSrc2 = 1;
            isWWD = 0;
            isHalt = 0;
        end
        // for branch instruction
        else if ((opcode == `OPCODE_BNE)
                |(opcode == `OPCODE_BEQ)
                |(opcode == `OPCODE_BGZ)
                |(opcode == `OPCODE_BLZ)) begin
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
            Jump_R = 0;
            Branch = 1;
            MemtoReg = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 0;
            RegWrite = 0;
            isWWD = 0;
            isHalt = 0;
        end
        // for jump instruction
        else if (opcode == `OPCODE_JMP) begin
            // need to implement..
            MemRead = 0;
            MemWrite = 0;
            Branch = 0;
            Jump_R = 0;
            Jump = 1;
            RegWrite = 0;
            isWWD = 0;
            isHalt = 0;
        end
        else if (opcode == `OPCODE_JAL) begin
            ALUOp = `OP_ID;
            MemRead = 0;
            MemWrite = 0;
            RegDst = 2;
            Jump = 1;
            Jump_R = 0;
            Branch = 0;
            MemtoReg = 0;
            ALUSrc1 = 1;
            ALUSrc2 = 0;
            RegWrite = 1;
            isWWD = 0;
            isHalt = 0;
        end
        end
    end

endmodule
