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

pub fn disassemble(rom: std.fs.File, file_name: []const u8) !void {// {{{
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

    var buf: [std.mem.page_size]u8 = undefined;
    const reader = rom.reader();
   
    //
    // TODO what is the maximum size, number of instructions, a file could have?
    // http://devernay.free.fr/hacks/chip8/C8TECH10.HTM#2.1
    // The Chip-8 language is capable of accessing up to 4KB (4,096 bytes) of RAM, from location 0x000 (0) to 0xFFF (4095). The first 512 bytes, from 0x000 to 0x1FF, are where the original interpreter was located, and should not be used by programs
    // 4096 = 0x1000 hex
    while (true) {
        const amt_read = reader.read(buf[0..]) catch |err| {
            std.debug.print("Error, {any}", .{err});
            return;
        };

        if (0 == amt_read) {
            break;
        }

        const opCodeSize: usize = 2;
        var iter = std.mem.window(u8, &buf, opCodeSize, opCodeSize);
        var log: [100:0]u8 = undefined;
        for (iter, 0..) |bytes, byte_offset| {
            // The high nibble of bytes[0] contains the command
            // the lower nibble holds the variable part of the command.
            const highNibble:u8 = bytes[0] >> 4;
            switch (highNibble) {
                0x0 => {
                    switch (bytes[1]) {
                        0x0E => _ = try bufPrint(&log, "Clear Screen", .{}),
                        0xEE => _ = try bufPrint(&log, "Exit Subroutine", .{}),
                        else => {
                            // Jump to a machine code routine at nnn, older
                            _ = try bufPrint(&log, "Jump to sys addr 0x{x:0>2}{x:0>2}\n", .{bytes[0], bytes[1]});
                        },
                    }
                },
                0x1 => {
                    // to get NNN from the high byte and low byte, combine them
                    // knock off the high nibble
                    const jumpAddr:u16 = @as(u16, (bytes[0] & 0x0F) << 0x4 | bytes[1]);
                    _ = try bufPrint(&log, "Set PC to {d}\n", .{jumpAddr});
                },
                0x2 => {
                    // Call subroutine at nnn.
                    // The interpreter increments the stack pointer, 
                    // then puts the current PC on the top of the stack. The PC is then set to nnn.

                    // to get NNN from the high byte and low byte, combine them
                    // knock off the high nibble
                    const jumpAddr:u16 = @as(u16, (bytes[0] & 0x0F) << 0x4 | bytes[1]);
                    _ = try bufPrint(&log, "Call subroutine at {d}\n", .{jumpAddr});
                },
                0x3 => {
                    // If vx != NN then
                    const vx:u8 = bytes[0] & 0x0F;
                    const NN = bytes[1];
                    _ = try bufPrint(&log, "If V{x} != {d}\n", .{vx, NN});
                },
                0x4 => {
                    // If vx == NN then
                    const vx:u8 = bytes[0] & 0x0F;
                    const NN = bytes[1];
                    _ = try bufPrint(&log, "If V{x} == {d}\n", .{vx, NN});
                },
                0x5 => {
                    // If vx != vy then
                    const vx:u8 = bytes[0] & 0x0F;
                    const vy:u8 = bytes[1] & 0xF0;
                    _ = try bufPrint(&log, "If V{x} == V{x}\n", .{vx, vy});
                },
                else => {},
            }

            // Write the log out to a *.dis file
            writeToFile(file, byte_offset, bytes, log);
        }
    }
}// }}}

pub fn writeToFile(file: std.fs.File, row:[]u8, from_buf:[]u8, row_counter:u32) void {// {{{
    // from fmt.zig
    //      e.g. {[specifier]:[fill][alignment][width]}
    const filled = bufPrint(row, "0x{x:0>8}: {x}\n", 
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

