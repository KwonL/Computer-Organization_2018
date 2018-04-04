///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 
// Description: 

// DEFINITIONS
`define WORD_SIZE 16    // data and address word size

// MODULE DECLARATION
module cpu (
    output readM,                       // read from memory
    output [`WORD_SIZE-1:0] address,    // current address for data
    inout reg [`WORD_SIZE-1:0] data,        // data being input or output
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
    wire RegDst, Jump, ALUSrc, RegWrite, isWWD;
    wire ALUOp;
    wire [`WORD_SIZE-1:0] PC_next;

    // internel register or wire for RTL
    reg [`WORD_SIZE-1:0] PC;
    reg [`WORD_SIZE-1:0] dataReg;
    reg [`WORD_SIZE-1:0] PC_jmp;
    reg [`WORD_SIZE-1:0] inst;
    
    wire [11:0] LHI;
    // end of register //

    // read data from memory Address
    assign address = PC;
    always @ (posedge inputReady) begin
        dataReg <= data;
    end
    ///////////////////////

    // PC, inst update
    always @ (posedge clk) begin 
        inst <= data;
        PC <= PC_next;
        num_inst <= num_inst + 1;
    end
    assign PC_next = Jump ? PC_jmp : PC + 1;
    ////////////////    

    // instruction decoding
    assign opcode = inst[`WORD_SIZE-1:`WORD_SIZE-4];
    assign func_code = inst[5:0];
    assign address = inst[11:0];
    //////////////

    // PC jump
    assign PC_jmp = {PC[`WORD_SIZE-1:`WORD_SIZE-2], inst[13:0]};
    /////////////
    
    control_unit Control (
        .reset_n (reset_n),
        .opcode (opcode),
        .func_code (func_code),
        .RegDst (RegDst),
        .Jump (Jump),
        .ALUOperation (ALUOp),
        .ALUSrc (ALUSrc),
        .RegWrite (RegWrite),
        .isWWD (isWWD)
    ); 
        
    datapath #(.WORD_SIZE (`WORD_SIZE)) 
        DP (
        .clk(clk),
        .reset_n (reset_n),
        .inputReady (inputReady),
        .data (data),
        .readM (readM),
        .address (LHI),
        .num_inst (num_inst),
        .output_port (output_port),
        
        .RegDst (RegDst),
        .RegWrite (RegWrite),
        .ALUSrc (ALUSrc),
        .ALUOp (ALUOp),    
        .Jump (Jump),
        .isWWD (isWWD),
        
        .opcode(opcode),
        .func_code (func_code)
    );    
  // ... fill in the rest of the code

endmodule
//////////////////////////////////////////////////////////////////////////

/*
 * definition fo module
 */

module control_unit Control (
    input reset_n, 
    input opcode,
    input func_code,
    
    output RegDst,
    output Jump,
    output ALUOperation,
    output ALUSrc,
    output RegWrite,
    output isWWD
    );

endmodule

module datapath (
    input clk,
    input reset_n,
    input inputReady,
    input [`WORD_SIZE-1:0] data,
    
    output [`WORD_SIZE-1:0] readM,

    // address var is PC's lower 12 bit
    // I designed this var for LHI instruction
    input [11:0] address,

    output [`WORD_SIZE-1:0] num_inst,
    output [`WORD_SIZE-1:0] output_port,

    input RegDst,
    input RegWrite,
    input ALUSrc,
    input [3:0] ALUOp,
    input Jump,
    input isWWD,
    input opcode,
    input func_code
);

    // variables for wiring
    wire [`WORD_SIZE-1:0] data1, data2, data3;
    reg [3:0] OP;
    wire [1:0] addr1, [1:0] addr2, [1:0] addr3;     // what is correct..?
    // end of var //

    // wiring address of register
    assign addr1 = address[11:10];
    assign addr2 = address[9:8];
    assign addr3 = RegDst ? address[7:6] : address[9:8];
    //////////////////////
    
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
        .B(data2),
        .Cin(0),
        .OP(ALUOp),
        .C(data3)
    );

endmodule

module sign_extension(
    input [`WORD_SIZE/2-1:0] imm;
    output [`WORD_SIZE-1:0] extended;
);
    assign extended = {imm, 8'b0};
endmodule

 ////// end of def //////