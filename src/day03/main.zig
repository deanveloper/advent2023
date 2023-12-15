const std = @import("std");
const deanread = @import("../deanread/read.zig");
const Schematic = @import("./schematic.zig").Schematic;

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
    const schem = try Schematic.init(alloc, lines);

    var sum: u32 = 0;

    for (schem.numbers.keys()) |num| {
        if (schem.isSymbolAdjacentToNumber(num) orelse unreachable) {
            sum += num.value;
        }
    }

    return sum;
}

fn part2(alloc: std.mem.Allocator, lines: []const []const u8) !u32 {
    const schem = try Schematic.init(alloc, lines);

    var sum: u32 = 0;
    for (schem.symbols.keys()) |coord| {
        const symbol = schem.symbols.get(coord) orelse unreachable;
        if (symbol == '*') {
            var list = std.AutoArrayHashMap(Schematic.Number, void).init(alloc);
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
