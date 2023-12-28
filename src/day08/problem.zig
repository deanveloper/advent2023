const std = @import("std");
const types = @import("./network.zig");
const Move = types.Move;
const Destinations = types.Destinations;
const Network = types.Network;
const Cycle = types.Cycle;

test "part 1" {
    const alloc = std.testing.allocator;
    const input = @embedFile("network.txt");
    const parsed = try parseFile(alloc, input);
    const moves = parsed.@"0";
    var network = parsed.@"1";
    defer moves.deinit();
    defer network.deinit();

    var currentNode: []const u8 = "AAA";
    var traversals: usize = 0;
    while (!std.mem.eql(u8, currentNode, "ZZZ")) : (traversals += 1) {
        const dest = network.nodes.get(currentNode) orelse return error.NotInNetwork;
        currentNode = switch (moves.items[traversals % moves.items.len]) {
            .Left => dest.left,
            .Right => dest.right,
        };
    }

    try std.testing.expectEqual(@as(usize, 24253), traversals);
}

test "part 2" {
    const alloc = std.testing.allocator;
    const input = @embedFile("network.txt");
    const parsed = try parseFile(alloc, input);
    const moves = parsed.@"0";
    var network = parsed.@"1";
    defer moves.deinit();
    defer network.deinit();

    var paths = std.StringArrayHashMap(Cycle).init(alloc);
    defer {
        for (paths.values()) |value| {
            value.deinit();
        }
        paths.deinit();
    }

    // init nodeCycles
    var keys = network.nodes.keyIterator();
    while (keys.next()) |nodePtr| {
        const node = nodePtr.*;
        if (node[node.len - 1] == 'A') {
            const cycle = try Cycle.fromNetwork(alloc, network, node, moves.items); // alloc cleaned up when cleaning up nodeCycles
            try paths.put(node, cycle);
        }
    }

    var currentNavigations: usize = 0;
    while (true) {
        // keep going until all of them equal the same number
        var minNextNavs: usize = std.math.maxInt(usize);
        var pathsNavigatingToMinNextNavs: usize = 0;
        for (paths.values()) |cycle| {
            const next = cycle.nextAfter(currentNavigations);
            if (next < minNextNavs) {
                minNextNavs = next;
                pathsNavigatingToMinNextNavs = 0;
            }
            if (next == minNextNavs) {
                pathsNavigatingToMinNextNavs += 1;
            }
        }

        currentNavigations = minNextNavs;

        // if all paths are navigating to a valid destination, we can break out :)
        if (pathsNavigatingToMinNextNavs == paths.count()) {
            break;
        }
    }

    try std.testing.expectEqual(@as(usize, 12357789728873), currentNavigations);
}

fn parseFile(alloc: std.mem.Allocator, input: []const u8) !struct { std.ArrayList(Move), Network } {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    const moveStr = lines.next() orelse return error.NoMoves;
    const moves = try Move.fromLine(alloc, moveStr);
    const network = try Network.fromLines(alloc, &lines);
    return .{ moves, network };
}
