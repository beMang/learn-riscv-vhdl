.text
.global main

main:
    # Initialize test progress vector (x10 = 0)
    addi x10, x0, 0

    # ------------------------------------------------------------------
    # Test 1: Forward JAL & Return Address Link Check
    # ------------------------------------------------------------------
    addi x10, x10, 1        # Marker 1 (x10 = 1)
    
    # Executing JAL should:
    # 1. Save address of (addi x10, x10, 25) into x1 (ra)
    # 2. Jump forward to test1_target
    jal  x1, test1_target   
    
    # Trap: If JAL fails to jump, execution hits this fail sequence
    addi x10, x10, 25       
    beq  x0, x0, fail       

test1_target:
    # Verify return address written to x1:
    # Address of (jal x1, test1_target) was PC = 4 (or base address + 0x04)
    # Target address of next instruction after JAL is stored in x1.
    # We test if x1 is non-zero (must hold return address)
    beq  x1, x0, fail       # If x1 was not updated (remains 0), fail!

    # ------------------------------------------------------------------
    # Test 2: Backward JAL
    # ------------------------------------------------------------------
    addi x10, x10, 1        # Marker 2 (x10 = 2)
    
    # Jump ahead to land_here to setup backward jump test
    jal  x0, land_here      # Using x0 discards return address

backward_target:
    # Successfully arrived via backward jump!
    jal  x0, test3_start

land_here:
    # Jump backward to backward_target
    jal  x8, backward_target
    
    # Trap: Should never reach here
    beq  x0, x0, fail

    # ------------------------------------------------------------------
    # Test 3: JAL to x0 (discard link)
    # ------------------------------------------------------------------
test3_start:
    addi x10, x10, 1        # Marker 3 (x10 = 3)
    
    # JAL with rd = x0 should NOT crash or corrupt memory/registers
    jal  x9, pass

    # Trap: Should never reach here
    beq  x0, x0, fail

    # ------------------------------------------------------------------
    # End States
    # ------------------------------------------------------------------
pass:
    # All JAL tests passed! Set x10 = 255 (0xFF)
    addi x10, x0, 255
pass_loop:
    beq  x0, x0, pass_loop  # Infinite loop on success

fail:
    # Test failed! x10 holds failing step number
fail_loop:
    beq  x0, x0, fail_loop  # Infinite loop on failure