package main

import "core:fmt"

M68K_Instruction :: struct {
    // Instruction decoding will work by sequentially comparing masked opcode with predefined patterns 
    mask: u16,
    pattern: u16,
    mnemonic: string,

    // Since instructions can have variable length depending on operands size, they are also responsible
    // for advancing the PC.
    handler: proc(m: ^M68K, opcode: u16) -> (cycles: u64),
}

@(rodata)
M68K_Instruction_Decoding_Table := [?]M68K_Instruction{
    // Instructions without variable parts
    { mask = 0b11111111_11111111, pattern = 0b00000000_00111100, mnemonic = "ORI to CCR",   handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00000000_01111100, mnemonic = "ORI to SR",    handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00000010_00111100, mnemonic = "ANDI to CCR",  handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00000010_01111100, mnemonic = "ANDI to SR",   handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00001010_00111100, mnemonic = "EORI to CCR",  handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00001010_01111100, mnemonic = "EORI to SR",   handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001010_11111100, mnemonic = "ILLEGAL",      handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001110_01110000, mnemonic = "RESET",        handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001110_01110001, mnemonic = "NOP",          handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001110_01110010, mnemonic = "STOP",         handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001110_01110011, mnemonic = "RTE",          handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001110_01110101, mnemonic = "RTS",          handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001110_01110110, mnemonic = "TRAPV",        handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001110_01110111, mnemonic = "RTR",          handler = m68k_not_implemented },

    // Other instructions
    { mask = 0b11111111_00000000, pattern = 0b00000000_00000000, mnemonic = "ORI",          handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b00000010_00000000, mnemonic = "ANDI",         handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b00000100_00000000, mnemonic = "SUBI",         handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b00000110_00000000, mnemonic = "ADDI",         handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b00001010_00000000, mnemonic = "EORI",         handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b00001100_00000000, mnemonic = "CMPI",         handler = m68k_not_implemented },
    { mask = 0b11110001_00111000, pattern = 0b00000001_00001000, mnemonic = "MOVEP",        handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b00001000_00000000, mnemonic = "BTST",         handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b00001000_01000000, mnemonic = "BCHG",         handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b00001000_10000000, mnemonic = "BCLR",         handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b00001000_11000000, mnemonic = "BSET",         handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b00000001_00000000, mnemonic = "BTST",         handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b00000001_01000000, mnemonic = "BCHG",         handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b00000001_10000000, mnemonic = "BCLR",         handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b00000001_11000000, mnemonic = "BSET",         handler = m68k_not_implemented },
    { mask = 0b11000001_11000000, pattern = 0b00000000_01000000, mnemonic = "MOVEA",        handler = m68k_not_implemented },
    { mask = 0b11000000_00000000, pattern = 0b00000000_00000000, mnemonic = "MOVE",         handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b01000000_11000000, mnemonic = "MOVE from SR", handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b01000100_11000000, mnemonic = "MOVE to CCR",  handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b01000110_11000000, mnemonic = "MOVE to SR",   handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b01000000_00000000, mnemonic = "NEGX",         handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b01000010_00000000, mnemonic = "CLR",          handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b01000100_00000000, mnemonic = "NEG",          handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b01000110_00000000, mnemonic = "NOT",          handler = m68k_not_implemented },
    { mask = 0b11111111_10111000, pattern = 0b01001000_10000000, mnemonic = "EXT",          handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b01001000_00000000, mnemonic = "NBCD",         handler = m68k_not_implemented },
    { mask = 0b11111111_11111000, pattern = 0b01001000_01000000, mnemonic = "SWAP",         handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b01001000_01000000, mnemonic = "PEA",          handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b01001010_11000000, mnemonic = "TAS",          handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b01001010_00000000, mnemonic = "TST",          handler = m68k_not_implemented },
    { mask = 0b11111111_11110000, pattern = 0b01001110_01000000, mnemonic = "TRAP",         handler = m68k_not_implemented },
    { mask = 0b11111111_11111000, pattern = 0b01001110_01010000, mnemonic = "LINK",         handler = m68k_not_implemented },
    { mask = 0b11111111_11111000, pattern = 0b01001110_01011000, mnemonic = "UNLK",         handler = m68k_not_implemented },
    { mask = 0b11111111_11110000, pattern = 0b01001110_01100000, mnemonic = "MOVE USP",     handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b01001110_10000000, mnemonic = "JSR",          handler = m68k_not_implemented },
    { mask = 0b11111111_11000000, pattern = 0b01001110_11000000, mnemonic = "JMP",          handler = m68k_not_implemented },
    { mask = 0b11111011_10000000, pattern = 0b01001000_10000000, mnemonic = "MOVEM",        handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b01000001_11000000, mnemonic = "LEA",          handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b01000001_10000000, mnemonic = "CHK",          handler = m68k_not_implemented },
    { mask = 0b11110000_11111000, pattern = 0b01010000_11001000, mnemonic = "DBcc",         handler = m68k_not_implemented },
    { mask = 0b11110000_11000000, pattern = 0b01010000_11000000, mnemonic = "Scc",          handler = m68k_not_implemented },
    { mask = 0b11110001_00000000, pattern = 0b01010000_00000000, mnemonic = "ADDQ",         handler = m68k_not_implemented },
    { mask = 0b11110001_00000000, pattern = 0b01010001_00000000, mnemonic = "SUBQ",         handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b01100000_00000000, mnemonic = "BRA",          handler = m68k_not_implemented },
    { mask = 0b11111111_00000000, pattern = 0b01100001_00000000, mnemonic = "BSR",          handler = m68k_not_implemented },
    { mask = 0b11110000_00000000, pattern = 0b01100000_00000000, mnemonic = "Bcc",          handler = m68k_not_implemented },
    { mask = 0b11110001_00000000, pattern = 0b01110000_00000000, mnemonic = "MOVEQ",        handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b10000000_11000000, mnemonic = "DIVU",         handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b10000001_11000000, mnemonic = "DIVS",         handler = m68k_not_implemented },
    { mask = 0b11110001_11110000, pattern = 0b10000001_00000000, mnemonic = "SBCD",         handler = m68k_not_implemented },
    { mask = 0b11110000_00000000, pattern = 0b10000000_00000000, mnemonic = "OR",           handler = m68k_not_implemented },
    { mask = 0b11110000_11000000, pattern = 0b10010000_11000000, mnemonic = "SUBA",         handler = m68k_not_implemented },
    { mask = 0b11110001_00110000, pattern = 0b10010001_00000000, mnemonic = "SUBX",         handler = m68k_not_implemented },
    { mask = 0b11110000_00000000, pattern = 0b10010000_00000000, mnemonic = "SUB",          handler = m68k_not_implemented },
    { mask = 0b11110000_11000000, pattern = 0b10110000_11000000, mnemonic = "CMPA",         handler = m68k_not_implemented },
    { mask = 0b11110001_00111000, pattern = 0b10110001_00001000, mnemonic = "CMPM",         handler = m68k_not_implemented },
    { mask = 0b11110001_00000000, pattern = 0b10110000_00000000, mnemonic = "CMP",          handler = m68k_not_implemented },
    { mask = 0b11110001_00000000, pattern = 0b10110001_00000000, mnemonic = "EOR",          handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b11000000_11000000, mnemonic = "MULU",         handler = m68k_not_implemented },
    { mask = 0b11110001_11000000, pattern = 0b11000001_11000000, mnemonic = "MULS",         handler = m68k_not_implemented },
    { mask = 0b11110001_11110000, pattern = 0b11000001_00000000, mnemonic = "ABCD",         handler = m68k_not_implemented },
    { mask = 0b11110001_00110000, pattern = 0b11000001_00000000, mnemonic = "EXG",          handler = m68k_not_implemented },
    { mask = 0b11110000_00000000, pattern = 0b11000000_00000000, mnemonic = "AND",          handler = m68k_not_implemented },
    { mask = 0b11110000_11000000, pattern = 0b11010000_11000000, mnemonic = "ADDA",         handler = m68k_not_implemented },
    { mask = 0b11110001_00110000, pattern = 0b11010001_00000000, mnemonic = "ADDX",         handler = m68k_not_implemented },
    { mask = 0b11110000_00000000, pattern = 0b11010000_00000000, mnemonic = "ADD",          handler = m68k_not_implemented },
    { mask = 0b11111110_11000000, pattern = 0b11100000_11000000, mnemonic = "ASd",          handler = m68k_not_implemented },
    { mask = 0b11111110_11000000, pattern = 0b11100010_11000000, mnemonic = "LSd",          handler = m68k_not_implemented },
    { mask = 0b11111110_11000000, pattern = 0b11100100_11000000, mnemonic = "ROXd",         handler = m68k_not_implemented },
    { mask = 0b11111110_11000000, pattern = 0b11100110_11000000, mnemonic = "ROd",          handler = m68k_not_implemented },
    { mask = 0b11110000_00011000, pattern = 0b11100000_00000000, mnemonic = "ASd",          handler = m68k_not_implemented },
    { mask = 0b11110000_00011000, pattern = 0b11100000_00001000, mnemonic = "LSd",          handler = m68k_not_implemented },
    { mask = 0b11110000_00011000, pattern = 0b11100000_00010000, mnemonic = "ROXd",         handler = m68k_not_implemented },
    { mask = 0b11110000_00011000, pattern = 0b11100000_00011000, mnemonic = "ROd",          handler = m68k_not_implemented },

    // Catch-all case for all unclassified opcodes
    { mask = 0b00000000_00000000, pattern = 0b00000000_00000000, mnemonic = "ILLEGAL",      handler = m68k_not_implemented },
}

