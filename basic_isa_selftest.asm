# Basic ISA self-test.
# FAIL = memory[128] / PC 512; PASS = memory[224] / PC 896.
# This is NOT a hazard-free pipeline test.
# It includes dependency checks via BNE/JAL.
# Assembly assumes RV32I, fixed 4-byte instructions.
.option norvc
.option norelax
.text
.org 0

# Test 0: Bootstrap BNE and ADDI checks
    addi x10, x0, 0              # PC 0, memory[0] | 00000513
    addi x3, x0, 1               # PC 4, memory[1] | 00100193
    addi x4, x0, 2               # PC 8, memory[2] | 00200213
    bne x3, x4, word_5           # PC 12, memory[3] | 00419463
    jal x0, FAIL                 # PC 16, memory[4] | 1F00006F
word_5:
    bne x3, x3, FAIL             # PC 20, memory[5] | 1E319663
    addi x1, x0, 5               # PC 24, memory[6] | 00500093
    addi x2, x0, 6               # PC 28, memory[7] | 00600113

# Test 1: ADD with x1=5, x2=6
    addi x10, x0, 1              # PC 32, memory[8] | 00100513
    add x3, x1, x2               # PC 36, memory[9] | 002081B3
    addi x4, x0, 11              # PC 40, memory[10] | 00B00213
    bne x3, x4, FAIL             # PC 44, memory[11] | 1C419A63

# Test 2: SUB with x1=5, x2=6
    addi x10, x0, 2              # PC 48, memory[12] | 00200513
    sub x3, x1, x2               # PC 52, memory[13] | 402081B3
    addi x4, x0, -1              # PC 56, memory[14] | FFF00213
    bne x3, x4, FAIL             # PC 60, memory[15] | 1C419263

# Test 3: SLL with x1=5, x2=6
    addi x10, x0, 3              # PC 64, memory[16] | 00300513
    sll x3, x1, x2               # PC 68, memory[17] | 002091B3
    addi x4, x0, 320             # PC 72, memory[18] | 14000213
    bne x3, x4, FAIL             # PC 76, memory[19] | 1A419A63

# Test 4: SRL with x1=5, x2=6
    addi x10, x0, 4              # PC 80, memory[20] | 00400513
    srl x3, x1, x2               # PC 84, memory[21] | 0020D1B3
    addi x4, x0, 0               # PC 88, memory[22] | 00000213
    bne x3, x4, FAIL             # PC 92, memory[23] | 1A419263

# Test 5: SRA with x1=5, x2=6
    addi x10, x0, 5              # PC 96, memory[24] | 00500513
    sra x3, x1, x2               # PC 100, memory[25] | 4020D1B3
    addi x4, x0, 0               # PC 104, memory[26] | 00000213
    bne x3, x4, FAIL             # PC 108, memory[27] | 18419A63

# Test 6: AND with x1=5, x2=6
    addi x10, x0, 6              # PC 112, memory[28] | 00600513
    and x3, x1, x2               # PC 116, memory[29] | 0020F1B3
    addi x4, x0, 4               # PC 120, memory[30] | 00400213
    bne x3, x4, FAIL             # PC 124, memory[31] | 18419263

# Test 7: OR with x1=5, x2=6
    addi x10, x0, 7              # PC 128, memory[32] | 00700513
    or x3, x1, x2                # PC 132, memory[33] | 0020E1B3
    addi x4, x0, 7               # PC 136, memory[34] | 00700213
    bne x3, x4, FAIL             # PC 140, memory[35] | 16419A63

# Test 8: XOR with x1=5, x2=6
    addi x10, x0, 8              # PC 144, memory[36] | 00800513
    xor x3, x1, x2               # PC 148, memory[37] | 0020C1B3
    addi x4, x0, 3               # PC 152, memory[38] | 00300213
    bne x3, x4, FAIL             # PC 156, memory[39] | 16419263

