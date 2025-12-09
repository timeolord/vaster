const std = @import("std");

const Callback = *const fn (i32) callconv(.c) void;

pub const GameState = struct {
    allocator: std.mem.Allocator,
    test_val: i32,
    callback: Callback,
};

export fn init(allocator: *const std.mem.Allocator, callback: Callback) *anyopaque {
    const gs = allocator.create(GameState) catch @panic("could not init game");
    gs.allocator = allocator.*;
    gs.test_val = 3;
    gs.callback = callback;

    return gs;
}

export fn update(gso: *anyopaque) bool {
    const gs: *GameState = @ptrCast(@alignCast(gso));

    gs.test_val +%= -12;
    gs.callback(gs.test_val);

    return true;
}

export fn close(gso: *anyopaque) void {
    _ = gso;
}