M68K_Instruction_Decoding_Cache: [0x10000]^M68K_Instruction

m68k_decode_instruction_uncached :: proc(opcode: u16) -> ^M68K_Instruction {
    for &entry in M68K_Instruction_Decoding_Table {
        if opcode & entry.mask == entry.pattern {
            return &entry
        }
    }

    panic(fmt.tprintf("unclassified opcode %04X\n", opcode))
}

m68k_init_instruction_decoding_cache :: proc() {
    for opcode in u16(0) ..= 0xFFFF {
        M68K_Instruction_Decoding_Cache[opcode] = m68k_decode_instruction_uncached(opcode)
    }
}

m68k_decode_instruction :: proc(opcode: u16) -> ^M68K_Instruction {
    return M68K_Instruction_Decoding_Cache[opcode]
}

m68k_not_implemented :: proc(m: ^M68K, opcode: u16) -> u64 {
    panic(fmt.tprintf("opcode %04X is not implemented", opcode))
}

// Fetches data from PC and advances it.
m68k_fetch :: proc(m: ^M68K, size: M68K_Data_Size) -> u32 {
    data := m68k_read(m, m.PC, size)
    m.PC += u32(size)
    return data
}

Immediate :: distinct u32

Effective_Address :: union {
    ^u32, // For registers
    u32,  // For bus addresses
    Immediate,
}

