const std = @import("std");
const deanread = @import("../deanread/read.zig");

pub fn main(alloc: std.mem.Allocator) !void {
    const content = try deanread.readFromExe(alloc, "day03.txt");
    var lines = std.ArrayList([]const u8).init(alloc);
    var linesIter = std.mem.splitScalar(u8, content, '\n');
    while (linesIter.next()) |line| {
        try lines.append(line);
    }
    std.debug.print("\n{d}\n", .{try part2(alloc, lines.items)});
}

fn part1(alloc: std.mem.Allocator, lines: []const []const u8) !u32 {
    _ = alloc;
    _ = lines;
    return 0;
}

fn part2(alloc: std.mem.Allocator, lines: []const []const u8) !u32 {
    _ = alloc;
    _ = lines;
    return 0;
}
