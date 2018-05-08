`include "opcodes.v"

// detect control hazard and send hazard signal
module hazard_detector(
    input Jump,
    input Jump_R,
    input Branch_taken,

    output flush
);
    
    assign flush = Jump | Branch_taken | Jump_R;

endmodule 

// Detect data hazard and send stall signal
// and data forwarding module
module stall_unit(
    input [3:0] opcode,
    input [5:0] func_code,
    
    /*
     * if these address are used at present instruction's
     * source address, then stall
     */ 
    input [1:0] dest_EX,
    input [1:0] dest_MEM,
    input [1:0] dest_WB,

    input RegWrite_reg_EX,
    input RegWrite_reg_MEM,
    input RegWrite_reg_WB,

    input [1:0] rs_addr,
    input [1:0] rt_addr,

    output stall
);
    // redefinition of registers
    reg stall = 0;
    // end of redef //

    /* 
     * this part is for stall unit.
     */
    always @ (*) begin
        // jump instructions do not stall.
        if (opcode == `OPCODE_JMP | opcode == `OPCODE_JAL) stall = 0;
        // R-type instruction use rt as source except for HLT and WWD
        else if (opcode == 4'hf & (func_code != 6'd29) & (func_code != 6'd28)) begin
            if (((rs_addr == dest_EX) & RegWrite_reg_EX)
               |((rs_addr == dest_MEM) & RegWrite_reg_MEM)
               |((rs_addr == dest_WB) & RegWrite_reg_WB)
               |((rt_addr == dest_EX) & RegWrite_reg_EX)
               |((rt_addr == dest_MEM) & RegWrite_reg_MEM)
               |((rt_addr == dest_WB) & RegWrite_reg_WB))
                stall = 1;
            else stall = 0;
        end
        // other type instruction only use rs as source
        else begin
            if (((rs_addr == dest_EX) & RegWrite_reg_EX)
               |((rs_addr == dest_MEM) & RegWrite_reg_MEM)
               |((rs_addr == dest_WB) & RegWrite_reg_WB))
                stall = 1;
            else stall = 0;
        end
    end
    ////////////////////////////////////////////////////////
endmodule


/* 
 * this module control data forwarding to ID stage
 * because WWD, JMP instructions use register value in ID stage
 */
module forwarding_unit(
    input [3:0] opcode,
    input [5:0] func_code,

    input [1:0] rs_addr,
    input [1:0] rt_addr,

    input [1:0] dest_EX,
    input [1:0] dest_MEM,
    input [1:0] dest_WB,

    input RegWrite_reg_EX,
    input RegWrite_reg_MEM,
    input RegWrite_reg_WB,

    input MemRead_reg_EX,
    input MemRead_reg_MEM,

    output stall,
    output [1:0] ForwardA,
    output [1:0] ForwardB
);
    // redefinition of registers
    reg stall = 0;
    reg [1:0] ForwardA = 0;
    reg [1:0] ForwardB = 0;
    // end of redef //

    always @ (*) begin
        // for R-type instruction except for HLT and WWD and JPR and JRL
        if ((opcode == 4'hf && func_code != 6'd28 && func_code != `FUNC_JPR && func_code != `FUNC_JRL) || opcode == `OPCODE_SWD) begin
            // if blocks for ForwardA
            if ((rs_addr == dest_EX) & RegWrite_reg_EX) begin
                // if previous instruction is LOAD, then must stall until end of MEM stage
                ForwardA = 1;
            end
            else if ((rs_addr == dest_MEM) & RegWrite_reg_MEM) begin
                // if previous instrucion is LOAD, then must stall 1 cycle
                ForwardA = 2;
            end
            else if ((rs_addr == dest_WB) & RegWrite_reg_WB) begin
                ForwardA = 3;
            end else begin
                ForwardA = 0;
            end

            // if blocks for ForwardB
            if ((rt_addr == dest_EX) & RegWrite_reg_EX) begin
                ForwardB = 1;
            end
            else if ((rt_addr == dest_MEM) & RegWrite_reg_MEM) begin
                ForwardB = 2;
            end
            else if ((rt_addr == dest_WB) & RegWrite_reg_WB) begin
                ForwardB = 3;
            end else begin
                ForwardB = 0;
            end

            // if blocks for stall
            // if prev instruction is LW, then must stall untill MEM stage
            if (((rt_addr == dest_EX) & RegWrite_reg_EX & MemRead_reg_EX) || ((rs_addr == dest_EX) & RegWrite_reg_EX & MemRead_reg_EX))
                stall = 1;
            else stall = 0; 
        end
        else begin
            if ((rs_addr == dest_EX) & RegWrite_reg_EX) begin
                ForwardA = 1;
            end 
            // if blocks for ForwardA
            else if ((rs_addr == dest_MEM) & RegWrite_reg_MEM) begin
                ForwardA = 2;
            end
            else if ((rs_addr == dest_WB) & RegWrite_reg_WB) begin
                ForwardA = 3;
            end
            else ForwardA = 0;

            ForwardB = 0;

            // if blocks for stall
            if ((rs_addr == dest_EX) & RegWrite_reg_EX & MemRead_reg_EX) stall = 1;
            else stall = 0;
        end
    end

endmodule 

/////////////////////////////////////////