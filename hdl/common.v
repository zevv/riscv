
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
`define ST_F_SP 1
`define ST_S_SP 2
`define ST_F_PC 3
`define ST_F_INST 4
`define ST_DECODE 5
// 6
`define ST_F_REG 7
`define ST_S_REG 8
// 9
// 10
// 11
`define ST_X_STORE 12
// 13
// 14
`define ST_X_JAL 15
// 16
`define ST_X_BRANCH 17
// 18
`define ST_X_ALU_R 19
// 21
// 22
`define ST_X_JALR 22
// 23
// 24
`define ST_X_LOAD_1 25
`define ST_X_LOAD_2 26

`define ST_FAULT 31
