`timescale 1ns/100ps

`include "opcodes.v"
`include "constants.v"
`include "ALU.v"

module cpu (
    output readM, // read from memory
    output writeM, // write to memory
    output [`WORD_SIZE-1:0] address, // current address for data
    inout [`WORD_SIZE-1:0] data, // data being input or output
    input inputReady, // indicates that data is ready from the input port
    input reset_n, // active-low RESET signal
    input clk, // clock signal
    
    // for debuging/testing purpose
    output [`WORD_SIZE-1:0] num_inst, // number of instruction during execution
    output [`WORD_SIZE-1:0] output_port, // this will be used for a "WWD" instruction
    output is_halted // 1 if the cpu is halted
);
    wire [15:0] inst_out;
    wire [3:0] ALUOp;
    wire [5:0] func_code;
    wire [1:0] PCSource;
    wire [3:0] opcode;
    wire [1:0] ALUSrcB;

    datapath dp(
        .clk(clk),
        .reset_n(reset_n),
        .inputReady(inputReady),
        .data(data),
        
        .readM(readM),
        .writeM(writeM),
        .address(address),

        .num_inst(num_inst),
        .output_port(output_port),

        .PCWriteCond(PCWriteCond),
        .PCWrite(PCWrite),
        .PCWrite_t(PCWrite_t),
        .IorD(IorD),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .IRWrite(IRWrite),

        .PCSource(PCSource),
        .ALUOp(ALUOp),
        .ALUSrcB(ALUSrcB),
        .ALUSrcA(ALUSrcA),
        .RegWrite(RegWrite),
        .RegDst(RegDst),
        .isWWD(isWWD),

        .opcode(opcode),
        .func_code(func_code),

        .inst_out(inst_out)
    );

    control_unit Control (
        .reset_n(reset_n),
        .clk(clk),
        .opcode(inst_out[15:12]),
        .func_code(inst_out[5:0]),

        .PCWriteCond(PCWriteCond),
        .PCWrite(PCWrite),
        .PCWrite_t(PCWrite_t),
        .IorD(IorD),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .IRWrite(IRWrite),

        .PCSource(PCSource),
        .ALUOp(ALUOp),
        .ALUSrcB(ALUSrcB),
        .ALUSrcA(ALUSrcA),
        .RegWrite(RegWrite),
        .RegDst(RegDst),
        .isWWD(isWWD)
    ); 

endmodule


/*
 * definition fo module
 */

