const std = @import("std");
const deanread = @import("../deanread/read.zig");

pub fn main(alloc: std.mem.Allocator) !void {
    const content = try deanread.readFromExe(alloc, "day01.txt");
    var lines = std.mem.splitScalar(u8, content, '\n');
    var numbers = std.ArrayList(u8).init(alloc);
    while (lines.next()) |line| {
        const hehe = processLine(line) orelse break;
        const number = hehe[0] * 10 + hehe[1];
        try numbers.append(number);
    }

    var sum: u32 = 0;
    for (numbers.items) |number| {
        sum += number;
    }
    std.log.info("{}", .{sum});
}

pub fn processLine(line: []const u8) ?struct { u8, u8 } {
    var first: u8 = 10;
    var last: u8 = 0;

    for (line, 0..) |byte, index| {
        // part 1
        if (byte <= '9' and byte >= '0') {
            mutateFirstLast(&first, &last, byte - '0');
        }

        // part 2
        if (isStartOfValue(line, index, "one")) {
            mutateFirstLast(&first, &last, 1);
        } else if (isStartOfValue(line, index, "two")) {
            mutateFirstLast(&first, &last, 2);
        } else if (isStartOfValue(line, index, "three")) {
            mutateFirstLast(&first, &last, 3);
        } else if (isStartOfValue(line, index, "four")) {
            mutateFirstLast(&first, &last, 4);
        } else if (isStartOfValue(line, index, "five")) {
            mutateFirstLast(&first, &last, 5);
        } else if (isStartOfValue(line, index, "six")) {
            mutateFirstLast(&first, &last, 6);
        } else if (isStartOfValue(line, index, "seven")) {
            mutateFirstLast(&first, &last, 7);
        } else if (isStartOfValue(line, index, "eight")) {
            mutateFirstLast(&first, &last, 8);
        } else if (isStartOfValue(line, index, "nine")) {
            mutateFirstLast(&first, &last, 9);
        } else if (isStartOfValue(line, index, "zero")) {
            mutateFirstLast(&first, &last, 0);
        }
    }

    if (first == 10) {
        return null;
    }

    return .{ first, last };
}

fn mutateFirstLast(first: *u8, last: *u8, value: u8) void {
    if (first.* == 10) {
        first.* = value;
    }
    last.* = value;
}

fn isStartOfValue(slice: []const u8, index: usize, value: []const u8) bool {
    const start = index;
    const end = index + value.len;
    if (slice.len <= end) {
        return false;
    }
    return std.mem.eql(u8, slice[start..end], value);
}
