///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 
// Description: 

`include "opcodes.v"
`include "ALU.v"

// DEFINITIONS
`define WORD_SIZE 16    // data and address word size

// MODULE DECLARATION
module cpu (
    output readM,                       // read from memory
    output [`WORD_SIZE-1:0] address,    // current address for data
    inout [`WORD_SIZE-1:0] data,        // data being input or output
    input inputReady,                   // indicates that data is ready from the input port
    input reset_n,                      // active-low RESET signal
    input clk,                          // clock signal
  
    // for debuging/testing purpose
    output [`WORD_SIZE-1:0] num_inst,   // number of instruction during execution
    output [`WORD_SIZE-1:0] output_port // this will be used for a "WWD" instruction
);

    // Datapath - control Unit
    wire [3:0] opcode;
    wire [5:0] func_code;
    wire RegDst, Jump, ALUSrc, RegWrite, isWWD, lhi;
    wire [3:0] ALUOp;
    wire [`WORD_SIZE-1:0] PC_next;
    
    control_unit Control (
        .reset_n (reset_n),
        .opcode (opcode),
        .func_code (func_code),
        .RegDst (RegDst),
        .Jump (Jump),
        .ALUOperation (ALUOp),
        .ALUSrc (ALUSrc),
        .RegWrite (RegWrite),
        .isWWD (isWWD),
        .lhi (lhi)
    ); 
        
    datapath #(.WORD_SIZE (`WORD_SIZE)) 
        DP (
        .clk(clk),
        .reset_n (reset_n),
        .inputReady (inputReady),
        .data (inst),
        .readM (readM),
        .address (address),
        .num_inst (num_inst),
        .output_port (output_port),
        
        .RegDst (RegDst),
        .RegWrite (RegWrite),
        .ALUSrc (ALUSrc),
        .ALUOp (ALUOp),    
        .Jump (Jump),
        .isWWD (isWWD),
        .lhi (lhi),
        
        .opcode(opcode),
        .func_code (func_code)
    );
  // ... fill in the rest of the code

endmodule
//////////////////////////////////////////////////////////////////////////

/*
 * definition fo module
 */

module control_unit (
    input reset_n, 
    input [3:0] opcode,
    input [5:0] func_code,
    
    output RegDst,
    output Jump,
    output ALUOperation,
    output ALUSrc,
    output RegWrite,
    output isWWD,
    output lhi
    );

    reg RegDst;
    reg Jump;
    reg [3:0] ALUOperation;
    reg ALUSrc;
    reg RegWrite;
    reg isWWD;
    reg lhi;

    always @ (*) begin
        case (opcode)

            4'hf : begin
                if (func_code == `FUNC_ADD) begin
                    RegDst = 1;
                    Jump = 0;
                    ALUOperation = `OP_ADD; 
                    ALUSrc = 0;
                    RegWrite = 1;
                    isWWD = 0;
                    lhi = 0;
                end
                // wwd control
                else if (func_code == 6'h1c) begin
                    Jump = 0;
                    isWWD = 1;
                    RegWrite = 0;
                end
            end

            `OPCODE_ADI : begin
                RegDst = 0;
                Jump = 0;
                ALUOperation = `OP_ADD;
                ALUSrc = 1;
                RegWrite = 1;
                isWWD = 0;
                lhi = 0;
            end

            `OPCODE_LHI : begin
                RegDst = 0;
                Jump = 0;
                ALUOperation = `OP_ADD;
                ALUSrc = 0;
                RegWrite = 1;
                isWWD = 0;
                lhi = 1;
            end

            `OPCODE_JMP : begin
                Jump = 1;
                RegWrite = 0;
                isWWD = 0;
            end
        endcase
    end

endmodule

module datapath (
    input clk,
    input reset_n,
    input inputReady,
    input [`WORD_SIZE-1:0] data,
    
    output [`WORD_SIZE-1:0] readM,
    output [`WORD_SIZE-1:0] address,

    output [`WORD_SIZE-1:0] num_inst;
    output [`WORD_SIZE-1:0] output_port,

    input RegDst,
    input RegWrite,
    input ALUSrc,
    input [3:0] ALUOp,
    input Jump,
    input isWWD,
    input lhi, 
    
    output [3:0] opcode,
    output func_code
);
    parameter WORD_SIZE = 16;

    // internel register for PC
    reg [`WORD_SIZE-1:0] PC;
    wire [`WORD_SIZE-1:0] PC_jmp;
    reg [`WORD_SIZE-1:0] inst;
    // end of register //
    
    // Redef of in or out
    reg [`WORD_SIZE-1:0] num_inst;
    reg [`WORD_SIZE-1:0] output_port;

    // variables for wiring
    wire [WORD_SIZE-1:0] data1, data2, data3;
    wire [1:0] addr1, addr2,  addr3;
    wire [WORD_SIZE-1:0] ALUsrc_wire, extended;
    wire [WORD_SIZE-1:0] ALU_out;
    // end of var //

    // read data from memory Address [PC]
    assign address = PC;
    always @ (posedge inputReady) inst <= data;
    ///////////////////////

    // initializing cpu
    initial begin
        inst <= 0;
        PC <= 0;
        num_inst <= 1;
    end
    assign readM = 1;
    //////////////////////

    // PC, inst update
    always @ (posedge clk) begin 
        if (reset_n == 0) begin
            PC <= 0;
            num_inst <= 1;
            inst <= 0;
        end else begin
            PC <= PC_next;
            num_inst <= num_inst + 1;
        end
    end
    assign PC_next = Jump ? PC_jmp : PC + 1;
    ////////////////    

    // instruction decoding
    assign opcode = inst[`WORD_SIZE-1:`WORD_SIZE-4];
    assign func_code = inst[5:0];
    ////////////////////////

    // PC jump
    assign PC_jmp = {4'b0, inst[11:0]};
    /////////////

    // wiring all mux or inputs
    assign addr1 = data[11:10];
    assign addr2 = data[9:8];
    assign addr3 = RegDst ? data[7:6] : data[9:8];
    assign ALUsrc_wire = ALUSrc ? extended : data2;
    assign data3 = lhi ? {data[7:0], 8'b0} : ALU_out;
    //////////////////////

    // wwd
    always @ (posedge clk) output_port <= isWWD ? data1 : output_port;
    ////////////////

    // lhi

    
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
        .A(data1),
        .B(ALUsrc_wire),
        .Cin(0),
        .OP(ALUOp),
        .C(ALU_out)
    );

    // sign extension module for ADI
    sign_extension SE(.imm(data[7:0]), .extended(extended));

endmodule

module sign_extension(
    input [`WORD_SIZE/2-1:0] imm,
    output [`WORD_SIZE-1:0] extended
);
    assign extended = imm[`WORD_SIZE/2-1] ? { {8{1'b1}}, imm} : {8'b0, imm}; 
endmodule

 ////// end of def //////