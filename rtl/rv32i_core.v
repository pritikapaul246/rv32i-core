module rv32i_core(
    input             clk,
    input             rst_n,
    output     [31:0] pc_out,
    output     [31:0] instr_out
);
    reg  [31:0] pc;
    wire [31:0] instr;

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [4:0] rd     = instr[11:7];

    wire        reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, jump;
    wire [3:0]  alu_ctrl;
    wire [2:0]  imm_sel;
    wire [31:0] imm;
    wire [31:0] rdata1, rdata2;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [31:0] mem_rdata;
    wire [31:0] write_back_data;

    wire [31:0] pc_plus4      = pc + 32'd4;
    wire [31:0] branch_target = pc + imm;
    wire [31:0] jal_target    = pc + imm;
    wire        take_branch   = branch & alu_zero; // BEQ only, in this subset

    imem IMEM (
        .addr  (pc),
        .instr (instr)
    );

    control CTRL (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .alu_src    (alu_src),
        .branch     (branch),
        .jump       (jump),
        .alu_ctrl   (alu_ctrl),
        .imm_sel    (imm_sel)
    );

    imm_gen IMMGEN (
        .instr   (instr),
        .imm_sel (imm_sel),
        .imm_out (imm)
    );

    regfile RF (
        .clk (clk),
        .we  (reg_write),
        .ra1 (rs1),
        .ra2 (rs2),
        .wa  (rd),
        .wd  (write_back_data),
        .rd1 (rdata1),
        .rd2 (rdata2)
    );

    assign alu_b = alu_src ? imm : rdata2;

    alu ALU (
        .alu_ctrl (alu_ctrl),
        .a        (rdata1),
        .b        (alu_b),
        .result   (alu_result),
        .zero     (alu_zero)
    );

    dmem DMEM (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (alu_result),
        .wdata     (rdata2),
        .rdata     (mem_rdata)
    );

    assign write_back_data = jump                    ? pc_plus4    :
                              mem_to_reg               ? mem_rdata   :
                              (opcode == 7'b0110111)    ? imm         : // LUI
                                                          alu_result;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'b0;
        else if (jump)
            pc <= jal_target;
        else if (take_branch)
            pc <= branch_target;
        else
            pc <= pc_plus4;
    end

    assign pc_out    = pc;
    assign instr_out = instr;
endmodule