module datapath (
    input clk,
    input reset_n,
    input inputReady,
    input [`WORD_SIZE-1:0] data,
    
    output readM,
    output writeM,
    output [`WORD_SIZE-1:0] address,

    output [`WORD_SIZE-1:0] num_inst,
    output [`WORD_SIZE-1:0] output_port,

    input PCWriteCond,
    input PCWrite,
    input PCWrite_t,
    input IorD,
    input MemRead,
    input MemWrite,
    input MemtoReg,
    input IRWrite,

    input [1:0] PCSource,
    input [3:0] ALUOp,
    input [1:0] ALUSrcB,
    input ALUSrcA,
    input RegWrite,
    input RegDst,
    input isWWD,
    
    output [3:0] opcode,
    output [5:0] func_code,

    output [`WORD_SIZE-1:0] inst_out
);

    // internel register for PC
    reg [`WORD_SIZE-1:0] PC;
    wire [`WORD_SIZE-1:0] PC_jmp;
    reg [`WORD_SIZE-1:0] inst;
    reg [`WORD_SIZE-1:0] PC_next;
    reg [`WORD_SIZE-1:0] PC_4_temp;
    reg [`WORD_SIZE-1:0] reg_data;
    // end of register //
    
    // Redef of in or out
    reg [`WORD_SIZE-1:0] num_inst;
    ///////////////////////////

    // variables for wiring
    wire [`WORD_SIZE-1:0] data1, data2, data3;
    wire [1:0] addr1, addr2,  addr3;
    wire [`WORD_SIZE-1:0] ALUsrc_wire1, extended;
    reg [`WORD_SIZE-1:0] ALUsrc_wire2 = 16'h4;
    wire [`WORD_SIZE-1:0] ALU_wire;
    wire Zero;
    // end of var //

    // registers (A, B, ALUOut and so on..)
    reg [`WORD_SIZE-1:0] ALUOut;
    reg [`WORD_SIZE-1:0] A;
    reg [`WORD_SIZE-1:0] B;
    // end of reg //  

    // register wiring
    always @ (posedge clk) begin

        ALUOut <= ALU_wire;
        A <= data1;
        B <= data2;

    end
    // end of wiring //

    assign inst_out = inst;

    // read data from memory Address 
    assign address = IorD ? ALU_wire : PC;
    always @ (posedge inputReady) begin
        if (IRWrite == 1) inst <= data;
        else reg_data <= data;
    end
    ///////////////////////

    // send data
    assign data = writeM ? data2 : 16'bz;
    /////////////////////

    // initializing cpu
    initial begin
        inst <= 0;
        PC <= 0;
        num_inst <= 0;
        reg_data <= 0;
    end
    //////////////////////

    // memory signal  
    assign readM = MemRead;
    assign writeM = MemWrite;
    //////////////////////

    // PC, inst update
    always @ (posedge clk or reset_n) begin 
        if (reset_n == 0) begin
            PC <= 0;
            num_inst <= 0;
            inst <= 0;
        end
        else if (PCWrite == 1 | (PCWriteCond & Zero)) begin
            PC <= PC_next;
            num_inst <= num_inst + 1;
        end
    end
    // PC MUX
    always @ (PC or inst or ALUOut or ALU_wire or PCSource) begin
        case (PCSource)
            0 : PC_next = PC_4_temp;
            1 : PC_next = ALUOut;
            2 : PC_next = {PC[15:12], inst[11:0]};
        endcase
    end
    // temporalily save PC + 4 at ID stage
    always @ (posedge clk) begin
        if (PCWrite_t) begin
            PC_4_temp <= ALU_wire;
        end
    end
    /////////////////////////

    // output port
    assign output_port = isWWD ? data1 : output_port;
    ////////////////////

    // instruction decoding
    assign opcode = inst[`WORD_SIZE-1:`WORD_SIZE-4];
    assign func_code = inst[5:0];
    ////////////////////////

    // wiring all mux or inputs
    assign addr1 = inst[11:10];
    assign addr2 = inst[9:8];
    assign addr3 = RegDst ? inst[7:6] : inst[9:8];
    assign ALUsrc_wire1 = ALUSrcA ? A : PC;
    always @ (extended or B or ALUSrcB) begin
        case (ALUSrcB)
            0 : ALUsrc_wire2 = B;
            1 : ALUsrc_wire2 = 16'h1;
            2 : ALUsrc_wire2 = extended;
        endcase
    end
    assign data3 = MemtoReg ? reg_data : ALUOut;
    //////////////////////

    // wwd
    
    ////////////////
    
    // Register file wiring
    RegisterFile rf(
        .addr1(addr1), 
        .addr2(addr2), 
        .addr3(addr3), 
        .data3(data3), 
        .write(RegWrite), 
        .clk(clk), 
        .reset_n(reset_n), 
        .data1(data1), 
        .data2(data2)
    );

    // ALU wiring
    ALU alu(
        .A(ALUsrc_wire1),
        .B(ALUsrc_wire2),
        .OP(ALUOp),
        .C(ALU_wire),
        .Zero(Zero)
    );

    // sign extension module for ADI
    sign_extension SE(.imm(inst[7:0]), .extended(extended));

endmodule

module sign_extension(
    input [`WORD_SIZE/2-1:0] imm,
    output [`WORD_SIZE-1:0] extended
);
    assign extended = imm[`WORD_SIZE/2-1] ? { {8{1'b1}}, imm} : {8'b0, imm}; 
endmodule

 ////// end of def //////
 