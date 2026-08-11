package main

// Motorola 68000 CPU
M68K :: struct {
    // Registers
    D:   [8]u32, // Data registers
    A:   [8]u32, // Address registers (A7 is the USP - user stack pointer)
    SSP: u32,    // Supervisor Stack Pointer
    SR:  u16,    // Status register
    PC:  u32,    // Program counter
}

M68K_Data_Size :: enum u32 {
    Byte = 1, 
    Word = 2, 
    Long = 4,
}

m68k_read :: proc(m: ^M68K, address: u32, size: M68K_Data_Size) -> u32 {
    switch size {
    case .Byte:
    case .Word:
    case .Long:
    }

    return 0
}

m68k_write :: proc(m: ^M68K, address: u32, size: M68K_Data_Size, data: u32) {
    switch size {
    case .Byte:
    case .Word:
    case .Long:
    }
}
