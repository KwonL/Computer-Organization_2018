module hazard_detector(
    input Jump,
    input Branch_taken,

    output flush
);
    
    assign flush = Jump | Branch_taken;

endmodule 

module stall_unit(

);

endmodule