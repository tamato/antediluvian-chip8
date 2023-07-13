use std::env;
use std::fs::File;
use std::io::prelude::*;

/**
https://tobiasvl.github.io/blog/write-a-chip-8-emulator/


SNES
https://problemkaputt.de/fullsnes.htm
**/

fn main() -> std::io::Result<()> {
    
    // get the file to load.
    let args: Vec<String> = env::args().collect();
    dbg!(&args);

    // TODO support multiple ROMs being passed in.
    if args.len() < 2 {
        println!("Need to provide a ROM to disassemble");
        return Ok(());
    }

    // load up a rom
    { // force opened file into a scope that closes before the app is finished.
        let file_path = &args[1];
        let mut rom = File::open(file_path)?;
        let mut data = Vec::new();
        rom.read_to_end(&mut data)?;

        disassemble(&data, file_path.to_owned());
        xxd(&data, file_path.to_owned());
    }

    Ok(())
}

fn xxd(rom: &Vec<u8>, file_name: String) {
    let mut disassemed_file = file_name;//{{{
    disassemed_file.push_str(".xxd");
    let mut diss = File::create(disassemed_file).unwrap();

    let mut row_counter = 0;
    let mut column_counter = 0;
    let col_byte_limit = 16;

    let mut row_string = String::new();
    for byte in rom {

        let hex = to_hex(*byte, 2);
        row_string.push_str(&hex);
        column_counter += 1;

        // write out the completed line.
        if column_counter == col_byte_limit {
            column_counter = 0;

            let row_hex = to_hex(row_counter, 4);
            row_counter += col_byte_limit;

            row_string = format!("0x{row_hex}: {row_string}\n");
            diss.write_all(row_string.as_bytes()).unwrap();
            row_string.clear();
        }
    }
}//}}}

