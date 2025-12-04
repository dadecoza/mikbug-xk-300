# -------- Configuration --------
ASM      := ../motorola-6800-assembler/bin/as0
ASMFLAGS := -l cre c s
SREC_CAT := srec_cat
PYTHON   := python3

TARGET   := mikbug
ASM_SRC  := mikbug.asm
S19      := $(TARGET).s19
BIN      := mikbug.bin
WAV      := $(TARGET).wav

# -------- Default Target --------
# By default, build only the assembled binary.
all: $(BIN)

# -------- Build Rules --------

$(S19): $(ASM_SRC)
	$(ASM) $(ASM_SRC) $(ASMFLAGS)

$(BIN): $(S19)
	$(SREC_CAT) $(S19) -offset -0xE800 -o $(BIN) -binary

# Optional WAV output
$(WAV): $(BIN)
	$(PYTHON) tools/bin2kcs300.py $(BIN) $(WAV)

# Convenience targets
bin: $(BIN)
wav: $(WAV)

clean:
	rm -f $(S19) $(BIN) $(WAV) *.lst *.sym *.err

.PHONY: all bin wav clean
