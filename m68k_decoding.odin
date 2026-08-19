package main

import "core:fmt"

M68K_Addressing_Mode :: enum u8 {
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
}

// Cache entry is separated from the decoding table entry in order to carry less data
// and be more CPU cache friendly.
// Fields are reordered from largest to smallest to minimize the size of each entry.
M68K_Instruction_Cache_Entry :: struct {
    handler: proc(m: ^M68K, i: ^M68K_Instruction_Cache_Entry, opcode: u16) -> (cycles: u8),

    // Info pre-calculated from the opcode
    size: M68K_Data_Size,
    reg: u16,
    addressing_mode: M68K_Addressing_Mode,
    execution_cycles: u8,
}

M68K_Instruction_Decoding_Table_Entry :: struct {
    // Instruction decoding will work by sequentially comparing masked opcode with predefined patterns 
    mask: u16,
    pattern: u16,
    mnemonic: string,

    parse_size: bool,
    parse_addressing_mode: bool,

    allowed_addressing_modes: bit_set[M68K_Addressing_Mode],
    execution_timing: #sparse [M68K_Data_Size][M68K_Addressing_Mode]u8,

    // Since instructions can have variable length depending on operands size, they are also responsible
    // for advancing the PC.
    handler: proc(m: ^M68K, i: ^M68K_Instruction_Cache_Entry, opcode: u16) -> (cycles: u8),
}

@(private="file")
M68K_Instruction_Decoding_Cache: [0x10000]M68K_Instruction_Cache_Entry

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
    { mask = 0b11111111_00000000, pattern = 0b00001010_00000000, mnemonic = "EORI",         parse_size = true, parse_addressing_mode = true, allowed_addressing_modes = Data_Alterable_Addressing_Modes, execution_timing = Execution_Timing_EORI_ORI_ANDI_SUBI_ADDI, handler = m68k_eori },
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

Data_Alterable_Addressing_Modes : bit_set[M68K_Addressing_Mode] : { 
    .Data_Register, 
    .Address, 
    .Address_With_Postincrement, 
    .Address_With_Predecrement, 
    .Address_With_Displacement, 
    .Address_With_Index, 
    .Absolute_Short, 
    .Absolute_Long, 
}

Execution_Timing_EORI_ORI_ANDI_SUBI_ADDI :: #sparse [M68K_Data_Size][M68K_Addressing_Mode]u8{
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

// Returns a size-efficient cache entry and a decoding table entry that was triggered by the provided opcode
m68k_decode_instruction_uncached :: proc(opcode: u16) -> (M68K_Instruction_Cache_Entry, ^M68K_Instruction_Decoding_Table_Entry) {
    illegal_instruction :: M68K_Instruction_Cache_Entry{ handler = m68k_illegal }

    for &entry in M68K_Instruction_Decoding_Table {
        if opcode & entry.mask != entry.pattern {
            continue
        }

        cache_entry := M68K_Instruction_Cache_Entry{ handler = entry.handler }

        ok: bool

        if entry.parse_size {
            cache_entry.size, ok = m68k_decode_size(opcode)
            if !ok {
                return illegal_instruction, &entry
            }
        }

        if entry.parse_addressing_mode {
            cache_entry.addressing_mode, cache_entry.reg, ok = m68k_decode_addressing_mode(opcode)
            if !ok {
                return illegal_instruction, &entry
            }
        }

        if entry.parse_size && entry.parse_addressing_mode {
            cache_entry.execution_cycles = entry.execution_timing[cache_entry.size][cache_entry.addressing_mode]
        }

        if card(entry.allowed_addressing_modes) == 0 || cache_entry.addressing_mode in entry.allowed_addressing_modes {
            return cache_entry, &entry
        }

        return illegal_instruction, &entry
    }

    return illegal_instruction, nil
}

m68k_init_instruction_decoding_cache :: proc() {
    for opcode in u16(0) ..= 0xFFFF {
        M68K_Instruction_Decoding_Cache[opcode], _ = m68k_decode_instruction_uncached(opcode)
    }
}

m68k_decode_instruction :: proc(opcode: u16) -> ^M68K_Instruction_Cache_Entry {
    return &M68K_Instruction_Decoding_Cache[opcode]
}

m68k_decode_addressing_mode :: proc(opcode: u16) -> (am: M68K_Addressing_Mode, reg: u16, ok: bool = true) {
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
        case:
            ok = false
        }
    case:
        ok = false
    }

    return
}

m68k_decode_size :: proc(opcode: u16) -> (size: M68K_Data_Size, ok: bool) {
    // Most of the opcodes encode data size this way, but there are exceptions - 
    // they will be handled by instructions individually.
    switch opcode & 0b11000000 {
    case 0b00000000:
        return .Byte, true
    case 0b01000000:
        return .Word, true
    case 0b10000000:
        return .Long, true
    case:
        return {}, false
    }
}

m68k_not_implemented :: proc(m: ^M68K, i: ^M68K_Instruction_Cache_Entry, opcode: u16) -> u8 {
    panic(fmt.tprintf("opcode %04X is not implemented", opcode))
}
