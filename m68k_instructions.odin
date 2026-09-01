package main

// Resolves an address register, taking 2 stack pointers banking into account.
// A7 refers to either USP or SSP, depending on the S flag.
m68k_resolve_address_register :: proc(m: ^M68K, reg: u16) -> ^u32 {
	// When the register number is 7 AND supervisor mode is active, add 1 to the register number to actually
	// return A8, which holds SSP. This is a branchless way to implement banking for 2 stack pointers.
	return &m.A[reg + u16(reg == 7) * u16(m.SR.S)]
}

// Resolves instruction effective address, fetches necessary amount of extension words according to 
// addressing mode, and advances PC. 
m68k_resolve_effective_address :: proc(m: ^M68K, size: M68K_Data_Size, addressing_mode: M68K_Addressing_Mode, reg: u16) -> M68K_Effective_Address {
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

    ea: M68K_Effective_Address

    #partial switch addressing_mode {
    case .Data_Register:
        ea = &m.D[reg]
    case .Address_Register:
        ea = m68k_resolve_address_register(m, reg)
    case .Address:
        ea = m.A[reg]
    case .Address_With_Postincrement:
        ea = m.A[reg]

        if reg == 7 && size == .Byte { // A7 (aka stack pointer) is always kept to a word boundary
            m.A[reg] += 2
        } else {
            m.A[reg] += u32(size)
        }
    case .Address_With_Predecrement:
        if reg == 7 && size == .Byte {
            m.A[reg] -= 2
        } else {
            m.A[reg] -= u32(size)
        }

        ea = m.A[reg]
    case .Address_With_Displacement:
        ea = address_with_displacement(m, m.A[reg])
    case .Address_With_Index:
        ea = address_with_index(m, m.A[reg])
    case .Absolute_Short:
        ea = u32(i32(i16(m68k_fetch(m, .Word))))
    case .Absolute_Long:
        ea = m68k_fetch(m, .Long)
    case .PC_With_Displacement:
        ea = address_with_displacement(m, m.PC)
    case .PC_With_Index:
        ea = address_with_index(m, m.PC)
    case .Immediate:
        ea = M68K_Immediate(m68k_fetch(m, size))
    case:
        panic("effective address resolution for invalid addressing mode")
    }

    // M68K's bus is 24-bit wide
    addr, ok := ea.(u32)
    if ok {
        ea = addr & 0xFFFFFF
    }

    return ea
}

m68k_illegal :: proc(i: ^M68K_Instruction_Cache_Entry, m: ^M68K, opcode: u16) -> u8 {
    return 34
}

m68k_eor :: proc(i: ^M68K_Instruction_Cache_Entry, m: ^M68K, opcode: u16) -> u8 {
    data_register := (opcode >> 9) & 0b111
    ea := m68k_resolve_effective_address(m, i.size, i.addressing_mode, i.reg)

    data_ea := ea_read(m, ea, i.size)
    result := data_ea ~ (m.D[data_register] & Data_Mask[i.size])
    ea_write(m, ea, i.size, result)

    m.SR.N = u8(result >> (u32(i.size) << 3 - 1))
    m.SR.Z = u8(result == 0)
    m.SR.V = 0
    m.SR.C = 0

    return i.execution_cycles
}

m68k_eori :: proc(i: ^M68K_Instruction_Cache_Entry, m: ^M68K, opcode: u16) -> u8 {
    data_imm := m68k_fetch(m, i.size)
    ea := m68k_resolve_effective_address(m, i.size, i.addressing_mode, i.reg)

    data_ea := ea_read(m, ea, i.size)
    result := data_ea ~ data_imm
    ea_write(m, ea, i.size, result)

    m.SR.N = u8(result >> (u32(i.size) << 3 - 1))
    m.SR.Z = u8(result == 0)
    m.SR.V = 0
    m.SR.C = 0

    return i.execution_cycles
}

m68k_eori_to_ccr :: proc(i: ^M68K_Instruction_Cache_Entry, m: ^M68K, opcode: u16) -> u8 {
    data_imm := u16(m68k_fetch(m, .Byte))

    result := data_imm ~ (u16(m.SR) & 0xFF)
    m.SR = auto_cast ((u16(m.SR) & 0xFF00) | result)

    return 20
}
