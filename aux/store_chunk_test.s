.text
.global main

main:
    # ------------------------------------------------------------------
    # Setup Base Memory Address & Progress Marker
    # ------------------------------------------------------------------
    addi x3, x0, 1000        # Base Address = 1000 (Word Index 250)
    addi x10, x0, 0          # Test Progress Marker (x10)

    # ------------------------------------------------------------------
    # Setup Test Data Patterns (Without 12-bit immediate overflow)
    # ------------------------------------------------------------------
    # x1 = 0xAA
    # x2 = 0xBB
    # x30 = 0x0000CCDD
    addi x1, x0, 0xAA
    addi x2, x0, 0xBB
    
    addi x30, x0, 0xCC       # Build 0xCCDD safely
    slli x30, x30, 8
    ori  x30, x30, 0xDD      # x30 = 0x0000CCDD

    # ------------------------------------------------------------------
    # Test 1: Store Byte (SB) Across All 4 Byte Lanes
    # Target Word Index 250 (Mem[1000])
    # Expected word in Mem[1000]: 0xBBAA33AA
    # ------------------------------------------------------------------
    addi x10, x10, 1         # Marker 1 (x10 = 1)
    
    # Initialize Mem[1000] to zero
    sw   x0, 0(x3)

    # Store individual bytes
    addi x5, x0, 0x33
    sb   x1, 0(x3)           # Byte 0 (0xAA)
    sb   x5, 1(x3)           # Byte 1 (0x33)
    sb   x1, 2(x3)           # Byte 2 (0xAA)
    sb   x2, 3(x3)           # Byte 3 (0xBB)

    # Load full 32-bit word back and verify
    lw   x6, 0(x3)
    
    # Build expected target 0xBBAA33AA in x7
    addi x7, x0, 0xBB        # x7 = 0x000000BB
    slli x7, x7, 8
    ori  x7, x7, 0xAA        # x7 = 0x0000BBAA
    slli x7, x7, 8
    ori  x7, x7, 0x33        # x7 = 0x00BBAA33
    slli x7, x7, 8
    ori  x7, x7, 0xAA        # x7 = 0xBBAA33AA (Exact Match!)
    
    bne  x6, x7, fail

    # ------------------------------------------------------------------
    # Test 2: Store Halfword (SH) Lower and Upper Lanes
    # Target Word Index 251 (Mem[1004])
    # Expected Word: 0xCCDDCCDD
    # ------------------------------------------------------------------
    addi x10, x10, 1         # Marker 2 (x10 = 2)

    # Initialize Mem[1004] to zero
    sw   x0, 4(x3)

    # Write Lower Half (Bytes 0 & 1) and Upper Half (Bytes 2 & 3)
    sh   x30, 4(x3)          # Write 0xCCDD to Bytes 0 & 1
    sh   x30, 6(x3)          # Write 0xCCDD to Bytes 2 & 3

    # Load full 32-bit word back
    lw   x8, 4(x3)

    # Build expected target 0xCCDDCCDD in x9
    addi x9, x0, 0xCC
    slli x9, x9, 8
    ori  x9, x9, 0xDD
    slli x9, x9, 8
    ori  x9, x9, 0xCC
    slli x9, x9, 8
    ori  x9, x9, 0xDD        # x9 = 0xCCDDCCDD
    
    bne  x8, x9, fail

    # ------------------------------------------------------------------
    # Test 3: Modify a Single Byte Inside an Existing Word
    # Overwrite Byte 1 of Mem[1004] with 0xFF
    # Expected Result: 0xCCDDFFDD
    # ------------------------------------------------------------------
    addi x10, x10, 1         # Marker 3 (x10 = 3)

    addi x11, x0, 0xFF
    sb   x11, 5(x3)          # Overwrite Mem[1005] (Byte 1)

    lw   x12, 4(x3)          # Load full word back

    # Build expected target 0xCCDDFFDD in x13
    addi x13, x0, 0xCC
    slli x13, x13, 8
    ori  x13, x13, 0xDD
    slli x13, x13, 8
    ori  x13, x13, 0xFF
    slli x13, x13, 8
    ori  x13, x13, 0xDD      # x13 = 0xCCDDFFDD

    bne  x12, x13, fail

    # ------------------------------------------------------------------
    # End States
    # ------------------------------------------------------------------
pass:
    addi x10, x0, 255        # x10 = 255 (SUCCESS!)
pass_loop:
    beq  x0, x0, pass_loop

fail:
    # x10 holds failing test stage (1, 2, or 3)
fail_loop:
    beq  x0, x0, fail_loop