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

    .RIWrite(RIWrite),
    .RDWrite(RDWrite),
    .PCWrite(PCWrite),
    .MEMWrite(MEMWrite),
    .MEMRead(MEMRead),
    .MEMsrc(MEMsrc),

    .RegDst(RegDst),
    .RegWrite(RegWrite),
    .ALUSrc(ALUSrc),
    .ALUOp(ALUOp),
    .Jump(jump),
    .isWWD(isWWD),
    .lhi(lhi), 
    
    .opcode(opcode),
    .func_code(func_code),

    .inst(inst)
    );

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

endmodule


/*
 * definition fo module
 */

/*
 * this module is kind of FSM machine that control controller by update stage
 * at every clock cycle. FSM is moore machine
 * stage : IF(4 cycle) ID(1 cycle) EX(2 cycle) MEM(4 cycle) WB(2 cycle)
 * 
 *       +-----+-----+-----+-----+----+-----+-----+------+------+------+------+------+-----+-----+
 * state |  0  |  1  |  2  |  3  |  4 |  5  |  6  |   7  |   8  |   9  |  10  |  11  |  12 |  13 |
 *       +-----+-----+-----+-----+----+-----+-----+------+------+------+------+------+-----+-----+
 * stage | IF0 | IF1 | IF2 | IF3 | ID | EX0 | EX1 | MEM0 | MEM1 | MEM2 | MEM3 | MEM4 | WB0 | WB1 |
 *       +-----+-----+-----+-----+----+-----+-----+------+------+------+------+------+-----+-----+
 */
 module micro_control (
     input reset_n,

     // datapath로부터 instruction을 받아야함
     // need some addintional port for datapath
     input [`WORD_SIZE-1:0] inst,
     input clk,

    output RIWrite,
    output RDWrite,
    output PCWrite,
    output MEMWrite,
    output MEMRead,

    output MEMsrc
 );
    // redef
    reg RIWrite;
    reg RDWrite;
    reg PCWrite;
    reg MEMWrite;
    reg MEMRead;
 
    /* register for fsm */
    reg [3:0] state;
    reg [3:0] next_state;
    ////////////////////////

    initial begin
        state <= 0;
        next_state <= 0;
    end

    // block for output
    always @ (posedge clk) begin
            // IF stage
            if (state < 4) begin
                RIWrite <= 0;
                RDWrite <= 0;
                PCWrite <= 0;
                MEMWrite <= 0;
                MEMRead <= 1;
            end
            // ID stage
            else if (state == 4) begin
                RIWrite <= 0;
                RDWrite <= 0;
                PCWrite <= 0;
                MEMWrite <= 0;
                MEMRead <= 0;
            end
            // EX stage
            else if (state < 7) begin
                RIWrite <= 0;
                PCWrite <= 0;
                MEMWrite <= 0;
                MEMRead <= 0;
            end
            // MEM stage
            else if (state < 12) begin
                // Store
                if (inst[15:12] == `OPCODE_SWD) begin
                    RIWrite <= 0;
                    RDWrite <= 0;
                    PCWrite <= 0;
                    MEMWrite <= 1;
                    MEMRead <= 0;
                end
                // Load
                else if (inst[15:12] == `OPCODE_LWD) begin
                    RIWrite <= 0;
                    RDWrite <= 0;
                    PCWrite <= 0;
                    MEMWrite <= 0;
                    MEMRead <= 1;
                end
            end
            // WB stage 1
            else if (state == 12) begin
                RIWrite <= 0;
                PCWrite <= 0;
                MEMWrite <= 0;
                MEMRead <= 0;
            end 
            // WB stage 2
            else begin
                RIWrite <= 0;
                PCWrite <= 1;
                MEMWrite <= 0;
                MEMRead <= 0;
            end
    end

    // block for next state

    // 지금 stage에서, instruction의 type에 따라 stage를 skip할지
    // 계속할지 정해서 하자
    always @ (state) begin
        
        // IF stage : continue whatever input
        if (state < 3) begin
            next_state <= state + 1;
        end
        else if (state == 3) begin
            if (inst[15:12] == `OPCODE_JMP) next_state <= 0;
            else next_state <= state + 1;
        end
        else if (state < 5) begin
            
        end
    
    end
 endmodule

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
            
            default : begin
                RegDst = 0;
                Jump = 0;
                ALUOperation = 0;
                ALUSrc = 0;
                RegWrite = 0;
                isWWD = 0;
                lhi = 0;                
            end
        endcase
    end

endmodule

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

    input RIWrite,
    input RDWrite,
    input PCWrite,
    input MEMWrite,
    input MEMRead,
    input MEMsrc,

    input RegDst,
    input RegWrite,
    input ALUSrc,
    input [3:0] ALUOp,
    input Jump,
    input isWWD,
    input lhi, 
    
    output [3:0] opcode,
    output [5:0] func_code,

    output [`WORD_SIZE-1:0] inst;
);

    // internel register for PC
    reg [`WORD_SIZE-1:0] PC;
    wire [`WORD_SIZE-1:0] PC_jmp;
    reg [`WORD_SIZE-1:0] inst;
    wire [`WORD_SIZE-1:0] PC_next;

    reg [`WORD_SIZE-1:0] reg_data;
    // end of register //
    
    // Redef of in or out
    reg [`WORD_SIZE-1:0] num_inst;
    reg [`WORD_SIZE-1:0] output_port;
    ///////////////////////////

    // variables for wiring
    wire [`WORD_SIZE-1:0] data1, data2, data3;
    wire [1:0] addr1, addr2,  addr3;
    wire [`WORD_SIZE-1:0] ALUsrc_wire, extended;
    wire [`WORD_SIZE-1:0] ALU_out;
    // end of var //

    // read data from memory Address [PC]
    assign address = MEMsrc ? ALU_out : PC;
    always @ (posedge inputReady) begin
        if (RIWrite == 1) inst <= data;
        else if (RDWrite == 1) reg_data <= data;
    end
    ///////////////////////

    // initializing cpu
    initial begin
        inst <= 0;
        PC <= 0;
        num_inst <= 0;
    end
    assign readM = MEMRead;
    assign writeM = MEMWrite;
    //////////////////////

    // PC, inst update
    always @ (posedge clk) begin 
        if (reset_n == 0) begin
            PC <= 0;
            num_inst <= 0;
            inst <= 0;
        end
        else if (PCWrite == 1) begin
            PC <= PC_next;
            num_inst <= num_inst + 1;
        end
    end
    assign PC_next = Jump ? PC_jmp : PC + 4;
    ////////////////    

    // instruction decoding
    assign opcode = inst[`WORD_SIZE-1:`WORD_SIZE-4];
    assign func_code = inst[5:0];
    ////////////////////////

    // PC jump
    assign PC_jmp = {4'b0, inst[11:0]};
    /////////////

    // wiring all mux or inputs
    assign addr1 = inst[11:10];
    assign addr2 = inst[9:8];
    assign addr3 = RegDst ? inst[7:6] : inst[9:8];
    assign ALUsrc_wire = ALUSrc ? extended : data2;
    assign data3 = lhi ? {inst[7:0], 8'b0} : ALU_out;
    //////////////////////

    // wwd
    always @ (posedge clk) output_port <= isWWD ? data1 : output_port;
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
        .A(data1),
        .B(ALUsrc_wire),
        .Cin(0),
        .OP(ALUOp),
        .C(ALU_out)
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
 