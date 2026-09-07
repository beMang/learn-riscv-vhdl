.text
.global main

main:
    # Setup test values
    # x1 =  5  (0x00000005)
    # x2 = 10  (0x0000000A)
    # x3 = -5  (0xFFFFFFFB - large number in unsigned, negative in signed)
    addi x1, x0, 5
    addi x2, x0, 10
    addi x3, x0, -5
    
    # x10 acts as the test progress marker (0 = starting)
    addi x10, x0, 0

    # ------------------------------------------------------------------
    # Test 1: BEQ (Branch if Equal)
    # ------------------------------------------------------------------
    addi x10, x10, 1        # Test 1 marker (x10 = 1)
    beq  x1, x2, fail       # 5 == 10 is FALSE -> Should NOT branch
    beq  x1, x1, test2      # 5 == 5  is TRUE  -> SHOULD branch
    beq  x0, x0, fail       # Unconditional jump to fail if branch above failed

    # ------------------------------------------------------------------
    # Test 2: BNE (Branch if Not Equal)
    # ------------------------------------------------------------------
test2:
    addi x10, x10, 1        # Test 2 marker (x10 = 2)
    bne  x1, x1, fail       # 5 != 5  is FALSE -> Should NOT branch
    bne  x1, x2, test3      # 5 != 10 is TRUE  -> SHOULD branch
    beq  x0, x0, fail

    # ------------------------------------------------------------------
    # Test 3: BLT (Branch if Less Than - Signed)
    # ------------------------------------------------------------------
test3:
    addi x10, x10, 1        # Test 3 marker (x10 = 3)
    blt  x2, x1, fail       # 10 < 5 is FALSE -> Should NOT branch
    blt  x3, x1, test4      # -5 < 5 is TRUE  -> SHOULD branch
    beq  x0, x0, fail

    # ------------------------------------------------------------------
    # Test 4: BGE (Branch if Greater Than or Equal - Signed)
    # ------------------------------------------------------------------
test4:
    addi x10, x10, 1        # Test 4 marker (x10 = 4)
    bge  x1, x2, fail       # 5 >= 10 is FALSE -> Should NOT branch
    bge  x1, x3, test5      # 5 >= -5 is TRUE  -> SHOULD branch
    beq  x0, x0, fail

    # ------------------------------------------------------------------
    # Test 5: BLTU (Branch if Less Than - Unsigned)
    # ------------------------------------------------------------------
test5:
    addi x10, x10, 1        # Test 5 marker (x10 = 5)
    bltu x3, x1, fail       # 0xFFFFFFFB < 5 is FALSE (unsigned) -> Should NOT branch
    bltu x1, x3, test6      # 5 < 0xFFFFFFFB is TRUE  (unsigned) -> SHOULD branch
    beq  x0, x0, fail

    # ------------------------------------------------------------------
    # Test 6: BGEU (Branch if Greater Than or Equal - Unsigned)
    # ------------------------------------------------------------------
test6:
    addi x10, x10, 1        # Test 6 marker (x10 = 6)
    bgeu x1, x3, fail       # 5 >= 0xFFFFFFFB is FALSE (unsigned) -> Should NOT branch
    bgeu x3, x1, pass       # 0xFFFFFFFB >= 5 is TRUE  (unsigned) -> SHOULD branch
    beq  x0, x0, fail

    # ------------------------------------------------------------------
    # End States
    # ------------------------------------------------------------------
pass:
    # All tests passed! Signal success in GTKWave by writing 255 to x10
    addi x10, x0, 255
pass_loop:
    beq  x0, x0, pass_loop  # Infinite loop on success

fail:
    # Test failed! x10 holds the failing test number (1 through 6)
fail_loop:
    beq  x0, x0, fail_loop  # Infinite loop on failure