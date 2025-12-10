const std = @import("std");
const vulkan = @import("vulkan");
const glfw = @import("zglfw");

pub const GameState = struct {
    allocator: std.mem.Allocator,
    test_val: i32,
    window: *glfw.Window,
};

export fn init(allocator: *const std.mem.Allocator, window: *glfw.Window) *anyopaque {
    const gs = allocator.create(GameState) catch @panic("could not init game");
    gs.allocator = allocator.*;
    gs.test_val = 3;
    gs.window = window;

    return gs;
}

export fn update(gso: *anyopaque) bool {
    const gs: *GameState = @ptrCast(@alignCast(gso));

    gs.window.swapBuffers();

    return true;
}

export fn close(gso: *anyopaque) void {
    _ = gso;

    glfw.terminate();
}
