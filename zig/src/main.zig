const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // command to run program
    // zig build run -- /home/ahrimen/repos/antediluvian-chip8/zig/../resources/c8roms/GUESS
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

    var row_counter:u32 = 0;
    const col_byte_limit:u32 = 16;

    while (true) {
        const amt_read = reader.read(buf[0..]) catch |err| {
            std.debug.print("Error, {any}", .{err});
            return;
        };

        if (0 == amt_read) {
            break;
        }

        // Print 16 bytes at time
        // how many groups of 8 bytes are there
        const groups = amt_read / col_byte_limit + 1;
        var start:usize = 0;
        for (1..groups) |idx| {
            const end = idx * col_byte_limit;

            // from fmt.zig
            //      e.g. {[specifier]:[fill][alignment][width]}
            std.debug.print("0x{x:0>8}: {x}\n", .{
                row_counter, 
                std.fmt.fmtSliceHexLower(buf[start..end])
            });

            row_counter += col_byte_limit;
            start = end;
        }

        // any left over bytes?
        const remainder = amt_read % col_byte_limit;
        if (remainder > 0) {
            std.debug.print("0x{x:0>8}: {x}\n",
                .{row_counter,
                    std.fmt.fmtSliceHexLower(buf[start..(start+remainder)])
                }
            );
        }
    }
}

