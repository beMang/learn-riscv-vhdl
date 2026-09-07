# Folders
SRC_DIR = components
TB_DIR  = tb
TMP_DIR = tmp
AUX_DIR = aux

# Variables
GHDL = ghdl
STD  = --std=08

TB ?= tb_top_level
DESIGN ?= $(SRC_DIR)/alu.vhd $(SRC_DIR)/control.vhd $(SRC_DIR)/memory.vhd $(SRC_DIR)/register.vhd $(SRC_DIR)/top_level.vhd
TB_FILE = $(TB_DIR)/$(TB).vhd

WAVE_FILE = $(TMP_DIR)/$(TB).ghw
WAVE_CFG  = $(AUX_DIR)/$(TB).gtkw

PROGRAM ?= test.s

.PHONY: all compile elaborate run view clean

all: view

compile:
	mkdir -p $(TMP_DIR)
	$(GHDL) -a $(STD) --workdir=$(TMP_DIR) $(DESIGN) $(TB_FILE)

	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o $(TMP_DIR)/test.o ./$(AUX_DIR)/$(PROGRAM)
	riscv64-unknown-elf-objcopy -O binary $(TMP_DIR)/test.o $(TMP_DIR)/test.bin
	hexdump -v -e '1/4 "%08x\n"' $(TMP_DIR)/test.bin > $(AUX_DIR)/program.hex

elaborate: compile
	$(GHDL) -e $(STD) --workdir=$(TMP_DIR) $(TB)

run: elaborate
	$(GHDL) -r $(STD) --workdir=$(TMP_DIR) $(TB) --wave=$(WAVE_FILE)

view: run
	@if [ -f "$(WAVE_CFG)" ]; then \
		gtkwave "$(WAVE_FILE)" "$(WAVE_CFG)"; \
	else \
		gtkwave "$(WAVE_FILE)"; \
	fi

clean:
	rm -rf $(TMP_DIR)