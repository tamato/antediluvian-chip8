const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.debug.print("Arguments: {s}\n", .{args[1]});

    if (args.len < 2) {
        return error.InvalidNumberOfArguments;
    }

    // load up a rom
    const file_path = args[1];
    const rom = try std.fs.openFileAbsolute(file_path, .{} );
    defer rom.close();
    
    xxd(rom, file_path);
}

fn xxd(rom: std.fs.File, file_name: []const u8) void {
    _ = file_name;
    var buf: [std.mem.page_size]u8 = undefined;
    const reader = rom.reader();
    while (true) {
        const amt_read = reader.read(buf[0..]) catch |err| {
            std.debug.print("Error, {any}", .{err});
            return;
        };

        if (0 == amt_read) break;

        for (buf[0..amt_read]) |byte| {
            std.debug.print("byte: {x}\n", .{byte});
        }
    }
}

// fn xxd(rom: &Vec<u8>, file_name: String) {//{{{
//     let mut disassemed_file = file_name;
//     disassemed_file.push_str(".xxd");
//     let mut diss = File::create(disassemed_file).unwrap();
//
//     let sz = rom.len();
//     let mut bytes_read:usize = 1;
//
//     let mut row_counter:u32 = 0;
//     let mut column_counter = 0;
//     let col_byte_limit = 16;
//
//     let mut row_string = String::new();
//     for byte in rom {
//         let hex = to_hex(*byte, 2);
//         row_string.push_str(&hex);
//         column_counter += 1;
//
//         // write out the completed line.
//         if    (column_counter == col_byte_limit)
//            || (bytes_read == sz) {
//             column_counter = 0;
//
//             let row_hex = format!("{row_counter:08X}");
//             row_counter += col_byte_limit;
//
//             row_string = format!("0x{row_hex}: {row_string}\n");
//             diss.write_all(row_string.as_bytes()).unwrap();
//             row_string.clear();
//         }
//
//         bytes_read += 1;
//     }
// }//}}}