// Resolves instruction effective address, fetches necessary amount of extension words according to 
// addressing mode, and advances PC. 
m68k_resolve_effective_address :: proc(m: ^M68K, opcode: u16, size: M68K_Data_Size) -> (Effective_Address, u64) {
    address_with_displacement :: proc(m: ^M68K, base: u32, size: M68K_Data_Size) -> (Effective_Address, u64) {
        // Displacement is always a 16-bit signed integer
        displacement := i16(m68k_fetch(m, .Word))

        // Sign-extend to i32 and then cast to u32 (two's complement arithmetic just works this way)
        return base + u32(i32(displacement)), size == .Long ? 12 : 8
    }

    address_with_index :: proc(m: ^M68K, base: u32, size: M68K_Data_Size) -> (Effective_Address, u64) {
        ea := base
        ext := m68k_fetch(m, .Word)

        index_reg_number := (ext >> 12) & 0b111
        index := ext >> 15 == 0 ? m.D[index_reg_number] : m.A[index_reg_number]

        if ext & 0b00001000_00000000 == 0 { // Use word for index instead of long
            ea += u32(i32(i16(index))) // Trim high bytes, interpret as i16, sign-extend to i32, and add to EA as u32
        } else {
            ea += index
        }

        displacement := i8(ext)
        ea += u32(i32(displacement))

        return ea, size == .Long ? 14 : 10
    }

    reg := opcode & 0b111
    
    // All opcodes decode addressing mode this way. The complication is that not all instructions
    // support all addressing modes, so we need to somehow filter them out per-instruction.
    switch opcode & 0b00111000 {
    case 0b00000000: // Data register
        return &m.D[reg], 0
    case 0b00001000: // Address register
        return &m.A[reg], 0
    case 0b00010000: // Address
        return m.A[reg], size == .Long ? 8 : 4
    case 0b00011000: // Address with post-increment
        ea := m.A[reg]

        if reg == 7 && size == .Byte { // A7 (aka stack pointer) is always kept to a word boundary
            m.A[reg] += 2
        } else {
            m.A[reg] += u32(size)
        }

        return ea, size == .Long ? 8 : 4
    case 0b00100000: // Address with pre-decrement
        if reg == 7 && size == .Byte {
            m.A[reg] -= 2
        } else {
            m.A[reg] -= u32(size)
        }

        return m.A[reg], size == .Long ? 10 : 6
    case 0b00101000:
        return address_with_displacement(m, m.A[reg], size)
    case 0b00110000:
        return address_with_index(m, m.A[reg], size)
    case 0b00111000:
        switch reg {
        case 0b000: // Absolute short
            // Address must be sign-extended to 32 bits
            return u32(i32(i16(m68k_fetch(m, .Word)))), size == .Long ? 12 : 8
        case 0b001: // Absolute long
            return m68k_fetch(m, .Long), size == .Long ? 16 : 12
        case 0b010:
            return address_with_displacement(m, m.PC, size)
        case 0b011:
            return address_with_index(m, m.PC, size)
        case 0b100: // Immediate
            cycles: u64 = size == .Long ? 8 : 4

            if size == .Byte {
                return Immediate(m68k_fetch(m, .Word) & 0xFF), cycles
            } else {
                return Immediate(m68k_fetch(m, size)), cycles
            }
        case:
            panic("unexpected register during effective address calculation")
        }
    case:
        panic("unexpected mode during effective address calculation")
    }
}

m68k_decode_size :: proc(opcode: u16) -> M68K_Data_Size {
    // Most of the opcodes encode data size this way, but there are exceptions - 
    // they will be handled by instructions individually.
    switch opcode & 0b11000000 {
    case 0b00000000:
        return .Byte
    case 0b01000000:
        return .Word
    case 0b10000000:
        return .Long
    case:
        panic("unexpected data size")
    }
}

/*
calculate ea -> rawptr
regardless of size:
    read_ea(size), read_pc(size), write_ea(size, data_pc ~ data_ea)
*/

m68k_eori :: proc(m: ^M68K, opcode: u16) -> u64 {
    size := m68k_decode_size(opcode)
    data_imm := m68k_fetch(m, size)
    return 0
}