# Test 9: SLT with x1=5, x2=6
    addi x10, x0, 9              # PC 160, memory[40] | 00900513
    slt x3, x1, x2               # PC 164, memory[41] | 0020A1B3
    addi x4, x0, 1               # PC 168, memory[42] | 00100213
    bne x3, x4, FAIL             # PC 172, memory[43] | 14419A63

# Test 10: SLTU with x1=5, x2=6
    addi x10, x0, 10             # PC 176, memory[44] | 00A00513
    sltu x3, x1, x2              # PC 180, memory[45] | 0020B1B3
    addi x4, x0, 1               # PC 184, memory[46] | 00100213
    bne x3, x4, FAIL             # PC 188, memory[47] | 14419263

# Test 11: ADDI immediate -1
    addi x10, x0, 11             # PC 192, memory[48] | 00B00513
    addi x3, x0, -1              # PC 196, memory[49] | FFF00193
    addi x4, x0, -1              # PC 200, memory[50] | FFF00213
    bne x3, x4, FAIL             # PC 204, memory[51] | 12419A63

# Test 12: SLLI immediate 2
    addi x10, x0, 12             # PC 208, memory[52] | 00C00513
    slli x3, x1, 2               # PC 212, memory[53] | 00209193
    addi x4, x0, 20              # PC 216, memory[54] | 01400213
    bne x3, x4, FAIL             # PC 220, memory[55] | 12419263

# Test 13: SRLI immediate 2
    addi x10, x0, 13             # PC 224, memory[56] | 00D00513
    srli x3, x1, 2               # PC 228, memory[57] | 0020D193
    addi x4, x0, 1               # PC 232, memory[58] | 00100213
    bne x3, x4, FAIL             # PC 236, memory[59] | 10419A63

# Test 14: SRAI immediate 2
    addi x10, x0, 14             # PC 240, memory[60] | 00E00513
    srai x3, x1, 2               # PC 244, memory[61] | 4020D193
    addi x4, x0, 1               # PC 248, memory[62] | 00100213
    bne x3, x4, FAIL             # PC 252, memory[63] | 10419263

# Test 15: ANDI immediate 4
    addi x10, x0, 15             # PC 256, memory[64] | 00F00513
    andi x3, x1, 4               # PC 260, memory[65] | 0040F193
    addi x4, x0, 4               # PC 264, memory[66] | 00400213
    bne x3, x4, FAIL             # PC 268, memory[67] | 0E419A63

# Test 16: ORI immediate 4
    addi x10, x0, 16             # PC 272, memory[68] | 01000513
    ori x3, x1, 4                # PC 276, memory[69] | 0040E193
    addi x4, x0, 5               # PC 280, memory[70] | 00500213
    bne x3, x4, FAIL             # PC 284, memory[71] | 0E419263

# Test 17: XORI immediate 4
    addi x10, x0, 17             # PC 288, memory[72] | 01100513
    xori x3, x1, 4               # PC 292, memory[73] | 0040C193
    addi x4, x0, 1               # PC 296, memory[74] | 00100213
    bne x3, x4, FAIL             # PC 300, memory[75] | 0C419A63

# Test 18: SLTI immediate 4
    addi x10, x0, 18             # PC 304, memory[76] | 01200513
    slti x3, x1, 4               # PC 308, memory[77] | 0040A193
    addi x4, x0, 0               # PC 312, memory[78] | 00000213
    bne x3, x4, FAIL             # PC 316, memory[79] | 0C419263

# Test 19: SLTIU immediate 4
    addi x10, x0, 19             # PC 320, memory[80] | 01300513
    sltiu x3, x1, 4              # PC 324, memory[81] | 0040B193
    addi x4, x0, 0               # PC 328, memory[82] | 00000213
    bne x3, x4, FAIL             # PC 332, memory[83] | 0A419A63

# Test 20: ADDI with x1=5, negative immediate -7
    addi x10, x0, 20             # PC 336, memory[84] | 01400513
    addi x3, x1, -7              # PC 340, memory[85] | FF908193
    addi x4, x0, -2              # PC 344, memory[86] | FFE00213
    bne x3, x4, FAIL             # PC 348, memory[87] | 0A419263

