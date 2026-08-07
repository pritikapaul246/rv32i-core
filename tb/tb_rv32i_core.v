`timescale 1ns/1ps

module tb_rv32i_core;
    reg  clk = 0;
    reg  rst_n = 0;
    wire [31:0] pc_out, instr_out;

    rv32i_core DUT (
        .clk       (clk),
        .rst_n     (rst_n),
        .pc_out    (pc_out),
        .instr_out (instr_out)
    );

    always #5 clk = ~clk; // 100MHz-equivalent sim clock

    initial begin
        $dumpfile("rv32i.vcd");
        $dumpvars(0, tb_rv32i_core);

        rst_n = 0;
        #12 rst_n = 1;

        #100; // let the 5 instructions + loop execute

        $display("---------------------------------------------");
        $display("Program: addi x1,x0,5 / addi x2,x0,10 / add x3,x1,x2 / sw x3,0(x0) / lw x4,0(x0)");
        $display("x1     = %0d  (expect 5)",  DUT.RF.regs[1]);
        $display("x2     = %0d  (expect 10)", DUT.RF.regs[2]);
        $display("x3     = %0d  (expect 15)", DUT.RF.regs[3]);
        $display("x4     = %0d  (expect 15, round-tripped through data memory)", DUT.RF.regs[4]);
        $display("mem[0] = %0d  (expect 15)", DUT.DMEM.mem[0]);
        $display("---------------------------------------------");

        if (DUT.RF.regs[3] == 15 && DUT.RF.regs[4] == 15)
            $display("RESULT: PASS - core executed ADDI/ADD/SW/LW correctly");
        else
            $display("RESULT: FAIL - check datapath/control logic");

        $finish;
    end
endmodule
