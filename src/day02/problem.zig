const std = @import("std");
const deanread = @import("dean");

test "legacy" {
    const alloc = std.testing.allocator;

    const content = try deanread.readFromExe(alloc, "day02.txt");
    defer alloc.free(content);

    var lines = std.mem.splitScalar(u8, content, '\n');
    const answer = try part2(&lines);
    try std.testing.expectEqual(@as(u32, 72513), answer);
}

const Balls = struct {
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
};

fn part1(lines: *std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar)) !u32 {
    var sum: u32 = 0;
    while (lines.next()) |line| {
        const gameIdIdx = getGameIdIdx(line) orelse break;
        const gameId = gameIdIdx[0];
        const colon = gameIdIdx[1];
        const maxBalls = maxOfEachColor(line[colon + 1 ..]) orelse break;
        if (maxBalls.red > 12) {
            continue;
        }
        if (maxBalls.green > 13) {
            continue;
        }
        if (maxBalls.blue > 14) {
            continue;
        }

        sum += gameId;
    }
    return sum;
}

fn part2(lines: *std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar)) !u32 {
    var sum: u32 = 0;
    while (lines.next()) |line| {
        const gameIdIdx = getGameIdIdx(line) orelse break;
        const colon = gameIdIdx[1];
        const maxBalls = maxOfEachColor(line[colon + 1 ..]) orelse break;

        const power = maxBalls.red * maxBalls.blue * maxBalls.green;

        sum += power;
    }
    return sum;
}

fn maxOfEachColor(line: []const u8) ?Balls {
    var maxOfEach: Balls = .{};

    var iter = std.mem.splitAny(u8, line, ",;");
    while (iter.next()) |pull| {
        const numberStart = 1;
        const numberEnd = std.mem.indexOfScalarPos(u8, pull, numberStart, ' ') orelse continue;
        const number = std.fmt.parseInt(u32, pull[numberStart..numberEnd], 10) catch continue;
        const colorChar = pull[numberEnd + 1];

        switch (colorChar) {
            'r' => maxOfEach.red = @max(maxOfEach.red, number),
            'g' => maxOfEach.green = @max(maxOfEach.green, number),
            'b' => maxOfEach.blue = @max(maxOfEach.blue, number),
            else => std.debug.print("illegal color '{c}'\n", .{colorChar}),
        }
    }

    return maxOfEach;
}

fn getGameIdIdx(line: []const u8) ?struct { u32, usize } {
    const start = 5;
    const end = std.mem.indexOfScalar(u8, line, ':') orelse return null;

    const id = std.fmt.parseInt(u32, line[start..end], 10) catch return null;

    return .{ id, end };
}
