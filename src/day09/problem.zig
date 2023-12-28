const std = @import("std");

fn readNumbers(comptime T: type, alloc: std.mem.Allocator, string: []const u8) !std.ArrayList(T) {
    var tokenizer = std.mem.tokenizeScalar(u8, string, ' ');

    var numbers = std.ArrayList(T).init(alloc);
    while (tokenizer.next()) |numStr| {
        const number = try std.fmt.parseInt(T, numStr, 10);
        try numbers.append(number);
    }

    return numbers;
}

test "part 1" {
    const alloc = std.testing.allocator;

    var sum: i64 = 0;

    const file = @embedFile("./stability.txt");
    var lines = std.mem.splitScalar(u8, file, '\n');
    while (lines.next()) |line| {
        const numbers = try readNumbers(i64, alloc, line);
        defer numbers.deinit();

        var extrapolator = try TriangleExtrapolator.init(alloc, numbers.items);
        defer extrapolator.deinit();

        const extrapolated = try extrapolator.extrapolateRight();
        sum += extrapolated;
    }

    try std.testing.expectEqual(@as(i64, 1882395907), sum);
}

test "part 2" {
    const alloc = std.testing.allocator;

    var sum: i64 = 0;

    const file = @embedFile("./stability.txt");
    var lines = std.mem.splitScalar(u8, file, '\n');
    while (lines.next()) |line| {
        const numbers = try readNumbers(i64, alloc, line);
        defer numbers.deinit();

        var extrapolator = try TriangleExtrapolator.init(alloc, numbers.items);
        defer extrapolator.deinit();

        const extrapolated = try extrapolator.extrapolateLeft();
        sum += extrapolated;
    }

    try std.testing.expectEqual(@as(i64, 1005), sum);
}

/// idk there's probably a name for this data structure, but i'm just gonna name it this because it's funny
const TriangleExtrapolator = struct {
    /// allocator used for resizing slices
    alloc: std.mem.Allocator,

    /// the top-level values as well as all interpolations, each interpolation appended will always have one fewer element than the one before it.
    values: std.ArrayList(std.ArrayList(i64)),

    fn init(alloc: std.mem.Allocator, values: []i64) !TriangleExtrapolator {
        var extrapolator = TriangleExtrapolator{ .alloc = alloc, .values = std.ArrayList(std.ArrayList(i64)).init(alloc) };

        var initialList = std.ArrayList(i64).init(alloc);
        try initialList.appendSlice(values);
        try extrapolator.values.append(initialList);

        try extrapolator.initInterpolations();

        return extrapolator;
    }

    fn initInterpolations(self: *TriangleExtrapolator) !void {
        // as long as our values are not all equal to zero, add another level to our values
        while (!std.mem.allEqual(i64, self.values.getLast().items, 0)) {
            const prevLevel = self.values.getLast();
            var newLevel = std.ArrayList(i64).init(self.alloc);

            for (1..prevLevel.items.len) |idx| {
                const prev = prevLevel.items[idx - 1];
                const curr = prevLevel.items[idx];
                try newLevel.append(curr - prev);
            }
            try self.values.append(newLevel);
        }
    }

    pub fn extrapolateRight(self: *TriangleExtrapolator) !i64 {
        if (self.values.items.len == 0) {
            return error.NoZeroesRow;
        }
        try self.values.items[self.values.items.len - 1].append(0);

        var level = self.values.items.len - 1; // len-1 to avoid zeroes row
        while (level > 0) {
            level -= 1;

            const prevLevel = &self.values.items[level + 1]; // +1 for prevLevel because we iterate backward
            var currentLevel = &self.values.items[level];

            const diff = prevLevel.getLastOrNull() orelse return error.EmptyPrevLevel;
            const lastValue = currentLevel.getLastOrNull() orelse return error.EmptyCurrentLevel;
            try currentLevel.append(lastValue + diff);
        }

        return self.values.items[0].getLast();
    }

    pub fn extrapolateLeft(self: *TriangleExtrapolator) !i64 {
        if (self.values.items.len == 0) {
            return error.NoZeroesRow;
        }
        try self.values.items[self.values.items.len - 1].append(0);

        var level = self.values.items.len - 1; // len-1 to avoid zeroes row
        while (level > 0) {
            level -= 1;

            const prevLevel = &self.values.items[level + 1]; // +1 for prevLevel because we iterate backward
            var currentLevel = &self.values.items[level];

            if (prevLevel.items.len == 0) {
                return error.EmptyPrevLevel;
            }
            if (currentLevel.items.len == 0) {
                return error.EmptyCurrentLevel;
            }

            const diff = prevLevel.items[0];
            const firstValue = currentLevel.items[0];
            try currentLevel.insert(0, firstValue - diff);
        }

        return self.values.items[0].items[0];
    }

    pub fn format(self: TriangleExtrapolator, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        var spaceOffset: u32 = 0;

        for (self.values.items) |level| {
            for (0..spaceOffset) |_| {
                try writer.print(" ", .{});
            }
            try writer.print("{}", .{level.items[0]});
            for (level.items[1..]) |number| {
                try writer.print("{: >4}", .{number});
            }
            spaceOffset += 2;
            try writer.print("\n", .{});
        }
    }

    fn deinit(self: TriangleExtrapolator) void {
        for (self.values.items) |level| {
            level.deinit();
        }
        self.values.deinit();
    }
};
