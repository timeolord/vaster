const std = @import("std");
const learning_zig = @import("learning_zig");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    try learning_zig.bufferedPrint();
}
