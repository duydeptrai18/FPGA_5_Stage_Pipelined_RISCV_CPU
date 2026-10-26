# Forwarding and stall and flush test cases.
# x10 = test number ID
# x3  = actual result
# x4  = expected result
#
# FAIL: PC 512, pc[9:7] = 100
# PASS: PC 896, pc[9:7] = 111

# Test 0: Immediate dependency on rs1.
addi x10, x0, 0
addi x1,  x0, 4
addi x2,  x0, 4
add  x3,  x2, x1
addi x4,  x0, 8
bne  x3,  x4, FAIL

# Test 1: Immediate dependency on rs2.
addi x10, x0, 1
addi x1,  x0, 4
addi x2,  x0, 5
add  x3,  x1, x2
addi x4,  x0, 9
bne  x3,  x4, FAIL

# Test 2: Both operands need the same new value.
addi x10, x0, 2
addi x1,  x0, 4
addi x2,  x0, 6
add  x3,  x2, x2
addi x4,  x0, 12
bne  x3,  x4, FAIL

# Test 3: Operands from different producers.
addi x10, x0, 3
addi x1,  x0, 7
addi x2,  x0, 8
add  x3,  x1, x2
addi x4,  x0, 15
bne  x3,  x4, FAIL

# Test 4: One unrelated instruction between producer and consumer.
addi x10, x0, 4
addi x1,  x0, 4
addi x2,  x0, 9
addi x5,  x0, 99
add  x3,  x2, x1
addi x4,  x0, 13
bne  x3,  x4, FAIL

# Test 5: Two unrelated instructions between producer and consumer.
addi x10, x0, 5
addi x1,  x0, 4
addi x2,  x0, 10
addi x5,  x0, 21
addi x6,  x0, 22
add  x3,  x2, x1
addi x4,  x0, 14
bne  x3,  x4, FAIL

# Test 6: Newest write to the same register wins.
addi x10, x0, 6
addi x1,  x0, 4
addi x2,  x0, 11
addi x2,  x0, 12
add  x3,  x2, x1
addi x4,  x0, 16
bne  x3,  x4, FAIL

# Test 7: Chain of dependent updates.
addi x10, x0, 7
addi x3,  x0, 4
addi x3,  x3, 1
addi x3,  x3, 2
addi x4,  x0, 7
bne  x3,  x4, FAIL

# Test 8a + 8b: Store-address and load-address forwarding.
addi x10, x0, 8
addi x1,  x0, 4
addi x4,  x0, 4
addi x2,  x0, 0
sw   x1,  0(x2)
addi x2,  x0, 0
lw   x3,  0(x2)
bne  x3,  x4, FAIL

# Test 9: Store-data forwarding only.
addi x10, x0, 9
addi x2,  x0, 0
addi x1,  x0, 42
sw   x1,  0(x0)
lw   x3,  0(x0)
addi x4,  x0, 42
bne  x3,  x4, FAIL

# Test 10: Forward both store address and store data.
addi x10, x0, 10
addi x2,  x0, 0
addi x1,  x0, 55
sw   x1,  0(x2)
lw   x3,  0(x0)
addi x4,  x0, 55
bne  x3,  x4, FAIL

# Test 11a: Forward BNE operands; branch must NOT be taken.
addi x10, x0, 11
addi x1,  x0, 5
addi x0,  x0, 0
addi x0,  x0, 0
addi x2,  x0, 5
bne  x2,  x1, FAIL

# Test 11b: Forward BLT operands; branch must NOT be taken.
addi x10, x0, 12
addi x1,  x0, 5
addi x0,  x0, 0
addi x0,  x0, 0
addi x2,  x0, 5
blt  x1,  x2, FAIL

# Test 12: Forward results from LUI and AUIPC.
# x3 and x4 = results; x5 and x6 = expected values.
addi x10, x0, 12
lui  x1, 4
addi x3, x1, 0       # x3 = 16384
auipc x2, 0          # PC = 356
addi x4, x2, 0       # x4 = 356
addi x5, x0, 1
slli x5, x5, 14      # Expected LUI result = 16384
addi x6, x0, 356     # Expected AUIPC result = 356
bne  x3, x5, FAIL
bne  x4, x6, FAIL

