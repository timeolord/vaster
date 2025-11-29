const std = @import("std");

pub const GameState = struct {
    allocator: std.mem.Allocator,
    test_val: i32,
};

export fn init(allocator: *const std.mem.Allocator) *anyopaque {
    const gs = allocator.create(GameState) catch @panic("could not init game");
    gs.allocator = allocator.*;
    gs.test_val = 3;

    return gs;
}

export fn update(gso: *anyopaque) bool {
    const gs: *GameState = @ptrCast(@alignCast(gso));

    gs.test_val +%= 1;

    return true;
}

export fn close(gso: *anyopaque) void {
    _ = gso;
}
