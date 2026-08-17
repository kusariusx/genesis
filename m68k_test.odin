package main

import "core:testing"

@(test)
test_m86k_instruction_decoding :: proc(t: ^testing.T) {
    all_instructions := []string{
        "ORI to CCR", "ORI to SR", "ANDI to CCR", "ANDI to SR", "EORI to CCR", "EORI to SR", "ILLEGAL", "RESET", 
        "NOP", "STOP", "RTE", "RTS", "TRAPV", "RTR", "ORI", "ANDI", "SUBI", "ADDI", "EORI", "CMPI", "BTST", "BCHG", 
        "BCLR", "BSET", "BTST", "BCHG", "BCLR", "BSET", "MOVEP", "MOVEA", "MOVE", "MOVE from SR", "MOVE to CCR", 
        "MOVE to SR", "NEGX", "CLR", "NEG", "NOT", "EXT", "NBCD", "SWAP", "PEA", "TAS", "TST", "TRAP", "LINK", "UNLK", 
        "MOVE USP", "JSR", "JMP", "MOVEM", "LEA", "CHK", "ADDQ", "SUBQ", "Scc", "DBcc", "BRA", "BSR", "Bcc", "MOVEQ", 
        "DIVU", "DIVS", "SBCD", "OR", "SUB", "SUBX", "SUBA", "EOR", "CMPM", "CMP", "CMPA", "MULU", "MULS", "ABCD", 
        "EXG", "AND", "ADD", "ADDX", "ADDA", "ASd", "LSd", "ROXd", "ROd", "ASd", "LSd", "ROXd", "ROd", 
    }

    covered_instructions := make(map[string]bool)
    defer delete(covered_instructions)

    for instr in all_instructions {
        covered_instructions[instr] = false
    }

    test_case :: struct {
        opcode: u16,
        expected_mnemonic: string,
    }

    cases := []test_case{
        { 0x003C, "ORI to CCR" }, { 0x007C, "ORI to SR" }, { 0x0053, "ORI" }, { 0x023C, "ANDI to CCR" }, { 0x027C, "ANDI to SR" }, 
        { 0x0202, "ANDI" }, {0x0494, "SUBI" }, { 0x0645, "ADDI" }, { 0x0A3C, "EORI to CCR" }, { 0x0A7C, "EORI to SR" }, 
        { 0x0A11, "EORI" }, { 0x0C78, "CMPI" }, { 0x0812, "BTST" }, { 0x0853, "BCHG" }, { 0x0894, "BCLR" }, { 0x08D5, "BSET" }, 
        { 0x0306, "BTST" }, { 0x0551, "BCHG" }, { 0x0792, "BCLR" }, { 0x09D3, "BSET" }, { 0x03CA, "MOVEP" }, { 0x2654, "MOVEA" }, 
        { 0x14BC, "MOVE" }, { 0x40D3, "MOVE from SR" }, { 0x44C1, "MOVE to CCR" }, { 0x46C2, "MOVE to SR" }, { 0x4003, "NEGX" }, 
        { 0x4254, "CLR" }, { 0x4485, "NEG" }, { 0x4616, "NOT" }, { 0x4883, "EXT" }, { 0x48C5, "EXT" }, { 0x4812, "NBCD" }, 
        { 0x4844, "SWAP" }, { 0x486B, "PEA" }, { 0x4AFC, "ILLEGAL" }, { 0x4AD5, "TAS" }, { 0x4A46, "TST" }, { 0x4E47, "TRAP" }, 
        { 0x4E55, "LINK" }, { 0x4E5E, "UNLK" }, { 0x4E62, "MOVE USP" }, { 0x4E70, "RESET" }, { 0x4E71, "NOP" }, { 0x4E72, "STOP" }, 
        { 0x4E73, "RTE" }, { 0x4E75, "RTS" }, { 0x4E76, "TRAPV" }, { 0x4E77, "RTR" }, { 0x4EAA, "JSR" }, { 0x4EEB, "JMP" }, 
        { 0x4894, "MOVEM" }, { 0x4CD5, "MOVEM" }, { 0x45EC, "LEA" }, { 0x4785, "CHK" }, { 0x5A42, "ADDQ" }, { 0x5783, "SUBQ" }, 
        { 0x57D4, "Scc" }, { 0x57CD, "DBcc" }, { 0x6008, "BRA" }, { 0x6108, "BSR" }, { 0x6608, "Bcc" }, { 0x7605, "MOVEQ" }, 
        { 0x86D2, "DIVU" }, { 0x8BD4, "DIVS" }, { 0x8501, "SBCD" }, { 0x8509, "SBCD" }, { 0x863C, "OR" }, { 0x8B54, "OR" }, 
        { 0x943C, "SUB" }, { 0x9D95, "SUB" }, { 0x9541, "SUBX" }, { 0x998B, "SUBX" }, { 0x96FC, "SUBA" }, { 0x9BC4, "SUBA" }, 
        { 0xB553, "EOR" }, { 0xBB0A, "CMPM" }, { 0xB6BC, "CMP" }, { 0xB4D4, "CMPA" }, { 0xC8D3, "MULU" }, { 0xCDD5, "MULS" }, 
        { 0xC501, "ABCD" }, { 0xC90B, "ABCD" }, { 0xC342, "EXG" }, { 0xC74C, "EXG" }, { 0xC58D, "EXG" }, { 0xC23C, "AND" }, 
        { 0xC752, "AND" }, { 0xD83C, "ADD" }, { 0xDD95, "ADD" }, { 0xD742, "ADDX" }, { 0xD509, "ADDX" }, { 0xD4FC, "ADDA" }, 
        { 0xD9C3, "ADDA" }, { 0xE1D3, "ASd" }, { 0xE0D4, "ASd" }, { 0xE3D5, "LSd" }, { 0xE2D6, "LSd" }, { 0xE5D1, "ROXd" }, 
        { 0xE4D2, "ROXd" }, { 0xE7D3, "ROd" }, { 0xE6D4, "ROd" }, { 0xE742, "ASd" }, { 0xE2A3, "ASd" }, { 0xE94C, "LSd" }, 
        { 0xE4AD, "LSd" }, { 0xEB56, "ROXd" }, { 0xE6B1, "ROXd" }, { 0xED5A, "ROd" }, { 0xE8BB, "ROd" },
    }

    for c in cases {
        _, instr := m68k_decode_instruction_uncached(c.opcode)
        
        testing.expectf(
            t, 
            instr.mnemonic == c.expected_mnemonic, 
            "opcode %04X should have been decoded as %s, but actually decoded as %s",
            c.opcode,
            c.expected_mnemonic,
            instr.mnemonic,
        )

        covered_instructions[instr.mnemonic] = true
    }

    for instr, covered in covered_instructions {
        testing.expectf(t, covered, "instruction %s is not covered by the tests", instr)
    }
}
