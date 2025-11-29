const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const game_lib = b.addLibrary(.{
        .name = "game",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/game.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(game_lib);
    const lib_cmd = b.addInstallArtifact(game_lib, .{});

    const exe = b.addExecutable(.{
        .name = "vaster",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const install_cmd = b.addInstallArtifact(exe, .{});

    const exe_step = b.step("runner", "Compile the wrapper runner executable");
    exe_step.dependOn(&install_cmd.step);

    const all_step = b.step("all", "Compile the game and wrapper");
    all_step.dependOn(exe_step);
    all_step.dependOn(&lib_cmd.step);
}
