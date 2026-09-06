from riscv_assembler.convert import AssemblyConverter

converter = AssemblyConverter(hex_mode=True)
hex = converter.convert("./aux/test.s") # Outputs program.hex

#Write machine code to file
with open("aux/program.hex", "w") as f:
    for l in hex:
        f.write(l + "\n")