# Test 21: ANDI with x1=5, negative immediate -2
    addi x10, x0, 21             # PC 352, memory[88] | 01500513
    andi x3, x1, -2              # PC 356, memory[89] | FFE0F193
    addi x4, x0, 4               # PC 360, memory[90] | 00400213
    bne x3, x4, FAIL             # PC 364, memory[91] | 08419A63

# Test 22: ORI with x1=5, negative immediate -8
    addi x10, x0, 22             # PC 368, memory[92] | 01600513
    ori x3, x1, -8               # PC 372, memory[93] | FF80E193
    addi x4, x0, -3              # PC 376, memory[94] | FFD00213
    bne x3, x4, FAIL             # PC 380, memory[95] | 08419263

# Test 23: XORI with x1=5, negative immediate -1
    addi x10, x0, 23             # PC 384, memory[96] | 01700513
    xori x3, x1, -1              # PC 388, memory[97] | FFF0C193
    addi x4, x0, -6              # PC 392, memory[98] | FFA00213
    bne x3, x4, FAIL             # PC 396, memory[99] | 06419A63

# Test 24: SLTI with x1=5, negative immediate -1
    addi x10, x0, 24             # PC 400, memory[100] | 01800513
    slti x3, x1, -1              # PC 404, memory[101] | FFF0A193
    addi x4, x0, 0               # PC 408, memory[102] | 00000213
    bne x3, x4, FAIL             # PC 412, memory[103] | 06419263

# Test 25: SLTIU with x1=5, negative immediate -1
    addi x10, x0, 25             # PC 416, memory[104] | 01900513
    sltiu x3, x1, -1             # PC 420, memory[105] | FFF0B193
    addi x4, x0, 1               # PC 424, memory[106] | 00100213
    bne x3, x4, FAIL             # PC 428, memory[107] | 04419A63
    addi x1, x0, -5              # PC 432, memory[108] | FFB00093
    addi x2, x0, 2               # PC 436, memory[109] | 00200113

# Test 26: SRA with x1=-5, x2=2
    addi x10, x0, 26             # PC 440, memory[110] | 01A00513
    sra x3, x1, x2               # PC 444, memory[111] | 4020D1B3
    addi x4, x0, -2              # PC 448, memory[112] | FFE00213
    bne x3, x4, FAIL             # PC 452, memory[113] | 02419E63

# Test 27: SRL with x1=-5, x2=2
    addi x10, x0, 27             # PC 456, memory[114] | 01B00513
    srl x3, x1, x2               # PC 460, memory[115] | 0020D1B3
    lui x4, 0x40000              # PC 464, memory[116] | 40000237
    addi x4, x4, -2              # PC 468, memory[117] | FFE20213
    bne x3, x4, FAIL             # PC 472, memory[118] | 02419463

# Test 28: SLT with x1=-5, x2=2
    addi x10, x0, 28             # PC 476, memory[119] | 01C00513
    slt x3, x1, x2               # PC 480, memory[120] | 0020A1B3
    addi x4, x0, 1               # PC 484, memory[121] | 00100213
    bne x3, x4, FAIL             # PC 488, memory[122] | 00419C63

# Test 29: SLTU with x1=-5, x2=2
    addi x10, x0, 29             # PC 492, memory[123] | 01D00513
    sltu x3, x1, x2              # PC 496, memory[124] | 0020B1B3
    addi x4, x0, 0               # PC 500, memory[125] | 00000213
    bne x3, x4, FAIL             # PC 504, memory[126] | 00419463

# Skip reserved FAIL loop; resume test 30 at memory[132]
    jal x0, CONTINUE_TEST30      # PC 508, memory[127] | 0140006F

# FAIL: PC 512, pc[9:7] = 100
FAIL:
    jal x0, FAIL                 # PC 512, memory[128] | 0000006F
    addi x0, x0, 0               # PC 516, memory[129] | 00000013
    addi x0, x0, 0               # PC 520, memory[130] | 00000013

