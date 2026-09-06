# Folders
SRC_DIR = components
TB_DIR  = tb
TMP_DIR = tmp

# Variables
GHDL = ghdl
STD  = --std=08

TB ?= tb_top_level
DESIGN ?= $(SRC_DIR)/alu.vhd $(SRC_DIR)/control.vhd $(SRC_DIR)/memory.vhd $(SRC_DIR)/register.vhd $(SRC_DIR)/top_level.vhd
TB_FILE = $(TB_DIR)/$(TB).vhd

WAVE_FILE = $(TMP_DIR)/$(TB).ghw
WAVE_CFG  = $(TMP_DIR)/$(TB).gtkw

.PHONY: all compile elaborate run view clean

all: view

compile:
	mkdir -p $(TMP_DIR)
	$(GHDL) -a $(STD) --workdir=$(TMP_DIR) $(DESIGN) $(TB_FILE)

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