fn disassemble(rom: &Vec<u8>, file_name: String) {
    let mut disassemed_file = file_name;//{{{
    disassemed_file.push_str(".dis");
    let mut diss = File::create(disassemed_file).unwrap();

    // To test for a sys call, 
    // check that only the high nib is ZERO
    let high_nib_mask:u8 = 0xF0; // test for a sys call, which can be ignored.
    let low_nib_mask:u8 = 0x0F; // mask out the high portion of the byte

    let mut inst = String::new();

    // Memory has a max size of 4 kB, 4096 bytes
    // so the max offset could be 0x0FFF
    // he first 512 bytes, from 0x000 to 0x1FF, are where the original interpreter was located, and should not be used by programs.
    let _rom_maximum:u16 = 0x0FFF;

    // Rom's start at 0x200 (512 bytes)
    let mut rom_offset:u16 = 0x200;

    let len = rom.len();
    let mut idx = 0;
    loop {
        let inst0 = rom[idx];
        idx += 1;
        let inst1 = rom[idx];
        idx += 1;
        
        // isolate the high nib of the first byte.
        let high_nib:u8 = inst0 >> 4;
        match high_nib {
            0x0 => {
                match inst1 {
                    0xE0 => {
                        inst = String::from("CLR");
                    },
                    0xEE => {
                        inst = String::from("RET\n");
                    },
                    _ => {
                        let hex0: String = to_hex(inst0, 2);
                        let hex1: String = to_hex(inst1, 2);
                        inst = format!("INVEST {hex0}, {hex1}");
                    },
                }
            },
            0x1 => {
                // 1nnn
                let high_byte = to_hex(inst0&low_nib_mask, 2);
                let low_byte = to_hex(inst1, 2);
                inst = format!("JP\t\t{high_byte}{low_byte}\t\t\t; Set PC to location");
            },
            0x2 => {
                // 2nnn
                let high_byte = to_hex(inst0&low_nib_mask, 2);
                let low_byte = to_hex(inst1, 2);
                inst = format!("CALL\t{high_byte}{low_byte}");
            },
            0x3 => {
                // 3xkk
                let high_byte = to_hex(inst0&low_nib_mask, 1);
                let low_byte = to_hex(inst1, 2);
                inst = format!("SE\t\tV{high_byte}\t\t0x{low_byte}\t\t; Skip if Vx = value");
            },
            0x4 => {
                // 4xkk
                let high_byte = to_hex(inst0&low_nib_mask, 1);
                let low_byte = to_hex(inst1, 2);
                inst = format!("SNE\tV{high_byte}\t\t0x{low_byte}\t; Skip if Vx != value");
            },
            0x5 => {
                // 5xy0
                let high_byte = to_hex(inst0&low_nib_mask, 1);
                let low_byte = to_hex((inst1&high_nib_mask)>>4, 1);
                inst = format!("SE\tV{high_byte}\t\tV{low_byte}\t\t; Skip if Vx = Vy");
            },
            0x6 => {
                // 6xkk
                let high_byte = to_hex(inst0&low_nib_mask, 1);
                let low_byte = to_hex(inst1, 2);
                inst = format!("SET\tV{high_byte}\t\t0x{low_byte}\t\t");
            },
            0x7 => {
                // 7xkk
                let high_byte = to_hex(inst0&low_nib_mask, 1);
                let low_byte = to_hex(inst1, 2);
                inst = format!("ADD\tV{high_byte}\t\t0x{low_byte}");
            },
            0x8 => {
                // 8xy1 - OR Vx Vy
                // 8xy2 - AND Vx Vy
                // 8xy3 - XOR Vx Vy
                // 8xy4 - ADD Vx Vy
                // 8xy5 - SUB Vx Vy, if Vx > Vy then VF is 1, else 0
                // 8xy6 - SHR Vx {, Vy}, LSB of Vx, then VF is 1 else 0, then Vx >> 1 (divided by 2)
                // 8xy7 - SUBN Vx Vy, Vx = Vy - Vx, set VF if Vy > Vx to 1, else 0
                // 8xyE - SHL Vx {, Vy}, Vx = Vx SHL 1. MSB bit of Vx is 1, then VF is 1. Then Vx << 2

                let x = to_hex(inst0&low_nib_mask, 1);
                let y = to_hex((inst1&high_nib_mask) >> 4, 1);

                let sub_inst = inst1 & low_nib_mask;
                match sub_inst {
                    0x1 => inst = format!("OR\tV{x}\tV{y}"),
                    0x2 => inst = format!("AND\tV{x}\tV{y}"),
                    0x3 => inst = format!("XOR\tV{x}\tV{y}"),
                    0x4 => inst = format!("ADD\tV{x}\t\tV{y}"),
                    0x5 => inst = format!("SUB\tV{x}\tV{y}"),
                    0x6 => inst = format!("SHR\tV{x}\tV{y}"),
                    0x7 => inst = format!("SUBN\tV{x}\tV{y}"),
                    0xE => inst = format!("SHL\tV{x}\tV{y}"),
                    _ => inst = format!("\t\t\t\t\t\t; Invalid binary operation"),
                }
            },
            0x9 => {
                // 9xy0 - SNE Vx Vy, skip iv Vx != Vy
                let high_byte = to_hex(inst0 & low_nib_mask, 1);
                let low_byte = to_hex((inst1&high_nib_mask)>>4, 1);
                inst = format!("SNE V{high_byte} V{low_byte}; Skip if Vx != Vy");
            },
            0xA => {
                // Annn - LD I addr
                let high_byte = to_hex(inst0&low_nib_mask, 1);
                let low_byte = to_hex(inst1, 2);
                inst = format!("LD\t\tI\t\t{high_byte}{low_byte}");
            },
            0xB => {
                // Bnnn - JP V0 addr
                let high_byte = to_hex(inst0&low_nib_mask, 2);
                let low_byte = to_hex(inst1, 2);
                inst = format!("JP V0 {high_byte}{low_byte}\t\t; PC is set to addr plus V0");
            },
            0xC => {
                // Cxkk - RND Vx byte
                let high_byte = to_hex(inst0&low_nib_mask, 1);
                let low_byte = to_hex(inst1, 2);
                inst = format!("RND V{high_byte} {low_byte}\t\t; Rng AND'd with byte, store in Vx");
            },
            0xD => {
                // Dxyn - DRW Vx Vy nibble
                let x = to_hex(inst0&low_nib_mask, 1);
                let y = to_hex((inst1&high_nib_mask) >> 4, 1);
                let n = to_hex(inst1&low_nib_mask, 1);
                inst = format!("DRW\tV{x} V{y} 0x{n}\t\t; Draw n-byte sprite starting at I, set VF = collison");
            },
            0xE => {
                // Ex9E - SKP Vx
                // Skip next instruction if key with the value of Vx is pressed.

                // ExA1 - SKNP Vx
                // Skip next instruction if key with the value of Vx is not pressed.

                let x = to_hex(inst0&low_nib_mask, 1);
                match inst1 {
                    0x9E => inst = format!("SKP\tV{x}t\t; Skip is key Vx is pressed"),
                    0xA1 => inst = format!("SKNP\tV{x}t\t; Skip is key Vx NOT is pressed"),
                    _ => inst = format!("Invalid SKP instruction"),
                }
            },
            0xF => {
                /*
                Fx07 - LD Vx, DT
                Set Vx = delay timer value.
                The value of DT is placed into Vx.

                Fx0A - LD Vx, K
                Wait for a key press, store the value of the key in Vx.
                All execution stops until a key is pressed, then the value of that key is stored in Vx.

                Fx15 - LD DT, Vx
                Set delay timer = Vx.
                DT is set equal to the value of Vx.

                Fx18 - LD ST, Vx
                Set sound timer = Vx.
                ST is set equal to the value of Vx.

                Fx1E - ADD I, Vx
                Set I = I + Vx.
                The values of I and Vx are added, and the results are stored in I.

                Fx29 - LD F, Vx
                Set I = location of sprite for digit Vx.
                The value of I is set to the location for the hexadecimal sprite corresponding to the value of Vx. See section 2.4, Display, for more information on the Chip-8 hexadecimal font.

                Fx33 - LD B, Vx
                Store BCD representation of Vx in memory locations I, I+1, and I+2.
                The interpreter takes the decimal value of Vx, and places the hundreds digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.

                Fx55 - LD [I], Vx
                Store registers V0 through Vx in memory starting at location I.
                The interpreter copies the values of registers V0 through Vx into memory, starting at the address in I.

                Fx65 - LD Vx, [I]
                Read registers V0 through Vx from memory starting at location I.
                The interpreter reads values from memory starting at location I into registers V0 through Vx.
                */
                inst = String::from("COND\tLD");
            },
            _ => {
                inst = String::from("wut");
            },
        }

        diss.write_all(format!("{rom_offset:04X}\t{inst0:02X} {inst1:02X}\t\t{inst}\n").as_bytes()).unwrap();
        rom_offset += 2;
        if idx >= len {
            break;
        }
    }
}//}}}

fn to_hex(val: u8, len:usize) -> String {
    format!("{:01$x}", val, len)
}

