const std = @import("std");
const deanread = @import("dean");
const Schematic = @import("./schematic.zig").Schematic;

test "legacy" {
    const alloc = std.testing.allocator;
    const content = try deanread.readFromExe(alloc, "day03.txt");
    defer alloc.free(content);

    var lines = std.ArrayList([]const u8).init(alloc);
    defer lines.deinit();

    var linesIter = std.mem.splitScalar(u8, content, '\n');
    while (linesIter.next()) |line| {
        try lines.append(line);
    }

    const answer = try part2(alloc, lines.items);
    try std.testing.expectEqual(@as(u32, 78826761), answer);
}

fn part1(alloc: std.mem.Allocator, lines: []const []const u8) !u32 {
    var schem = try Schematic.init(alloc, lines);
    defer schem.deinit();

    var sum: u32 = 0;

    for (schem.numbers.keys()) |num| {
        if (schem.isSymbolAdjacentToNumber(num) orelse unreachable) {
            sum += num.value;
        }
    }

    return sum;
}

fn part2(alloc: std.mem.Allocator, lines: []const []const u8) !u32 {
    var schem = try Schematic.init(alloc, lines);
    defer schem.deinit();

    var sum: u32 = 0;
    for (schem.symbols.keys()) |coord| {
        const symbol = schem.symbols.get(coord) orelse unreachable;
        if (symbol == '*') {
            var list = std.AutoArrayHashMap(Schematic.Number, void).init(alloc);
            defer list.deinit();
            try schem.numbersAdjacentToSymbol(coord.x, coord.y, &list);

            if (list.count() >= 2) {
                var product: u32 = 1;
                for (list.keys()) |number| {
                    product *= number.value;
                }
                sum += product;
            }
        }
    }

    return sum;
}
