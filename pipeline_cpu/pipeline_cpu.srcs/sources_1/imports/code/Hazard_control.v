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
    
    reg stall = 0;

    always @ (*) begin
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

endmodule