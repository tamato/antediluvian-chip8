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
}

