const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("vaster", .{
        .root_source_file = b.path("src/game.zig"),
        .target = target,
        .optimize = optimize,
    });
    const game_lib = b.addLibrary(.{
        .name = "game",
        .linkage = .dynamic,
        .root_module = lib_mod,
    });

    b.installArtifact(game_lib);
    const lib_cmd = b.addInstallArtifact(game_lib, .{});

    const exe_mod = b.addModule("vaster", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "vaster",
        .root_module = exe_mod,
    });

    const install_cmd = b.addInstallArtifact(exe, .{});

    const exe_step = b.step("runner", "Compile the wrapper runner executable");
    exe_step.dependOn(&install_cmd.step);

    const check = b.step("check", "Check if vaster compiles");
    check.dependOn(&exe.step);
    check.dependOn(&game_lib.step);

    const all_step = b.step("all", "Compile the game and wrapper");
    all_step.dependOn(exe_step);
    all_step.dependOn(&lib_cmd.step);
}
