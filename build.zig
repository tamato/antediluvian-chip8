const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    buildXXD(b, target, optimize);
    buildDis(b, target, optimize);
    buildInterp(b, target, optimize);
}

fn buildInterp(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "interp",
        .root_source_file = .{ .path = "src/interpreter.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("interp", "Run the interpreter");
    run_step.dependOn(&run_cmd.step);


    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/interpreter.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("testinterp", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn buildXXD(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "xxdC8",
        .root_source_file = .{ .path = "src/xxd.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("xxd", "Run the xxd executable");
    run_step.dependOn(&run_cmd.step);


    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/xxd.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("testxxd", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn buildDis(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "dis",
        .root_source_file = .{ .path = "src/disassembler.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("dis", "run the disassembler");
    run_step.dependOn(&run_cmd.step);


    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/disassembler.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("testdis", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

