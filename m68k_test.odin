package main

import "core:encoding/json"
import "core:strings"
import "core:log"
import "core:os"
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

@(test)
test_m68k_json :: proc(t: ^testing.T) {
    test_cpu_state :: struct {
        d0: u32 `json:"d0"`,
        d1: u32 `json:"d1"`,
        d2: u32 `json:"d2"`,
        d3: u32 `json:"d3"`,
        d4: u32 `json:"d4"`,
        d5: u32 `json:"d5"`,
        d6: u32 `json:"d6"`,
        d7: u32 `json:"d7"`,

        a0: u32 `json:"a0"`,
        a1: u32 `json:"a1"`,
        a2: u32 `json:"a2"`,
        a3: u32 `json:"a3"`,
        a4: u32 `json:"a4"`,
        a5: u32 `json:"a5"`,
        a6: u32 `json:"a6"`,

        usp: u32 `json:"usp"`,
        ssp: u32 `json:"ssp"`,
        sr: u16 `json:"sr"`,
        pc: u32 `json:"pc"`,
        
        ram: [][2]u32 `json:"ram"`,
    }

    m68k_init_instruction_decoding_cache()

    test_case :: struct {
        name: string `json:"name"`,
        initial: test_cpu_state `json:"initial"`,
        final: test_cpu_state `json:"final"`,
        length: u8 `json:"length"`,
    }

    w := os.walker_create("test_data/m68k/json")
    defer os.walker_destroy(&w)

    // Odin allows to use procedures returning bool as the last value, in range loops.
    // Loop runs until function returns false.
    for info in os.walker_walk(&w) {
        if info.type == .Directory {
            os.walker_skip_dir(&w)
            continue
        }

        if !strings.starts_with(info.name, "EOR") {
            continue
        }

        data, err := os.read_entire_file(info.fullpath, context.allocator)
        testing.expect_value(t, err, nil)
        defer delete(data)

        cases: []test_case
        testing.expect_value(t, json.unmarshal(data, &cases), nil)
        
        defer {
            for c in cases {
                delete(c.name)
                delete(c.initial.ram)
                delete(c.final.ram)
            }

            delete(cases)
        }

        for c in cases {
            log.infof("testing %s", c.name)

            m := M68K{
                // M68K has a 2-word prefetch queue which I currently don't emulate, so at the start of each test
                // 2 words (opcode and the word after it) have already been put onto the queue, and PC itself
                // has incremented. Decrement PC by 4 to execute the intended opcode "in-place".
                PC = c.initial.pc - 4,

                SR = auto_cast c.initial.sr,
            }

            m.D = { 
                c.initial.d0, c.initial.d1, c.initial.d2, c.initial.d3, 
                c.initial.d4, c.initial.d5, c.initial.d6, c.initial.d7,
            }

            m.A = {
                c.initial.a0, c.initial.a1, c.initial.a2, c.initial.a3,
                c.initial.a4, c.initial.a5, c.initial.a6, c.initial.usp,
                c.initial.ssp,
            }

            for el in c.initial.ram {
                m68k_write(&m, el[0], .Byte, el[1])
            }

            opcode := u16(m68k_fetch(&m, .Word))
            instr := m68k_decode_instruction(opcode)
            cycles := instr->handler(&m, opcode)

            is_success := true

            expect_value(t, &is_success, m.D[0], c.final.d0)
            expect_value(t, &is_success, m.D[1], c.final.d1)
            expect_value(t, &is_success, m.D[2], c.final.d2)
            expect_value(t, &is_success, m.D[3], c.final.d3)
            expect_value(t, &is_success, m.D[4], c.final.d4)
            expect_value(t, &is_success, m.D[5], c.final.d5)
            expect_value(t, &is_success, m.D[6], c.final.d6)
            expect_value(t, &is_success, m.D[7], c.final.d7)

            expect_value(t, &is_success, m.A[0], c.final.a0)
            expect_value(t, &is_success, m.A[1], c.final.a1)
            expect_value(t, &is_success, m.A[2], c.final.a2)
            expect_value(t, &is_success, m.A[3], c.final.a3)
            expect_value(t, &is_success, m.A[4], c.final.a4)
            expect_value(t, &is_success, m.A[5], c.final.a5)
            expect_value(t, &is_success, m.A[6], c.final.a6)

            expect_value(t, &is_success, m.A[7], c.final.usp)
            expect_value(t, &is_success, m.A[8], c.final.ssp)
            expect_value(t, &is_success, m.PC, c.final.pc - 4) // Decrement by 4 to account for lack of pre-fetch queue
            expect_value(t, &is_success, u16(m.SR), c.final.sr)

            expect_value(t, &is_success, cycles, c.length)

            for el in c.final.ram {
                v := m68k_read(&m, el[0], .Byte)
                expect_value(t, &is_success, v, el[1])
            }

            if !is_success {
                log.infof("stopping after a failed test")
                return
            }
        }
    }

    _, err_walk := os.walker_error(&w)
    testing.expect_value(t, err_walk, nil)
}

expect_value :: proc(t: ^testing.T, is_success: ^bool, value, expected: $T, loc := #caller_location, value_expr := #caller_expression(value)) {
    is_success^ &= testing.expect_value(t, value, expected, loc, value_expr)
}
