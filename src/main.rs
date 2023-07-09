use std::env;
use std::fs::File;
use std::io::prelude::*;

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
    let col_byte_limit = 2;

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

    let len = rom.len();
    println!("Len: {len}");
    let mut idx = 0;
    loop {
        let inst0 = rom[idx];
        idx += 1;
        // let inst1 = rom[idx];
        idx += 1;

        // isolate the high nib of the first byte.
        let high_nib:u8 = inst0 >> 4;
        match high_nib {
            0x0 => {
                let high_nib = (inst0 & high_nib_mask) == 0;
                let low_nib = (inst0 & low_nib_mask) != 0;

                println!("could sysadd, cls, or ret");
            },
            0x1 => {
                println!("JP");
            },
            0x2 => {
                println!("CALL addr");
            },
            0x3 => {
                println!("SKIP ie EQ");
            },
            0x4 => {
                println!("SKIP NEQ");
            },
            0x5 => {
                println!("SKIP X=Y");
            },
            0x6 => {
                println!("SET");
            },
            0x7 => {
                println!("ADD");
            },
            0x8 => {
                println!("OR");
            },
            0x9 => {
                println!("SKIP x!=y");
            },
            0xA => {
                println!("LD I");
            },
            0xB => {
                println!("JMP v0");
            },
            0xC => {
                println!("RND");
            },
            0xD => {
                println!("DRW");
            },
            0xE => {
                println!("SKIP PRESSED");
            },
            0xF => {
                println!("COND LD");
            },
            _ => println!("wut?"),
        }

        // diss.write_all(hex.as_bytes()).unwrap();
        if idx >= len {
            break;
        }
    }

    // TODO read 2 bytes in at a time.
    for byte in rom {
        let hex: String = to_hex(*byte, 2);
        // println!("Hex: {hex}");
        diss.write_all(hex.as_bytes()).unwrap();
    }
}

fn to_hex(val: u8, len:usize) -> String {
    format!("{:01$x}", val, len)
}
