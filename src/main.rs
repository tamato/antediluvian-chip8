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

        disassemble(data, file_path.to_owned());
    }

    Ok(())
}

fn disassemble(rom: Vec<u8>, file_name: String) {
    let mut disassemed_file = file_name;
    disassemed_file.push_str(".dis");
    let mut diss = File::create(disassemed_file).unwrap();

    for byte in rom {
        println!("Byte: {byte}");
        diss.write(&[byte;1]).unwrap();
    }
}

