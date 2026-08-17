package main

import "core:fmt"

// Cache entry is separated from the decoding table entry in order to carry less data
// and be more CPU cache friendly.
M68K_Instruction_Cache_Entry :: struct {
    // Info pre-calculated from the opcode
    size: M68K_Data_Size,
    addressing_mode: Addressing_Mode,
    reg: u16,
    execution_cycles: u64,

    handler: proc(m: ^M68K, i: ^M68K_Instruction_Cache_Entry, opcode: u16) -> (cycles: u64),
}

M68K_Instruction_Decoding_Table_Entry :: struct {
    // Instruction decoding will work by sequentially comparing masked opcode with predefined patterns 
    mask: u16,
    pattern: u16,
    mnemonic: string,

    allowed_addressing_modes: bit_set[Addressing_Mode],
    execution_timing: #sparse [M68K_Data_Size][Addressing_Mode]u64,

    // Since instructions can have variable length depending on operands size, they are also responsible
    // for advancing the PC.
    handler: proc(m: ^M68K, i: ^M68K_Instruction_Cache_Entry, opcode: u16) -> (cycles: u64),
}

@(rodata)
M68K_Instruction_Decoding_Table := [?]M68K_Instruction_Decoding_Table_Entry{
    // Instructions without variable parts
    { mask = 0b11111111_11111111, pattern = 0b00000000_00111100, mnemonic = "ORI to CCR",   handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00000000_01111100, mnemonic = "ORI to SR",    handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00000010_00111100, mnemonic = "ANDI to CCR",  handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00000010_01111100, mnemonic = "ANDI to SR",   handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00001010_00111100, mnemonic = "EORI to CCR",  handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b00001010_01111100, mnemonic = "EORI to SR",   handler = m68k_not_implemented },
    { mask = 0b11111111_11111111, pattern = 0b01001010_11111100, mnemonic = "ILLEGAL",      handler = m68k_illegal },
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
    { mask = 0b11111111_00000000, pattern = 0b00001010_00000000, mnemonic = "EORI",         allowed_addressing_modes = Data_Alterable_Addressing_Modes, execution_timing = Execution_Timing_EORI_ORI_ANDI_SUBI_ADDI, handler = m68k_eori },
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
}

// Returns a size-efficient cache entry and a decoding table entry that was triggered by the provided opcode
m68k_decode_instruction_uncached :: proc(opcode: u16) -> (M68K_Instruction_Cache_Entry, ^M68K_Instruction_Decoding_Table_Entry) {
    illegal_instruction :: M68K_Instruction_Cache_Entry{ handler = m68k_illegal }

    for &entry in M68K_Instruction_Decoding_Table {
        if opcode & entry.mask != entry.pattern {
            continue
        }

        size := m68k_decode_size(opcode)
        addressing_mode, reg := m68k_decode_addressing_mode(opcode)

        if card(entry.allowed_addressing_modes) == 0 || addressing_mode in entry.allowed_addressing_modes {
            cache_entry := M68K_Instruction_Cache_Entry{
                size = size,
                addressing_mode = addressing_mode,
                reg = reg,
                execution_cycles = entry.execution_timing[size][addressing_mode],
                handler = entry.handler,
            }

            return cache_entry, &entry
        }

        return illegal_instruction, &entry
    }

    return illegal_instruction, nil
}

M68K_Instruction_Decoding_Cache: [0x10000]M68K_Instruction_Cache_Entry

m68k_init_instruction_decoding_cache :: proc() {
    for opcode in u16(0) ..= 0xFFFF {
        M68K_Instruction_Decoding_Cache[opcode], _ = m68k_decode_instruction_uncached(opcode)
    }
}

m68k_decode_instruction :: proc(opcode: u16) -> ^M68K_Instruction_Cache_Entry {
    return &M68K_Instruction_Decoding_Cache[opcode]
}

m68k_not_implemented :: proc(m: ^M68K, i: ^M68K_Instruction_Cache_Entry, opcode: u16) -> u64 {
    panic(fmt.tprintf("opcode %04X is not implemented", opcode))
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

Addressing_Mode :: enum {
    Data_Register,
    Address_Register,
    Address,
    Address_With_Postincrement,
    Address_With_Predecrement,
    Address_With_Displacement,
    Address_With_Index,
    PC_With_Displacement,
    PC_With_Index,
    Absolute_Short,
    Absolute_Long,
    Immediate,
    Invalid,
}

Data_Alterable_Addressing_Modes : bit_set[Addressing_Mode] : { 
    .Data_Register, 
    .Address, 
    .Address_With_Postincrement, 
    .Address_With_Predecrement, 
    .Address_With_Displacement, 
    .Address_With_Index, 
    .Absolute_Short, 
    .Absolute_Long, 
}

m68k_decode_addressing_mode :: proc(opcode: u16) -> (am: Addressing_Mode, reg: u16) {
    am = .Invalid
    reg = opcode & 0b111

    // All opcodes decode addressing mode this way. The complication is that not all instructions
    // support all addressing modes, so we need to somehow filter them out per-instruction.
    switch opcode & 0b00111000 {
    case 0b00000000:
        am = .Data_Register
    case 0b00001000:
        am = .Address_Register
    case 0b00010000:
        am = .Address
    case 0b00011000:
        am = .Address_With_Postincrement
    case 0b00100000:
        am = .Address_With_Predecrement
    case 0b00101000:
        am = .Address_With_Displacement
    case 0b00110000:
        am = .Address_With_Index
    case 0b00111000:
        switch reg {
        case 0b000:
            am = .Absolute_Short
        case 0b001:
            am = .Absolute_Long
        case 0b010:
            am = .PC_With_Displacement
        case 0b011:
            am = .PC_With_Index
        case 0b100:
            am = .Immediate
        }
    }

    return
}

Immediate :: distinct u32

Effective_Address :: union {
    ^u32, // For registers
    u32,  // For bus addresses
    Immediate,
}

@(rodata)
Data_Mask := #sparse [M68K_Data_Size]u32 {
    .Byte = 0xFF,
    .Word = 0xFFFF,
    .Long = 0xFFFFFFFF,
}

