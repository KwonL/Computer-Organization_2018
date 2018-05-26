`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "opcodes.v"

/*
 * CPU module can be splited into two subset.
 * one is datapath. datapath module connects registers or wires correctly.
 * one is control_unit. It's output controls datapath and RTL.
 */

module cpu(
    input Clk, 
    input Reset_N, 

    // Instruction memory interface
    output i_readM, 
    output i_writeM, 
    input i_send_data,
    output [`WORD_SIZE-1:0] i_address, 
    inout [4*`WORD_SIZE-1:0] i_data_block, 

    // Data memory interface
    output d_readM, 
    output d_writeM, 
    output [`WORD_SIZE-1:0] d_address, 
    inout [4*`WORD_SIZE-1:0] d_data_block, 

    output [`WORD_SIZE-1:0] num_inst, 
    output [`WORD_SIZE-1:0] output_port, 
    output is_halted
);
    // TODO : Implement your pipeline-cycle CPU!

    wire [`WORD_SIZE-1:0] i_data;
    wire [`WORD_SIZE-1:0] d_data;
    wire [3:0] opcode;
    wire [5:0] func_code;
    wire [1:0] RegDst;
    wire [3:0] ALUOp;
    wire [`WORD_SIZE-1:0] num_inst;
    wire [`WORD_SIZE-1:0] output_port;
    wire [`WORD_SIZE-1:0] i_address_to_C;
    wire [`WORD_SIZE-1:0] d_address_to_C;

    cache_unit cache(
        .clk(!Clk),
        .reset_n(Reset_N),

        .i_readC(i_readC),
        .i_address_to_C(i_address_to_C),
        .i_data(i_data),
        .i_hit(i_hit),

        .i_send_data(i_send_data),
        .i_address(i_address),
        .i_readM(i_readM),
        .i_data_block(i_data_block),

        .d_readC(d_readC),
        .d_writeC(d_writeC),
        .d_address_to_C(d_address_to_C),
        .d_data(d_data),
        .d_hit(d_hit),

        .d_send_data(d_send_data),
        .d_address(d_address),
        .d_readM(d_readM),
        .d_writeM(d_writeM),
        .d_data_block(d_data_block)
    );

    control_unit controller(
		.reset_n(Reset_N),
        .clk(Clk),
        .opcode(opcode),
        .func_code(func_code),

        .stall(stall),

        .MemRead(MemRead),
        .MemWrite(MemWrite),

        .RegDst(RegDst),
        .Jump(Jump),
        .Jump_R(Jump_R),
        .Branch(Branch),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .RegWrite(RegWrite),

        .isWWD(isWWD),
        .isHalt(isHalt)
    );

    datapath dp(
        .clk(Clk),
        .reset_n(Reset_N),

        .i_readC(i_readC),
        .i_writeC(i_writeC),
        .i_hit(i_hit),
        .i_address_to_C(i_address_to_C),
        .i_data(i_data),

        .d_readC(d_readC),
        .d_writeC(d_writeC),
        .d_address_to_C(d_address_to_C),
        .d_data(d_data),

        .num_inst(num_inst),
        .output_port(output_port),
        .is_halted(is_halted),

        .MemRead(MemRead),
        .MemWrite(MemWrite),

        .RegDst(RegDst),
        .Jump(Jump),
        .Jump_R(Jump_R),
        .Branch(Branch),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .RegWrite(RegWrite),

        .isWWD(isWWD),
        .isHalt(isHalt),

        .stall_out(stall),

        .opcode(opcode),
        .func_code(func_code)
    );
endmodule
