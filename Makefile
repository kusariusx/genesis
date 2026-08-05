.PHONY: test

BUILD_DIR := bin
TARGET := $(BUILD_DIR)/genesis
BUILD_FLAGS := -microarch:native -no-bounds-check -no-type-assert -disable-assert

test:
	odin test . -all-packages -o:speed

run:
	./$(TARGET)

build: ensure-bin-exists
	odin build . $(BUILD_FLAGS) -out:$(TARGET) -o:speed

build-debug: ensure-bin-exists
	odin build . $(BUILD_FLAGS) -out:$(TARGET) -o:none -debug

build-asm: ensure-bin-exists
	odin build . $(BUILD_FLAGS) -out:$(TARGET).S -o:speed -build-mode:asm

ensure-bin-exists:
	mkdir -p bin

clean:
	rm -rf bin/
