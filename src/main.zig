const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // command to run program
    // zig build-exe run -- /home/ahrimen/repos/antediluvian-chip8/../resources/c8roms/GUESS
    if (args.len < 2) {
        return error.InvalidNumberOfArguments;
    }

    // load up a rom
    const file_path = args[1];
    const rom = try std.fs.openFileAbsolute(file_path, .{} );
    defer rom.close();
    
    xxd(rom, file_path);
}

fn xxd(rom: std.fs.File, file_name: []const u8) void {// {{{
    var buf: [std.mem.page_size]u8 = undefined;
    const reader = rom.reader();

    var name: [100:0]u8 = undefined;
    const slice = std.fmt.bufPrint(&name, "{s}.xxd", .{ std.fs.path.basename(file_name)} ) 
        catch |err| {
            std.debug.print("Error, failed to format file name, {any}\n", .{err});
            return; 
    };

    const file = std.fs.cwd().createFile( slice, .{}) 
        catch |err| {
            std.debug.print("Error, failed to create xxd file, {any}\n", .{err});
            return;
    };
    defer file.close();

    var row: [100:0]u8 = undefined;
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

            writeToFile(file, row[0..], buf[start..end], row_counter);

            row_counter += col_byte_limit;
            start = end;
        }

        // any left over bytes?
        const remainder = amt_read % col_byte_limit;
        if (remainder > 0) {
            writeToFile(file, row[0..], buf[start..(start+remainder)], row_counter);
        }
    }
}// }}}

pub fn writeToFile(file: std.fs.File, row:[]u8, from_buf:[]u8, row_counter:u32) void {// {{{
    // from fmt.zig
    //      e.g. {[specifier]:[fill][alignment][width]}
    const filled = std.fmt.bufPrint(row, "0x{x:0>8}: {x}\n", 
        .{row_counter, std.fmt.fmtSliceHexLower(from_buf)})
        catch |err| {
            std.debug.print("Error, {any}\n", .{err});
            return;
    };

    _ = file.write(filled) catch |err| {
        std.debug.print("Error, {any}\n", .{err});
        return;
    };
}// }}}