# Test 13: Load-use dependency in ADD.
# Test 10 left data memory[0] = 55.
addi x10, x0, 13
addi x2, x0, 4
lw   x1, 0(x0)
add  x3, x1, x2      # x3 = 59
addi x4, x0, 59
bne  x3, x4, FAIL

# Test 14: Load-use dependency in store data.
# Copy data memory[0] to data memory[1], then read it back.
addi x10, x0, 14
lw   x1, 0(x0)
sw   x1, 4(x0)
lw   x3, 4(x0)       # x3 = 55
addi x4, x0, 55
bne  x3, x4, FAIL

# Test 15: Writes to x0 must be ignored.
addi x10, x0, 15
addi x2, x0, 4
addi x0, x0, 7       # x0 remains 0
add  x3, x0, x2      # x3 = 4
addi x4, x0, 4
bne  x3, x4, FAIL

# Continue from test 15 at memory[114]. Because Fail occupies memory[128]
jal  x0, TEST16
addi x0, x0, 0
addi x0, x0, 0


# Test 16: Taken branch must flush both following instructions.
.org 528
TEST16:
    addi x10, x0, 16
    addi x12, x0, 0
    addi x13, x0, 0
    addi x4,  x0, 0
    addi x1,  x0, 5
    addi x2,  x0, 5
    beq  x1,  x2, BRANCH_TARGET

    # Wrong path: both must be flushed.
    addi x12, x0, 5
    addi x13, x0, 6

BRANCH_TARGET:
    bne x12, x4, FAIL
    bne x13, x4, FAIL

# Test 17: JALR base forwarding, flush, and return address.
    addi x10, x0, 17
    addi x16, x0, 0
    addi x17, x0, 0
    addi x4,  x0, 0
    addi x14, x0, 604
    jalr x15, 0(x14)      # Target = 604; return address = 596

    # Wrong path: both must be flushed.
    addi x16, x0, 1
    addi x17, x0, 2

JALR_TARGET:
    addi x5, x0, 596
    bne x16, x4, FAIL
    bne x17, x4, FAIL
    bne x15, x5, FAIL

# Test 18: JAL flush and return address.
    addi x10, x0, 18
    addi x20, x0, 0
    addi x21, x0, 0
    addi x4,  x0, 0
    jal  x19, JAL_TARGET  # Return address = 640

    # Wrong path: both must be flushed.
    addi x20, x0, 1
    addi x21, x0, 2

JAL_TARGET:
    addi x5, x0, 640
    bne x20, x4, FAIL
    bne x21, x4, FAIL
    bne x19, x5, FAIL

# Test 19: Load-use dependency in branch operands.
# Starts at memory[166], PC = 664.
addi x10, x0, 19
addi x4,  x0, 55
lw   x3,  0(x0)         # x3 = 55
bne  x3,  x4, FAIL

# Test 20: Load-use dependency in the next load's base address.
addi x10, x0, 20
addi x4,  x0, 55
lw   x1,  0(x0)         # x1 = 55
lw   x3,  -51(x1)       # Address 4 -> data memory[1] = 55
bne  x3,  x4, FAIL

# Test 21: Load-use dependency in JALR's base register.
addi x10, x0, 21
lw   x1,  0(x0)         # x1 = 55
jalr x0,  665(x1)       # Target = 720 -> memory[180]

# Test 22: Two NOPs after JALR.
addi x0, x0, 0
addi x0, x0, 0

# Test 23: Branch immediate bits must not create false forwarding.
JALR_LOAD_TARGET:
    addi x10, x0, 23
    addi x8,  x0, 352
    addi x1,  x0, 8
    addi x2,  x0, 4

    # Offset +8 makes instruction[11:7] resemble rd = x8.
    # Condition 8 < 4 is false.
    blt  x1, x2, FALSE_BRANCH_TARGET
    add  x3, x0, x8     # Must use x8 = 352

FALSE_BRANCH_TARGET:
    addi x4, x0, 352
    bne  x3, x4, FAIL


# All tests passed.
    jal  x0, PASS
    addi x0, x0, 0
    addi x0, x0, 0

.org 512
FAIL:
    jal  x0, FAIL
    addi x0, x0, 0
    addi x0, x0, 0

.org 896
PASS:
    jal  x0, PASS
    addi x0, x0, 0
    addi x0, x0, 0