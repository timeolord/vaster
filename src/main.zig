const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;

const glfw = @import("zglfw");

const constants = @import("constants.zig");
const graphics = @import("graphics.zig");

const GameStatePtrOpaque = *anyopaque;

const GameLib = struct {
    const MAX_PATH_LENGTH: comptime_int = 1024;
    exe_path_buf: [MAX_PATH_LENGTH]u8 = [_]u8{undefined} ** MAX_PATH_LENGTH,
    exe_path: []const u8 = undefined,
    lib_name: []const u8 = undefined,
    lib_copy_name: []const u8 = undefined,

    lib_path: []const u8 = undefined,

    loaded: bool = false,
    mtime: i128 = 0,

    lib: std.DynLib = undefined,

    init: *const fn (*const std.mem.Allocator, *glfw.Window, *graphics.Context) callconv(.c) GameStatePtrOpaque = undefined,
    update: *const fn (GameStatePtrOpaque) callconv(.c) bool = undefined,
    close: *const fn (GameStatePtrOpaque) callconv(.c) void = undefined,

    fn setup(game: *GameLib) !void {
        switch (builtin.target.os.tag) {
            .windows => {
                game.lib_name = "game.dll";
                game.lib_copy_name = "_LOADED_game.dll";
            },
            .linux => {
                game.lib_name = "../lib/libgame.so";
                game.lib_copy_name = "_LOADED_libgame.so";
            },
            else => {
                std.log.err("unsupported platform {s}", .{@tagName(builtin.target.os.tag)});
                @panic("unsuported platform");
            },
        }

        game.exe_path = try std.fs.selfExeDirPath(&game.exe_path_buf);

        game.exe_path_buf[game.exe_path.len] = std.fs.path.sep;

        game.exe_path = game.exe_path_buf[0 .. game.exe_path.len + 1];

        @memcpy(game.exe_path_buf[game.exe_path.len .. game.exe_path.len + game.lib_copy_name.len], game.lib_copy_name);
        game.lib_path = game.exe_path_buf[0 .. game.exe_path.len + game.lib_copy_name.len];

        std.log.debug("exe dir path: {s}, {d}", .{ game.exe_path, game.exe_path.len });
        std.log.debug("dll path: {s}, {d}", .{ game.lib_path, game.lib_path.len });
        _ = game.check_updated();
    }

    fn load_lib(game: *GameLib) !void {
        std.debug.assert(!game.loaded);
        var dir = try std.fs.openDirAbsolute(game.exe_path, .{});
        defer dir.close();
        try dir.copyFile(game.lib_name, dir, game.lib_path, .{});
        game.lib = try std.DynLib.open(game.lib_path);

        game.init = game.lib.lookup(@TypeOf(game.init), "init") orelse return error.MissingFn;
        game.update = game.lib.lookup(@TypeOf(game.update), "update") orelse return error.MissingFn;
        game.close = game.lib.lookup(@TypeOf(game.close), "close") orelse return error.MissingFn;

        game.loaded = true;
        std.log.debug("Loaded dll", .{});
    }

    fn unload_lib(game: *GameLib) !void {
        std.debug.assert(game.loaded);
        game.lib.close();
        var dir = try std.fs.openDirAbsolute(game.exe_path, .{});
        defer dir.close();
        try dir.deleteFile(game.lib_copy_name);
        game.loaded = false;
    }

    fn check_updated(game: *GameLib) bool {
        var dir = std.fs.openDirAbsolute(game.exe_path, .{}) catch return false;
        defer dir.close();

        var f = dir.openFile(game.lib_name, .{
            .lock = .exclusive,
            .lock_nonblocking = false,
        }) catch return false;
        const stat = f.stat() catch return false;
        const was_modified = stat.mtime > game.mtime;
        f.close();
        if (was_modified)
            game.mtime = stat.mtime;
        return was_modified;
    }
};

pub fn main() !void {
    var game: GameLib = .{};
    game.setup() catch @panic("Couldn't setup game lib");
    game.load_lib() catch @panic("Couldn't load game");
    var keep_running = true;

    try glfw.init();
    defer glfw.terminate();

    if (!glfw.isVulkanSupported()) {
        @panic("Vulkan is not supported");
    }

    glfw.windowHint(glfw.WindowHint.client_api, glfw.ClientApi.no_api);
    const window: *glfw.Window = try glfw.Window.create(
        @intCast(constants.window_width),
        @intCast(constants.window_height),
        constants.app_name,
        null,
    );
    // defer window.destroy();

    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = false }){};
    const allocator = gpa.allocator();

    var graphics_context = graphics.Context.init(allocator, window);

    const gso: GameStatePtrOpaque = blk: {
        break :blk game.init(&allocator, window, &graphics_context);
    };

    while (keep_running and !window.shouldClose()) {
        if (game.check_updated()) {
            std.log.debug("Dll modified, reloading...\n", .{});
            try game.unload_lib();
            try game.load_lib();
        }
        glfw.pollEvents();

        keep_running = game.update(gso);
    }

    game.close(gso);
    try game.unload_lib();
}
