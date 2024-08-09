const std = @import("std");
const bufPrint = std.fmt.bufPrint;

///
/// Disassemble chip8 program into human readable format.
///

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // command to run program
    // TODO need to update
    // zig build-exe run -- /home/ahrimen/repos/antediluvian-chip8/resources/c8roms/GUESS
    if (args.len < 2) {
        return error.InvalidNumberOfArguments;
    }

    // load up a program.
    const file_path = args[1];
    const rom = try std.fs.openFileAbsolute(file_path, .{} );
    defer rom.close();

    disassemble(rom, file_path) catch |err| {
        std.debug.print("Disassemble threw some Error: {any}\n", .{err});
    };
}

pub fn disassemble(rom: std.fs.File, file_name: []const u8) !void {
    var name: [100:0]u8 = undefined;
    const slice = bufPrint(&name, "{s}.dis", .{ std.fs.path.basename(file_name)} ) 
        catch |err| {
            std.debug.print("Error, failed to format file name, {any}\n", .{err});
            return; 
    };

    const file = std.fs.cwd().createFile( slice, .{}) 
        catch |err| {
            std.debug.print("Error, failed to create disassembly file, {any}\n", .{err});
            return;
    };
    defer file.close();

    const reader = rom.reader();
   
    //
    // TODO what is the maximum size, number of instructions, a file could have?
    // http://devernay.free.fr/hacks/chip8/C8TECH10.HTM#2.1
    // The Chip-8 language is capable of accessing up to 4KB (4,096 bytes) of RAM, from location 0x000 (0) to 0xFFF (4095). The first 512 bytes, from 0x000 to 0x1FF, are where the original interpreter was located, and should not be used by programs
    // 4096 = 0x1000 hex
    while (true) {
        var buf = [_]u8{0} ** std.mem.page_size;
        const amt_read = reader.read(&buf) catch |err| {
            std.debug.print("Error, {any}", .{err});
            return;
        };

        if (0 == amt_read) {
            break;
        }

        const opCodeSize: usize = 2;
        var iter = std.mem.window(u8, buf[0..amt_read], opCodeSize, opCodeSize);
        while (iter.next()) |bytes| {
            var log: []u8 = &.{}; // "zero-init"
            var log_storage = [_:0]u8{0}**100;
            
            // The high nibble of bytes[0] contains the command
            // the lower nibble holds the variable part of the command.
            const highNibble:u8 = bytes[0] >> 4;
            switch (highNibble) {
                0x0 => {
                    switch (bytes[1]) {
                        0x0E => log = try bufPrint(&log_storage, "Clear Screen", .{}),
                        0xEE => log = try bufPrint(&log_storage, "Exit Subroutine", .{}),
                        else => {
                            // Jump to a machine code routine at nnn, older
                            log = try bufPrint(&log_storage, "DEPRECATED: Jump to sys addr 0x{x:0>2}{x:0>2}", .{bytes[0], bytes[1]});
                        },
                    }
                },
                0x1 => {
                    // to get NNN from the high byte and low byte, combine them
                    // knock off the high nibble
                    const jumpAddr:u16 = @as(u16, (bytes[0] & 0x0F) << 0x4 | bytes[1]);
                    log = try bufPrint(&log_storage, "Set PC to {d}", .{jumpAddr});
                },
                0x2 => {
                    // Call subroutine at nnn.
                    // The interpreter increments the stack pointer,
                    // then puts the current PC on the top of the stack. The PC is then set to nnn.

                    // to get NNN from the high byte and low byte, combine them
                    // knock off the high nibble
                    const jumpAddr:u16 = @as(u16, (bytes[0] & 0x0F) << 0x4 | bytes[1]);
                    log = try bufPrint(&log_storage, "Call subroutine at 0x{x:0>4}", .{jumpAddr});
                },
                0x3 => {
                    const vx:u8 = bytes[0] & 0x0F;
                    const NN:u8 = bytes[1];
                    log = try bufPrint(&log_storage, "If X{x} != {d}", .{vx, NN});
                },
                0x4 => {
                    const vx:u8 = bytes[0] & 0x0F;
                    const NN:u8 = bytes[1];
                    log = try bufPrint(&log_storage, "If X{x} == {d}", .{vx, NN});
                },
                0x5 => {
                    const vx:u8 = bytes[0] & 0x0F;
                    const vy:u8 = bytes[1] & 0xF0;
                    log = try bufPrint(&log_storage, "If X{x} == Y{x}", .{vx, vy});
                },
                0x6 => {
                    const vx:u8 = bytes[0] & 0x0F;
                    const NN:u8 = bytes[1];
                    log = try bufPrint(&log_storage, "X{x} = {d}", .{vx, NN});
                },
                0x7 => {
                    const vx:u8 = bytes[0] & 0x0F;
                    const NN:u8 = bytes[1];
                    log = try bufPrint(&log_storage, "X{x} += {d}", .{vx, NN});
                },
                else => {},
            }

            // Write the log out to a *.dis file
            const offset = iter.index orelse amt_read;
            writeToFile(file, offset - opCodeSize, bytes, log);
        }
    }
}

pub fn writeToFile(file: std.fs.File, row_counter:usize, opCodes:[]const u8, dis:[]const u8) void {
    var buf:[300:0]u8 = undefined;
    // from fmt.zig
    //      e.g. {[specifier]:[fill][alignment][width]}
    const filled = bufPrint(&buf, "0x{x:0>4}: {x:0>4} {s}\n", 
        .{row_counter, std.fmt.fmtSliceHexLower(opCodes), dis}
    ) catch |err| {
            std.debug.print("Error, {any}\n", .{err});
            return;
    };

    _ = file.write(filled) catch |err| {
        std.debug.print("Error, {any}\n", .{err});
        return;
    };
}

