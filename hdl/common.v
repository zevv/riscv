
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

`define ST_BOOT 0
`define ST_F_SP 1
`define ST_S_SP 2
`define ST_F_PC 3

`define ST_F_INST 4
`define ST_DECODE 5
// 6
`define ST_F_RS1 7
`define ST_F_RS2 8
`define ST_X_ALU_I_1 9
`define ST_X_ALU_I_2 10
`define ST_X_STORE_1 11
`define ST_X_STORE_2 12
// 13
// 14
`define ST_X_JAL_1 15
`define ST_X_BRANCH_1 16
`define ST_X_BRANCH_2 17
`define ST_X_ALU_R_1 18
`define ST_X_ALU_R_2 19
`define ST_X_LUI 20
`define ST_X_AUIPC 21
`define ST_X_JALR_1 22
`define ST_X_JALR_2 23
`define ST_X_LOAD_1 24
`define ST_X_LOAD_2 25
`define ST_X_LOAD_3 26
`define ST_X_LOAD_4 27

`define ST_FAULT 31