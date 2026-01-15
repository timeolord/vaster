const std = @import("std");

const glfw = @import("zglfw");

const constants = @import("constants.zig");
const graphics = @import("graphics.zig");

pub const GameState = struct {
    allocator: std.mem.Allocator,
    test_val: i32,
    window: *glfw.Window,

    graphics_context: *graphics.Context,
};

export fn init(allocator: *const std.mem.Allocator, window: *glfw.Window, context: *graphics.Context) *anyopaque {
    const gs = allocator.create(GameState) catch @panic("could not init game");
    gs.allocator = allocator.*;
    gs.test_val = 3;
    gs.window = window;

    gs.graphics_context = context;

    return gs;
}

export fn update(gso: *anyopaque) bool {
    const gs: *GameState = @ptrCast(@alignCast(gso));

    gs.window.swapBuffers();

    return true;
}

export fn close(gso: *anyopaque) void {
    const gs: *GameState = @ptrCast(@alignCast(gso));

    // gs.graphics_context.deinit();

    _ = gs;
}
