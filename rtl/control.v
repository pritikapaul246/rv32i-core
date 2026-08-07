module control(
    input      [6:0] opcode,
    input      [2:0] funct3,
    input      [6:0] funct7,
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       mem_to_reg,
    output reg       alu_src,
    output reg       branch,
    output reg       jump,
    output reg [3:0] alu_ctrl,
    output reg [2:0] imm_sel   // 0:I  1:S  2:B  3:U  4:J
);
    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_ITYPE  = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_LUI    = 7'b0110111;

    always @(*) begin
        // safe defaults every cycle
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_ctrl   = 4'b0000;
        imm_sel    = 3'd0;

        case (opcode)
            OP_RTYPE: begin
                reg_write = 1'b1;
                case ({funct7, funct3})
                    10'b0000000_000: alu_ctrl = 4'b0000; // ADD
                    10'b0100000_000: alu_ctrl = 4'b0001; // SUB
                    10'b0000000_111: alu_ctrl = 4'b0010; // AND
                    10'b0000000_110: alu_ctrl = 4'b0011; // OR
                    10'b0000000_100: alu_ctrl = 4'b0100; // XOR
                    10'b0000000_010: alu_ctrl = 4'b0101; // SLT
                    10'b0000000_001: alu_ctrl = 4'b0110; // SLL
                    10'b0000000_101: alu_ctrl = 4'b0111; // SRL
                    default:         alu_ctrl = 4'b0000;
                endcase
            end

            OP_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = 3'd0;
                case (funct3)
                    3'b000:  alu_ctrl = 4'b0000; // ADDI
                    3'b111:  alu_ctrl = 4'b0010; // ANDI
                    3'b110:  alu_ctrl = 4'b0011; // ORI
                    3'b100:  alu_ctrl = 4'b0100; // XORI
                    3'b010:  alu_ctrl = 4'b0101; // SLTI
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                imm_sel    = 3'd0;
                alu_ctrl   = 4'b0000; // address = base + offset
            end

            OP_STORE: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                imm_sel   = 3'd1;
                alu_ctrl  = 4'b0000;
            end

            OP_BRANCH: begin
                branch   = 1'b1;
                imm_sel  = 3'd2;
                alu_ctrl = 4'b0001; // SUB, then check zero flag (BEQ)
            end

            OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                imm_sel   = 3'd4;
            end

            OP_LUI: begin
                reg_write = 1'b1;
                imm_sel   = 3'd3;
            end

            default: ; // NOP / unimplemented opcode: all defaults hold
        endcase
    end
endmodule
