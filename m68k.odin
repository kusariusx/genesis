package main

import "base:runtime"

// Motorola 68000 CPU
M68K :: struct {
    // Registers
    D:   [8]u32, // Data registers
    A:   [8]u32, // Address registers (A7 is the USP - user stack pointer)
    SSP: u32,    // Supervisor Stack Pointer
    PC:  u32,    // Program counter

    SR: bit_field u16 { // Status register
        C: u8 | 1, // Carry
        V: u8 | 1, // Overflow
        Z: u8 | 1, // Zero
        N: u8 | 1, // Negative
        X: u8 | 1, // Extend
        _: u8 | 3, // Padding
        I: u8 | 3, // Interrupt Mask
        _: u8 | 2, // Padding
        S: u8 | 1, // Supervisor State
        _: u8 | 1, // Padding
        T: u8 | 1, // Trace Mode
    },
}

M68K_Data_Size :: enum u32 {
    Byte = 1,
    Word = 2,
    Long = 4,
}

M68K_Immediate :: distinct u32

M68K_Effective_Address :: union #no_nil {
    ^u32, // For registers
    u32,  // For bus addresses
    M68K_Immediate,
}

@(rodata)
Data_Mask := #sparse [M68K_Data_Size]u32 {
    .Byte = 0xFF,
    .Word = 0xFFFF,
    .Long = 0xFFFFFFFF,
}

ea_read :: proc(m: ^M68K, ea: M68K_Effective_Address, size: M68K_Data_Size) -> u32 {
    switch e in ea {
    case ^u32:
        return e^ & Data_Mask[size]
    case u32:
        return m68k_read(m, e, size)
    case M68K_Immediate:
        return u32(e)
    }

    return 0
}

ea_write :: proc(m: ^M68K, ea: M68K_Effective_Address, size: M68K_Data_Size, value: u32) {
    switch e in ea {
    case ^u32:
        mask := Data_Mask[size]
        e^ = (e^ & ~mask) | (value & mask)
    case u32:
        m68k_write(m, e, size, value)
    case M68K_Immediate:
        // Writing to immediate value?
    }
}

when ODIN_TEST {
    Testing_Bus: map[u32]u8

    @(init)
    init_testing_bus :: proc "contextless" () {
        context = runtime.default_context()
        Testing_Bus = make(map[u32]u8)
    }

    @(fini)
    fini_testing_bus :: proc "contextless" () {
        context = runtime.default_context()
        delete(Testing_Bus)
    }

    m68k_read :: proc(m: ^M68K, address: u32, size: M68K_Data_Size) -> (result: u32) {
        switch size {
        case .Byte:
            return u32(Testing_Bus[address])
        case .Word:
            return (u32(Testing_Bus[address]) << 8) | u32(Testing_Bus[address + 1])
        case .Long:
            return (u32(Testing_Bus[address]) << 24) |
                (u32(Testing_Bus[address + 1]) << 16) |
                (u32(Testing_Bus[address + 2]) << 8) |
                u32(Testing_Bus[address + 3])
        }

        return 0
    }

    m68k_write :: proc(m: ^M68K, address: u32, size: M68K_Data_Size, data: u32) {
        switch size {
        case .Byte:
            Testing_Bus[address] = u8(data)
        case .Word:
            Testing_Bus[address] = u8(data >> 8)
            Testing_Bus[address + 1] = u8(data)
        case .Long:
            Testing_Bus[address] = u8(data >> 24)
            Testing_Bus[address + 1] = u8(data >> 16)
            Testing_Bus[address + 2] = u8(data >> 8)
            Testing_Bus[address + 3] = u8(data)
        }
    }
} else {
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
}

// Fetches data from PC and advances it.
m68k_fetch :: proc(m: ^M68K, size: M68K_Data_Size) -> u32 {
    if size == .Byte { // PC is always aligned to a word
        data := m68k_read(m, m.PC, .Word)
        m.PC += 2
        return data & 0xFF
    }

    data := m68k_read(m, m.PC, size)
    m.PC += u32(size)
    return data
}
