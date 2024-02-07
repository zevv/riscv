
`define OP_ALU_R  7'b0110011
`define OP_ALU_I  7'b0010011
`define OP_LOAD   7'b0000011
`define OP_STORE  7'b0100011
`define OP_BRANCH 7'b1100011
`define OP_JAL    7'b1101111
`define OP_JALR   7'b1100111
`define OP_LUI    7'b0110111
`define OP_AUIPC  7'b0010111

`define BR_BEQ 3'h0
`define BR_BNE 3'h1
`define BR_BLT 3'h4
`define BR_BGE 3'h5
`define BR_BLTU 3'h6
`define BR_BGEU 3'h7

`define ALU_FN_ADD 4'h0
`define ALU_FN_SUB 4'h8
`define ALU_FN_SLL 4'h1
`define ALU_FN_LT  4'h2
`define ALU_FN_LTU 4'h3
`define ALU_FN_XOR 4'h4
`define ALU_FN_SRL 4'h5
`define ALU_FN_OR  4'h6
`define ALU_FN_AND 4'h7
`define ALU_FN_SRA 4'hd

`define ST_BOOT 0
`define ST_F_PC 1
`define ST_F_SP 2
`define ST_S_SP 3
`define ST_F_INST 4
`define ST_DECODE 5
`define ST_RD_REG 6
`define ST_WB_REG 7
`define ST_X_STORE 8
`define ST_X_JAL 9
`define ST_X_BRANCH 10
`define ST_X_JALR 11
`define ST_X_LOAD_1 12
`define ST_X_LOAD_2 13
`define ST_FAULT 15

`define ALU_X_RS1 2'h0
`define ALU_X_PC 2'h1
`define ALU_X_ZERO 2'h2

`define ALU_Y_IMM 2'h0
`define ALU_Y_RS2 2'h1
`define ALU_Y_FOUR 2'h2

`define VEC_RESET 16'h0000
`define VEC_SP    16'h0004

`define REG_ZERO   'h00
`define REG_RA     'h01
`define REG_SP     'h02
`define REG_GP     'h03
`define REG_TP     'h04
`define REG_T0     'h05
`define REG_T1     'h06
`define REG_T2     'h07
`define REG_S0     'h08
`define REG_S1     'h09
`define REG_A0     'h0a
`define REG_A1     'h0b
`define REG_A2     'h0c
`define REG_A3     'h0d
`define REG_A4     'h0e
`define REG_A5     'h0f
`define REG_A6     'h10
`define REG_A7     'h11
`define REG_S2     'h12
`define REG_S3     'h13
`define REG_S4     'h14
`define REG_S5     'h15
`define REG_S6     'h16
`define REG_S7     'h17
`define REG_S8     'h18
`define REG_S9     'h19
`define REG_S10    'h1a
`define REG_S11    'h1b
`define REG_T3     'h1c
`define REG_T4     'h1d
`define REG_T5     'h1e
`define REG_T6     'h1f
