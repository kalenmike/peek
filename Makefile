# Variables
AS = nasm
ASFLAGS = -f elf64
LD = ld
LDFLAGS = -n -N --strip-all
STRIP = strip
TARGET = pk

# Debug
ASFLAGS_DEBUG = -f elf64 -g -F dwarf
LDFLAGS_DEBUG = -g

# Directories
SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin
PREFIX = /usr/local
INSTALL_DIR = $(PREFIX)/bin

# Files
SRCS = $(wildcard $(SRC_DIR)/*.asm)
OBJS = $(patsubst $(SRC_DIR)/%.asm, $(BUILD_DIR)/%.o, $(SRCS))
BIN = $(BIN_DIR)/$(TARGET)

.PHONY: all clean

all: $(BIN)

# Debug build target
debug: ASFLAGS = $(ASFLAGS_DEBUG)
debug: $(BIN)_debug

# Link and strip
$(BIN): $(OBJS)
	@mkdir -p $(BIN_DIR)
	$(LD) $(LDFLAGS) -o $(BIN) $(OBJS)
	$(STRIP) --strip-all $(BIN)
	@echo "Binary created in: $(BIN_DIR)"

# Assemble
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm
	@mkdir -p $(BUILD_DIR)
	$(AS) $(ASFLAGS) $< -o $@
	@echo "Assembled: $<"

$(BIN)_debug: $(OBJS)
	@mkdir -p $(BIN_DIR)
	$(LD) $(LDFLAGS_DEBUG) -o $@ $(OBJS)
	@echo "Debug binary created: $@ (Symbols included)"

install: $(BIN)
	@echo "Installing $(BIN) to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@install -m 755 $(BIN) $(INSTALL_DIR)/$(BIN)
	@echo "Done! You can now run '$(BIN)' from anywhere."

uninstall:
	@echo "Removing $(BIN) from $(INSTALL_DIR)..."
	@rm -f $(INSTALL_DIR)/$(BIN)
	@echo "Uninstall complete."

# Clean up
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
	@echo "Cleaned up build artifacts."