ea_read :: proc(m: ^M68K, ea: Effective_Address, size: M68K_Data_Size) -> u32 {
    switch e in ea {
    case ^u32:
        return e^ & Data_Mask[size]
    case u32:
        return m68k_read(m, e, size)
    case Immediate:
        return u32(e)
    case:
        return 0
    }
}

ea_write :: proc(m: ^M68K, ea: Effective_Address, size: M68K_Data_Size, value: u32) {
    switch e in ea {
    case ^u32:
        mask := Data_Mask[size]
        e^ = (e^ & ~mask) | (value & mask)
    case u32:
        m68k_write(m, e, size, value)
    case Immediate:
        // Writing to immediate value?
    }
}

// Resolves instruction effective address, fetches necessary amount of extension words according to 
// addressing mode, and advances PC. 
m68k_resolve_effective_address :: proc(m: ^M68K, size: M68K_Data_Size, addressing_mode: Addressing_Mode, reg: u16) -> Effective_Address {
    address_with_displacement :: proc(m: ^M68K, base: u32) -> u32 {
        // Displacement is always a 16-bit signed integer
        displacement := i16(m68k_fetch(m, .Word))

        // Sign-extend to i32 and then cast to u32 (two's complement arithmetic just works this way)
        return base + u32(i32(displacement))
    }

    address_with_index :: proc(m: ^M68K, base: u32) -> u32 {
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

        return ea
    }

    #partial switch addressing_mode {
    case .Data_Register:
        return &m.D[reg]
    case .Address_Register:
        return &m.A[reg]
    case .Address:
        return m.A[reg]
    case .Address_With_Postincrement:
        ea := m.A[reg]

        if reg == 7 && size == .Byte { // A7 (aka stack pointer) is always kept to a word boundary
            m.A[reg] += 2
        } else {
            m.A[reg] += u32(size)
        }

        return ea
    case .Address_With_Predecrement:
        if reg == 7 && size == .Byte {
            m.A[reg] -= 2
        } else {
            m.A[reg] -= u32(size)
        }

        return m.A[reg]
    case .Address_With_Displacement:
        return address_with_displacement(m, m.A[reg])
    case .Address_With_Index:
        return address_with_index(m, m.A[reg])
    case .Absolute_Short:
        return u32(i32(i16(m68k_fetch(m, .Word))))
    case .Absolute_Long:
        return m68k_fetch(m, .Long)
    case .PC_With_Displacement:
        return address_with_displacement(m, m.PC)
    case .PC_With_Index:
        return address_with_index(m, m.PC)
    case .Immediate:
        return Immediate(m68k_fetch(m, size))
    case:
        panic("effective address resolution for invalid addressing mode")
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
        // Either an invalid instruction, or custom/implied size encoding, so return whatever
        // TODO: return error instead?
        return .Byte
    }
}

Execution_Timing_EORI_ORI_ANDI_SUBI_ADDI :: #sparse [M68K_Data_Size][Addressing_Mode]u64{
    .Byte = #partial {
        .Data_Register = 8,
        .Address = 16,
        .Address_With_Postincrement = 16,
        .Address_With_Predecrement = 18,
        .Address_With_Displacement = 20,
        .Address_With_Index = 22,
        .Absolute_Short = 20,
        .Absolute_Long = 24,
    },
    .Word = #partial {
        .Data_Register = 8,
        .Address = 16,
        .Address_With_Postincrement = 16,
        .Address_With_Predecrement = 18,
        .Address_With_Displacement = 20,
        .Address_With_Index = 22,
        .Absolute_Short = 20,
        .Absolute_Long = 24,
    },
    .Long = #partial {
        .Data_Register = 16,
        .Address = 28,
        .Address_With_Postincrement = 28,
        .Address_With_Predecrement = 30,
        .Address_With_Displacement = 32,
        .Address_With_Index = 34,
        .Absolute_Short = 32,
        .Absolute_Long = 36,
    },
}

m68k_illegal :: proc(m: ^M68K, i: ^M68K_Instruction_Cache_Entry, opcode: u16) -> u64 {
    return 34
}

m68k_eori :: proc(m: ^M68K, i: ^M68K_Instruction_Cache_Entry, opcode: u16) -> u64 {
    data_imm := m68k_fetch(m, i.size)
    ea := m68k_resolve_effective_address(m, i.size, i.addressing_mode, i.reg)

    data_ea := ea_read(m, ea, i.size)
    ea_write(m, ea, i.size, data_imm ~ data_ea)

    return i.execution_cycles
}
