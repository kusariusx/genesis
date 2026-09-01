package main

import "base:runtime"

// Motorola 68000 CPU
M68K :: struct {
    // Registers
    D:   [8]u32, // Data registers
    A:   [9]u32, // Address registers (A7 is the USP - user stack pointer, and A8 is SSP - supervisor stack pointer)
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

    halted: bool,
}

// Using enum as a group of named constants. Holding already shifted vectors to avoid doing it at runtime.
M68K_Exception_Vector :: enum u32 {
	// Group 0
	Reset, // Vectors 0 (initial SSP) and 1 (initial PC)
	Bus_Error = 2 << 2,
	Address_Error = 3 << 2,

	// Group 1
	Trace = 9 << 2,
	Interrupt,
	Illegal_Instruction = 4 << 2,
	Privilege_Violation = 8 << 2,

	// Group 2
	TRAP,
	TRAPV = 7 << 2,
	CHK = 6 << 2,
	Zero_Divide = 5 << 2,
}

// Common fields for address error and bus error exceptions
M68K_Address_Or_Bus_Error_Exception :: struct {
	opcode: u16,
	address: u32,
	is_read: bool, // Is exception caused by read or write
	is_instruction: bool, // Is exception occured during instruction processing
	function_code: u16,
}

// Keeping 2 separate structs to make intent clearer
M68K_Address_Error_Exception :: struct {
	using _: M68K_Address_Or_Bus_Error_Exception,
}

M68K_Bus_Error_Exception :: struct {
	using _: M68K_Address_Or_Bus_Error_Exception,
}

M68K_Exception :: union {
	M68K_Address_Error_Exception,
	M68K_Bus_Error_Exception,
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

m68k_handle_exception :: proc(m: ^M68K, ex: M68K_Exception) -> u8 {
	handle_address_or_bus_error_exception :: proc(m: ^M68K, vector: M68K_Exception_Vector, e: M68K_Address_Or_Bus_Error_Exception) {
		// The status register is copied, the supervisor state is entered, and the trace state is turned off
		sr_copy := m.SR
		m.SR.S = 1
		m.SR.T = 0

		// Push stack frame
		m68k_push(m, u16(m.PC & 0xFFFF))
		m68k_push(m, u16(m.PC >> 16))
		m68k_push(m, u16(sr_copy))
		m68k_push(m, e.opcode)
		m68k_push(m, u16(e.address & 0xFFFF))
		m68k_push(m, u16(e.address >> 16))
		m68k_push(m, (u16(e.is_read) << 4) | (u16(!e.is_instruction) << 3) | (e.function_code & 0b111))

		// Fetch vector
		m.PC = m68k_read(m, u32(vector), .Long)
	}
	
	#partial switch e in ex {
	case M68K_Address_Error_Exception:
		handle_address_or_bus_error_exception(m, .Address_Error, e)
		return 50
	case M68K_Bus_Error_Exception:
		handle_address_or_bus_error_exception(m, .Bus_Error, e)
		return 50
	case:
		return 0
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

// Pushes a value onto a stack (user or supervisor depending on current mode)
m68k_push :: proc(m: ^M68K, value: u16) {
	sp := m68k_resolve_address_register(m, 7)
	sp^ -= 2 // Pre-decrement, align to word
	m68k_write(m, sp^, .Word, u32(value))
}

m68k_pop :: proc(m: ^M68K) -> u16 {
	sp := m68k_resolve_address_register(m, 7)
	val := m68k_read(m, sp^, .Word)
	sp^ += 2 // Post-increment, align to word
	return u16(val)
}
