module dmem(
    input             clk,
    input             mem_read,
    input             mem_write,
    input      [31:0] addr,
    input      [31:0] wdata,
    output     [31:0] rdata
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end

    assign rdata = mem_read ? mem[addr[9:2]] : 32'b0;

    always @(posedge clk) begin
        if (mem_write)
            mem[addr[9:2]] <= wdata;
    end
endmodule
