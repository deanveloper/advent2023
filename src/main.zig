const std = @import("std");

const days = struct {
    pub const day01 = @import("./day01/main.zig");
    pub const day02 = @import("./day02/main.zig");
    pub const day03 = @import("./day03/main.zig");
};

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    var argsIter = try std.process.argsWithAllocator(allocator.allocator());
    defer argsIter.deinit();

    _ = argsIter.next(); // first arg is executable
    const numberStr = argsIter.next() orelse return error.ArgIsRequired;
    const number = std.fmt.parseInt(u8, numberStr, 10) catch |err| {
        if (err == error.InvalidCharacter) {
            std.debug.print("first arg: \"{s}\"", .{numberStr});
        }
        return;
    };
    switch (number) {
        1 => {
            try days.day01.main(allocator.allocator());
        },
        2 => {
            try days.day02.main(allocator.allocator());
        },
        3 => {
            try days.day03.main(allocator.allocator());
        },
        else => {
            std.debug.print("not a valid number: {d}", .{number});
        },
    }
}
