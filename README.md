## SNU 2018-1 Computer Organization Projects
Seoul National University EE computer organization lecture.
by prof.JangWoo Kim

## Motivation
The whole purpose of this project is to complete a system. To do this, I built a pipeline CPU with cache and DMA added starting with a single cycle CPU.

## Features
You can find Verilog source code in 'some_project_folder/project_folder.srcs/sources_1/imports/code'

1. ALU : 16-bit ALU
2. RTL sequential logic

    2-1) 010 detector
  
    2-2) Register File

3. Vending machine : RTL Design
4. 16-bit single cycle CPU
5. 16-bit multi cycle CPU
6. 16-bit pipeline CPU

    6-1) pipeline CPU with stall for data hazard solution
    
    6-2) pipeline CPU with forwarding for data hazard solution
    
    6-3) pipeline CPU with branch predictor for control hazard solution

7. 16-bit pipeline CPU with cache

    7-1) baseline CPU - it takes 2-cycle to read memory
    
    7-2) cache CPU - it takes 6-cycle to read memory and 1-cycle to read cache
    
8. 16-bit pipeline CPU with DMA controller

    Externel Device write data to memory. DMA controller can handle this without CPU stall

    8-1) DMA controller
    
    8-2) DMA controller with cycle stealing

## Tests
You can enter some project folder and open description file. Just press 'run simulation' button to test projects.

## How to use?
I leave this project for my juniors. Good Luck!
