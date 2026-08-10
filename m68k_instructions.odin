package main

import "core:log"
import "core:fmt"

M68K_Instruction :: struct {
    // Instruction decoding will work by sequentially comparing masked opcode with predefined patterns 
    mask: u16,
    pattern: u16,
    mnemonic: string,
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
}

M68K_Instruction_Decoding_Cache: [0x10000]^M68K_Instruction

m68k_decode_instruction_uncached :: proc(opcode: u16) -> ^M68K_Instruction {
    for &entry in M68K_Instruction_Decoding_Table {
        if opcode & entry.mask == entry.pattern {
            return &entry
        }
    }

    return nil
}

m68k_init_instruction_decoding_cache :: proc() {
    for opcode in u16(0) ..= 0xFFFF {
        instr := m68k_decode_instruction_uncached(opcode)
        if instr == nil {
            panic(fmt.tprintf("unclassified opcode %04X", opcode))
        }

        M68K_Instruction_Decoding_Cache[opcode] = instr
    }
}

m68k_decode_instruction :: proc(opcode: u16) -> ^M68K_Instruction {
    return M68K_Instruction_Decoding_Cache[opcode]
}

m68k_not_implemented :: proc(m: ^M68K, opcode: u16) -> (cycles: u64) {
    log.warnf("opcode %04X is not implemented", opcode)
    return 0
}
