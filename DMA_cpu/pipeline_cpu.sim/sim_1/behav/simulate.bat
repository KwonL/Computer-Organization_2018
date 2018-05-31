@echo off
set xv_path=D:\\Xilinx\\Vivado\\2016.4\\bin
call %xv_path%/xsim cpu_TB_behav -key {Behavioral:sim_1:Functional:cpu_TB} -tclbatch cpu_TB.tcl -view D:/Users/lkh116/Desktop/C.O_2018/DMA_cpu/cpu_TB_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
