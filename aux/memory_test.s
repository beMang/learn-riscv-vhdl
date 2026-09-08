.text
.global main

main:
    # ------------------------------------------------------------------
    # Step 1: Construct Test Patterns without LUI
    # ------------------------------------------------------------------
    # Pattern 1: x1 = 0x12345678
    addi x1, x0, 0x123
    slli x1, x1, 12
    ori  x1, x1, 0x456
    slli x1, x1, 8
    ori  x1, x1, 0x78

    # Pattern 2: x2 = 0xABCDEF01
    # Using negative signed 12-bit representations:
    # -1348 (0xFABC) sign-extends to 0xFFFFFABC
    # -529  (0xFDEF) sign-extends to 0xFFFFFDEF
    addi x2, x0, -1348       # Upper bits for 0xABC
    slli x2, x2, 12
    ori  x2, x2, -529        # Upper bits for 0xDEF
    slli x2, x2, 8
    ori  x2, x2, 0x01        # x2 = 0xABCDEF01

    # Base memory addresses
    addi x3, x0, 1000        # Base 1: 1000 (0x03E8) -> Word Index 250
    addi x4, x0, 1024        # Base 2: 1024 (0x0400) -> Word Index 256

    # Test progress marker (x10)
    addi x10, x0, 0

    # ------------------------------------------------------------------
    # Test 1: Basic SW and LW (Zero Offset)
    # Store x1 at Mem[1000], load it back into x5, verify x5 == x1
    # ------------------------------------------------------------------
    addi x10, x10, 1         # Marker 1 (x10 = 1)
    sw   x1, 0(x3)           # Store 0x12345678 at Mem[1000]
    lw   x5, 0(x3)           # Load back into x5
    bne  x1, x5, fail        # Verify loaded data matches pattern 1

    # ------------------------------------------------------------------
    # Test 2: Positive Offset SW and LW
    # Store x2 at Mem[1004], load into x6, verify x6 == x2
    # ------------------------------------------------------------------
    addi x10, x10, 1         # Marker 2 (x10 = 2)
    sw   x2, 4(x3)           # Store 0xABCDEF01 at Mem[1004]
    lw   x6, 4(x3)           # Load back into x6
    bne  x2, x6, fail        # Verify loaded data matches pattern 2

    # ------------------------------------------------------------------
    # Test 3: Negative Offset SW and LW
    # Store x1 at Mem[996], load into x7 using Base 1 (-4 offset)
    # ------------------------------------------------------------------
    addi x10, x10, 1         # Marker 3 (x10 = 3)
    sw   x1, -4(x3)          # Store 0x12345678 at Mem[996]
    lw   x7, -4(x3)          # Load back into x7
    bne  x1, x7, fail        # Verify loaded data matches pattern 1

    # ------------------------------------------------------------------
    # Test 4: Cross-Base Address LW Verification
    # Read Mem[1004] (Index 251) using Base 2 with -20 offset (1024 - 20 = 1004)
    # ------------------------------------------------------------------
    addi x10, x10, 1         # Marker 4 (x10 = 4)
    lw   x8, -20(x4)         # Load from Mem[1004] into x8
    bne  x2, x8, fail        # Verify x8 holds pattern 2 (0xABCDEF01)

    # ------------------------------------------------------------------
    # Test 5: LW Zero Value
    # Store x0 at Mem[1008], load into x9, verify x9 == 0
    # ------------------------------------------------------------------
    addi x10, x10, 1         # Marker 5 (x10 = 5)
    sw   x0, 8(x3)           # Store 0 at Mem[1008]
    lw   x9, 8(x3)           # Load into x9
    bne  x0, x9, fail        # Verify x9 == 0

    # ------------------------------------------------------------------
    # End States
    # ------------------------------------------------------------------
pass:
    # All LOAD and STORE tests passed successfully!
    addi x10, x0, 255        # Signal complete (x10 = 0xFF)
pass_loop:
    beq  x0, x0, pass_loop   # Infinite loop on pass

fail:
    # Test failed! x10 holds the specific failing step (1 through 5)
fail_loop:
    beq  x0, x0, fail_loop   # Infinite loop on fail