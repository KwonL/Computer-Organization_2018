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

    control_unit controller(
		
    )
endmodule

/*
 * definition of modules
 */


module datapath (
    input clk,
    input reset_n,
	
	output i_readM,
	output i_writeM,
	inout [`WORD_SIZE-1:0] i_address,
	inout [`WORD_SIZE-1:0] i_data,

	output d_readM,
	output d_writeM,
	output [`WORD_SIZE-1:0] d_address,
	inout d_data,

    output [`WORD_SIZE-1:0] num_inst, 
    output [`WORD_SIZE-1:0] output_port, 
    output is_halted

    input MemRead,
    input MemWrite,

    input RegDst,
    input Jump,
    input Branch,
    input MemtoReg,
    input [3:0] ALUOp,
    input ALUsrc,
    input RegWrite,
    
    input isWWD,
    input isHalt
    
    output [3:0] opcode,
    output [5:0] func_code,
);
    // internel register for PC and instruction
    reg [`WORD_SIZE-1:0] PC;
    wire [`WORD_SIZE-1:0] PC_jmp;
    reg [`WORD_SIZE-1:0] inst;
    reg [`WORD_SIZE-1:0] PC_next;
    // end of register //
    
    // Redef of in or out
    reg [`WORD_SIZE-1:0] num_inst;
    ///////////////////////////

    // variables for wiring
    wire [`WORD_SIZE-1:0] data1, data2, data3;
    wire [1:0] addr1, addr2;
    reg [1:0] addr3;
    wire [`WORD_SIZE-1:0] ALUsrc_wire, extended;
    wire [`WORD_SIZE-1:0] ALU_wire;
    wire Zero;
    // end of var //

    // registers (A, B, ALUOut and so on..)
    reg [`WORD_SIZE-1:0] ALUOut;
	reg [`WORD_SIZE-1:0] reg_data;
    reg [`WORD_SIZE-1:0] A;
    reg [`WORD_SIZE-1:0] B;
    // end of reg //  

	// control registers(each stage)
	/*
	 * each signal has array..
	 * 0: EX stage
	 * 1: MEM stage
	 * 2: WB stage
	 * control signal will be carried until it is used
	 */
	reg MemRead_reg[1:0];
	reg MemWrite_reg[1:0];
	reg RegDst_reg;
	// maybe jump will be used directly?
	reg Jump_reg;
	reg Branch_reg;
	reg MemtoReg_reg[2:0];
	reg [3:0] ALUOp_reg;
	reg ALUsrc_reg;
	reg RegWrite_reg[2:0];
	reg isWWD_reg;
	reg isHalt_reg;
	// end of reg//

    // register wiring
    always @ (posedge clk) begin

        ALUOut <= ALU_wire;
        A <= data1;
        B <= data2;

    end
    // end of wiring //

	// control carrier wiring
	always @ (posedge clk) begin
		MemRead_reg[0] <= MemRead;
		MemWrite_reg[0] <= MemWrite;
		MemRead_reg[1] <= MemRead_reg[0];
		MemWrite_reg[1] <= MemWrite_reg[0];
		RegDst_reg <= RegDst;
		Jump_reg <= Jump;
		Branch_reg <= Branch;
		MemtoReg_reg[0] <= MemtoReg_reg;
		MemtoReg_reg[1] <= MemtoReg_reg[0];
		MemtoReg_reg[2] <= MemtoReg_reg[1];
		ALUOp_reg <= ALUOp;
		ALUsrc_reg <= ALUsrc;
		isWWD_reg <= isWWD;
		isHalt_reg <= isHalt;
	end
	// end of wiring

    assign is_halted = isHalt;

    // read instruction data from memory Address 
	assign i_address = PC;
	assign i_readM = 1;
	assign i_writeM = 0;
	always @ (posedge clk) inst <= i_data;
    ///////////////////////

    // send data
    assign data = MemWrite_reg[1] ? data2 : 16'bz;
    /////////////////////

    // initializing cpu
    initial begin
        inst <= 0;
        PC <= 0;
        num_inst <= -1;
        reg_data <= 0;
    end
    //////////////////////

    // memory signal  
    assign d_readM = MemRead;
    assign d_writeM = MemWrite;
    //////////////////////

    // PC, inst update
    always @ (posedge clk or reset_n) begin 
        if (reset_n == 0) begin
            PC <= 0;
            num_inst <= -1;
            inst <= 0;
        end
        else if (PCWrite == 1 | (PCWriteCond & Zero)) begin
            PC <= PC_next;
        end
    end
    always @ (inst) begin
        num_inst <= num_inst + 1;
    end
    // PC MUX
    always @ (PC or inst or ALUOut or ALU_wire or PCSource) begin
        case (PCSource)
            0 : PC_next = ALU_wire;
            1 : PC_next = ALUOut;
            2 : PC_next = {PC[15:12], inst[11:0]};
        endcase
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
    always @ (inst or RegDst) begin
        case (RegDst)
            0 : addr3 = inst[9:8];
            1 : addr3 = inst[7:6];
            // this is for JAL or JRL instruction
            2 : addr3 = 2;
        endcase
    end
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
 