# Test 30: SRAI with x1=-5, shift 2
.org 528
CONTINUE_TEST30:
    addi x10, x0, 30             # PC 528, memory[132] | 01E00513
    srai x3, x1, 2               # PC 532, memory[133] | 4020D193
    addi x4, x0, -2              # PC 536, memory[134] | FFE00213
    bne x3, x4, FAIL             # PC 540, memory[135] | FE4192E3
    addi x7, x0, 8               # PC 544, memory[136] | 00800393
    addi x1, x0, 5               # PC 548, memory[137] | 00500093

# Test 31: SW/LW positive offset: address 0+4, value 5
    addi x10, x0, 31             # PC 552, memory[138] | 01F00513
    sw x1, 4(x0)                 # PC 556, memory[139] | 00102223
    lw x3, 4(x0)                 # PC 560, memory[140] | 00402183
    addi x4, x0, 5               # PC 564, memory[141] | 00500213
    bne x3, x4, FAIL             # PC 568, memory[142] | FC4194E3
    addi x1, x0, -5              # PC 572, memory[143] | FFB00093

# Test 32: SW/LW negative offset: address 8-4, value -5
    addi x10, x0, 32             # PC 576, memory[144] | 02000513
    sw x1, -4(x7)                # PC 580, memory[145] | FE13AE23
    lw x3, -4(x7)                # PC 584, memory[146] | FFC3A183
    addi x4, x0, -5              # PC 588, memory[147] | FFB00213
    bne x3, x4, FAIL             # PC 592, memory[148] | FA4198E3

# Test 33: LUI upper immediate 4
    addi x10, x0, 33             # PC 596, memory[149] | 02100513
    lui x3, 4                    # PC 600, memory[150] | 000041B7
    addi x4, x0, 4               # PC 604, memory[151] | 00400213
    slli x4, x4, 12              # PC 608, memory[152] | 00C21213
    bne x3, x4, FAIL             # PC 612, memory[153] | F8419EE3

# Test 34: LUI with bit 31 set
    addi x10, x0, 34             # PC 616, memory[154] | 02200513
    lui x3, 0x80000              # PC 620, memory[155] | 800001B7
    addi x4, x0, 1               # PC 624, memory[156] | 00100213
    slli x4, x4, 31              # PC 628, memory[157] | 01F21213
    bne x3, x4, FAIL             # PC 632, memory[158] | F84194E3

# Test 35: AUIPC upper immediate 4
    addi x10, x0, 35             # PC 636, memory[159] | 02300513
    auipc x3, 4                  # PC 640, memory[160] | 00004197
    lui x4, 0x00004              # PC 644, memory[161] | 00004237
    addi x4, x4, 640             # PC 648, memory[162] | 28020213
    bne x3, x4, FAIL             # PC 652, memory[163] | F6419AE3

# Test 36: AUIPC negative upper immediate (-4096)
    addi x10, x0, 36             # PC 656, memory[164] | 02400513
    auipc x3, 0xfffff            # PC 660, memory[165] | FFFFF197
    lui x4, 0xfffff              # PC 664, memory[166] | FFFFF237
    addi x4, x4, 660             # PC 668, memory[167] | 29420213
    bne x3, x4, FAIL             # PC 672, memory[168] | F64190E3
    addi x10, x0, 0              # PC 676, memory[169] | 00000513

# All tests passed: jump to PASS, followed by two NOPs
    jal x0, PASS                 # PC 680, memory[170] | 0D80006F
    addi x0, x0, 0               # PC 684, memory[171] | 00000013
    addi x0, x0, 0               # PC 688, memory[172] | 00000013

# PASS: PC 896, pc[9:7] = 111
.org 896
PASS:
    jal x0, PASS                 # PC 896, memory[224] | 0000006F
    addi x0, x0, 0               # PC 900, memory[225] | 00000013
    addi x0, x0, 0               # PC 904, memory[226] | 00000013
