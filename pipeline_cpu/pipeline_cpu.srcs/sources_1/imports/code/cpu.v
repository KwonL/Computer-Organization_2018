`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "opcodes.v"

module cpu(
    input Clk, 
    input Reset_N, 

    // Instruction memory interface
    output i_readM, 
    output i_writeM, 
    output [`WORD_SIZE-1:0] i_address, 
    inout [`WORD_SIZE-1:0] i_data, 

    // Data memory interface
    output d_readM, 
    output d_writeM, 
    output [`WORD_SIZE-1:0] d_address, 
    inout [`WORD_SIZE-1:0] d_data, 

    output [`WORD_SIZE-1:0] num_inst, 
    output [`WORD_SIZE-1:0] output_port, 
    output is_halted
);
    // TODO : Implement your pipeline-cycle CPU!

    wire [3:0] opcode;
    wire [5:0] func_code;
    wire [1:0] RegDst;
    wire [3:0] ALUOp;
    wire [`WORD_SIZE-1:0] num_inst;
    wire [`WORD_SIZE-1:0] output_port;

    control_unit controller(
		.reset_n(Reset_N),
        .clk(Clk),
        .opcode(opcode),
        .func_code(func_code),

        .MemRead(MemRead),
        .MemWrite(MemWrite),

        .RegDst(RegDst),
        .Jump(Jump),
        .Branch(Branch),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),

        .isWWD(isWWD),
        .isHalt(isHalt)
    );

    datapath dp(
        .clk(Clk),
        .reset_n(Reset_N),

        .i_readM(i_readM),
        .i_writeM(i_writeM),
        .i_address(i_address),
        .i_data(i_data),

        .d_readM(d_readM),
        .d_writeM(d_writeM),
        .d_address(d_address),
        .d_data(d_data),

        .num_inst(num_inst),
        .output_port(output_port),
        .is_halted(isHalt),

        .MemRead(MemRead),
        .MemWrite(MemWrite),

        .RegDst(RegDst),
        .Jump(Jump),
        .Branch(Branch),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),

        .isWWD(isWWD),
        .isHalt(isHalt),

        .opcode(opcode),
        .func_code(func_code)
    );
endmodule
