package main

import "core:fmt"

// Motorola 68000 CPU
M68K :: struct {
    // Registers
    D:   [8]u32, // Data registers
    A:   [8]u32, // Address registers (A7 is the USP - user stack pointer)
    SSP: u32,    // Supervisor Stack Pointer
    SR:  u16,    // Status register
    PC:  u32,    // Program counter
}

m68k_read_byte :: proc(m: ^M68K, address: u32) -> u8 {
    return 0
}

m68k_read_word :: proc(m: ^M68K, address: u32) -> u16 {
    return 0
}

m68k_read_long :: proc(m: ^M68K, address: u32) -> u32 {
    return 0
}
