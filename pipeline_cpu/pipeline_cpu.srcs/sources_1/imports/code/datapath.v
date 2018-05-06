`define WORD_SIZE 16
`include "ALU.v"

/*
 * definition of modules
 */


module datapath (
    input clk,
    input reset_n,
	
	output i_readM,
	output i_writeM,
	output [`WORD_SIZE-1:0] i_address,
	input [`WORD_SIZE-1:0] i_data,

	output d_readM,
	output d_writeM,
	output [`WORD_SIZE-1:0] d_address,
	inout d_data,

    output [`WORD_SIZE-1:0] num_inst, 
    output [`WORD_SIZE-1:0] output_port, 
    output is_halted,

    input MemRead,
    input MemWrite,

    input [1:0] RegDst,
    input Jump,
    input Branch,
    input MemtoReg,
    input [3:0] ALUOp,
    input ALUSrc,
    input RegWrite,
    
    input isWWD,
    input isHalt,

    output stall_out,
    
    output [3:0] opcode,
    output [5:0] func_code
);
    // internel register for PC and instruction
    reg [`WORD_SIZE-1:0] PC;
    wire [`WORD_SIZE-1:0] PC_jmp;
    reg [`WORD_SIZE-1:0] inst;
    reg [`WORD_SIZE-1:0] PC_next;
    // end of register //
    
    // Redef of in or out
    reg [`WORD_SIZE-1:0] num_inst;
    reg [`WORD_SIZE-1:0] output_port;
    ///////////////////////////

    // variables for wiring
    wire [`WORD_SIZE-1:0] data1, data2, data3;
    wire [1:0] addr1, addr2;
    wire [1:0] addr3;
    wire [`WORD_SIZE-1:0] ALUSrc_wire, extended;
    wire [`WORD_SIZE-1:0] ALU_wire;
    wire Zero;
    wire flush;
    // for hazard detecting
    wire Branch_taken;
    assign Branch_taken = Branch & Zero;
    wire stall;
    // for control unit to stop write signal
    assign stall_out = stall;
    // end of var //

    // registers (A, B, ALUOut and so on..)
    reg [`WORD_SIZE-1:0] ALUOut;
	reg [`WORD_SIZE-1:0] reg_data;
    reg [`WORD_SIZE-1:0] A;
    reg [`WORD_SIZE-1:0] B;
    reg [`WORD_SIZE-1:0] extended_reg;
    reg [`WORD_SIZE-1:0] PC_carrie_reg[1:0];
    reg [1:0] rt_reg;
    reg [1:0] rd_reg;   
    reg [1:0] write_addr_EX;
    reg [1:0] write_addr_MEM;
    reg [1:0] write_addr_WB;
    reg [`WORD_SIZE-1:0] ALUOut_WB;
    // this is for WWD instruction
    reg [`WORD_SIZE-1:0] A_reg[1:0];
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
	reg [1:0] RegDst_reg;
	// maybe jump will be used directly?
	reg Jump_reg;
	reg Branch_reg;
	reg MemtoReg_reg[2:0];
	reg [3:0] ALUOp_reg;
	reg ALUSrc_reg;
	reg RegWrite_reg[2:0];
	reg isWWD_reg[2:0];
	reg isHalt_reg;
	// end of reg//

    // register wiring
    always @ (posedge clk) begin

        ALUOut <= ALU_wire;
        ALUOut_WB <= ALUOut;
        A <= data1;
        B <= data2;
        extended_reg <= extended;
        PC_carrie_reg[0] <= PC + 4;
        PC_carrie_reg[1] <= PC_carrie_reg[1];
        // rt_reg <= inst[9:8];
        // rd_reg <= inst[7:6];
        case (RegDst) 
            0 : write_addr_EX <= inst[9:8];
            1 : write_addr_EX <= inst[7:6];
            // this is for JAL or JRL instruction
            2 : write_addr_EX <= 2;
        endcase
        write_addr_MEM <= write_addr_EX;
        write_addr_WB <= write_addr_MEM;
        A_reg[0] <= A;
        A_reg[1] <= A;

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
		MemtoReg_reg[0] <= MemtoReg;
		MemtoReg_reg[1] <= MemtoReg_reg[0];
		MemtoReg_reg[2] <= MemtoReg_reg[1];
		ALUOp_reg <= ALUOp;
		ALUSrc_reg <= ALUSrc;
        RegWrite_reg[0] <= RegWrite;
        RegWrite_reg[1] <= RegWrite_reg[0];
        RegWrite_reg[2] <= RegWrite_reg[1];
		isWWD_reg[0] <= isWWD;
        isWWD_reg[1] <= isWWD_reg[0];
        isWWD_reg[2] <= isWWD_reg[1];
		isHalt_reg <= isHalt;
	end
	// end of wiring

    assign is_halted = isHalt;

    // read instruction data from memory Address 
	assign i_address = PC;
	assign i_readM = 1;
	assign i_writeM = 0;
    ///////////////////////

    // send data
    assign data = MemWrite_reg[1] ? data2 : 16'bz;
    /////////////////////

    // initializing cpu
    initial begin
        inst <= 0;
        PC <= 0;
        num_inst <= -4;
        reg_data <= 0;
    end
    //////////////////////

    // memory signal  
    assign d_readM = MemRead_reg[1];
    assign d_writeM = MemWrite_reg[1];
    //////////////////////

    // PC, inst update
    always @ (posedge clk) begin 
        if (reset_n == 0) begin
            PC <= 0;
            num_inst <= -4;
            inst <= 0;
        end
        else begin
            // stalling until data complete
            if (stall) begin
                PC <= PC;
                inst <= inst;
            end 
            // normal instruction
            else begin
            PC <= PC_next;
            // flushing
            if (flush) inst <= 0;
            else inst <= i_data;
            end
        end
    end
    always @ (inst) begin
        num_inst = num_inst + 1;
    end
    // PC MUX
    // Jump: jump to PC jump
    // Branch: jump to PC + 1 + extended_reg
    always @ (Jump or PC_jmp or Branch_reg or Zero or PC_carrie_reg[1] or extended_reg or PC) begin
        if (Jump) begin
            PC_next = PC_jmp;
        end
        else if (Branch & Zero) begin
            PC_next = PC_carrie_reg[1] + extended_reg;
        end
        else begin
            PC_next = PC + 1;
        end
    end
    /////////////////////////

    // PC_jmp wiring
    assign PC_jmp = {PC_carrie_reg[0][15:12], inst[11:0]};
    ///////////////////

    // output port
    always @ (posedge clk) output_port = isWWD_reg[2] ? ALUOut_WB : output_port;
    ////////////////////

    // instruction decoding
    assign opcode = inst[`WORD_SIZE-1:`WORD_SIZE-4];
    assign func_code = inst[5:0];
    ////////////////////////

    // wiring all mux or inputs
    assign addr1 = inst[11:10];
    assign addr2 = inst[9:8];
    assign addr3 = write_addr_WB;
    assign ALUSrc_wire = ALUSrc_reg ? extended_reg : B;
    assign data3 = MemtoReg_reg[2] ? reg_data : ALUOut_WB;
    //////////////////////

    // Register file wiring
    RegisterFile rf(
        .addr1(addr1), 
        .addr2(addr2), 
        .addr3(addr3), 
        .data3(data3), 
        .write(RegWrite_reg[2]), 
        .clk(clk), 
        .reset_n(reset_n), 
        .data1(data1), 
        .data2(data2)
    );

    // ALU wiring
    ALU alu(
        .A(A),
        .B(ALUSrc_wire),
        .OP(ALUOp),
        .C(ALU_wire)
    );

    comparator CP(
        .A(data1),
        .B(data2),
        .OP(ALUOp),

        .Zero(Zero)
    );

    hazard_detector hd(
        .Jump(Jump),
        .Branch_taken(Branch_taken),

        .flush(flush)
    );

    stall_unit SU(
        .opcode(opcode),
        .func_code(func_code),
        
        .dest_EX(write_addr_EX),
        .dest_MEM(write_addr_MEM),
        .dest_WB(write_addr_WB),

        .RegWrite_reg_EX(RegWrite_reg[0]),
        .RegWrite_reg_MEM(RegWrite_reg[1]),
        .RegWrite_reg_WB(RegWrite_reg[2]),

        .rs_addr(inst[11:10]),
        .rt_addr(inst[9:8]),

        .stall(stall)
    );

    // sign extension module for ADI
    sign_extension SE(.imm(inst[7:0]), .extended(extended));

endmodule

module sign_extension(
    input [7:0] imm,
    output [`WORD_SIZE-1:0] extended
);
    assign extended = imm[7] ? { {8{1'b1}}, imm} : {8'b0, imm}; 
endmodule

module comparator(
    input [`WORD_SIZE-1:0] A,
    input [`WORD_SIZE-1:0] B,

    input [3:0] OP,

    output reg Zero

);  
    always @ (*) begin
        case (OP)
            `OP_BNE : begin
                Zero = (A != B);
            end

            `OP_BEQ : begin
                Zero = (A == B);
            end

            `OP_BGZ : begin 
                if (A != 0) Zero = ~A[15];
                else Zero = 0;
            end

            `OP_BLZ : begin
                Zero = A[15];
            end
        endcase
    end
endmodule
 ////// end of def //////
 