const std = @import("std");
const vulkan = @import("vulkan");
const glfw = @import("zglfw");

const Callback = *const fn (i32) callconv(.c) void;

pub const GameState = struct {
    allocator: std.mem.Allocator,
    test_val: i32,
    callback: Callback,
    window: *glfw.Window,
};

export fn init(allocator: *const std.mem.Allocator, callback: Callback, window: *glfw.Window) *anyopaque {
    const gs = allocator.create(GameState) catch @panic("could not init game");
    gs.allocator = allocator.*;
    gs.test_val = 3;
    gs.callback = callback;
    gs.window = window;

    return gs;
}

export fn update(gso: *anyopaque) bool {
    const gs: *GameState = @ptrCast(@alignCast(gso));

    gs.test_val +%= -12;
    gs.callback(gs.test_val);

    if (!gs.window.shouldClose()) {
        glfw.pollEvents();

        // render your things here

        gs.window.swapBuffers();
    }

    return true;
}

export fn close(gso: *anyopaque) void {
    _ = gso;

    glfw.terminate();
}
