const std = @import("std");

pub const Move = union(enum) {
    Right,
    Left,

    pub fn fromLine(alloc: std.mem.Allocator, line: []const u8) !std.ArrayList(Move) {
        var list = std.ArrayList(Move).init(alloc);
        for (line) |char| {
            try list.append(fromChar(char) orelse return error.BadCharacter);
        }
        return list;
    }

    pub fn fromChar(char: u8) ?Move {
        return switch (char) {
            'R' => .Right,
            'L' => .Left,
            else => return null,
        };
    }
};
pub const Destinations = struct {
    left: []const u8,
    right: []const u8,
};

pub const Network = struct {
    nodes: std.StringHashMap(Destinations),

    pub fn fromLines(alloc: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, std.mem.DelimiterType.scalar)) !Network {
        var network = Network{ .nodes = std.StringHashMap(Destinations).init(alloc) };

        while (lines.next()) |line| {
            var tokens = std.mem.tokenizeAny(u8, line, " =(),");
            const sourceNode = tokens.next() orelse return error.NoSourceNode;
            const leftDest = tokens.next() orelse return error.NoLeftDestNode;
            const rightDest = tokens.next() orelse return error.NoRightDestNode;
            try network.nodes.put(sourceNode, Destinations{ .left = leftDest, .right = rightDest });
        }

        return network;
    }

    pub const NetworkIterator = struct {
        network: Network,
        currentNode: []const u8,
        moves: []const Move,
        moveIdx: usize,

        fn next(self: *NetworkIterator) ![]const u8 {
            const move = self.moves[self.moveIdx];
            const dest = self.network.nodes.get(self.currentNode) orelse return error.NotInNetwork;
            const nextNode = switch (move) {
                .Left => dest.left,
                .Right => dest.right,
            };

            self.moveIdx += 1;
            self.currentNode = nextNode;

            return nextNode;
        }
    };
    pub fn iterator(self: Network, currentNode: []const u8, moves: []const Move) NetworkIterator {
        return NetworkIterator{
            .network = self,
            .currentNode = currentNode,
            .moves = moves,
            .moveIdx = 0,
        };
    }

    pub fn deinit(self: *Network) void {
        self.nodes.deinit();
    }
};

/// used for part 2 - optimization to not need to repeatedly follow nodes once cycles are calculated.
/// i'm now realizing that this would've been way easier with graph theory
const Cycle = struct {
    alloc: std.mem.Allocator,
    start: usize,
    end: usize,
    zList: []const usize,

    fn nextAfter(self: Cycle, index: usize) usize {

        // simple case, just return the first thing larger than `index`
        if (index < self.end) {
            for (self.zList) |z| {
                if (z > index) {
                    return z;
                }
            }
        }

        // otherwise, calculate the offset and use that like the index
        const cycleLen = self.end - self.start;
        const normalizedIndex = (index - self.start) % cycleLen + self.start;
        const cyclesDoneToNormalizeIndex = (index - self.start) / cycleLen;
        for (self.zList) |z| {
            if (z > normalizedIndex) {
                return z + cyclesDoneToNormalizeIndex * cycleLen;
            }
        }

        // otherwise go to the next cycle and return the first thing
        for (self.zList) |z| {
            if (z >= self.start) {
                return z + (cyclesDoneToNormalizeIndex + 1) * cycleLen;
            }
        }

        unreachable;
    }

    fn fromNetwork(alloc: std.mem.Allocator, network: Network, startingNode: []const u8, moves: []Move) !Cycle {
        var cycleStart: usize = undefined;
        var cycleEnd: usize = undefined;

        var arena = std.heap.ArenaAllocator.init(alloc);
        defer arena.deinit();

        var zList = std.ArrayList(usize).init(arena.allocator());
        var startingNodeToMoveCycle = std.StringHashMap(usize).init(arena.allocator());

        var moveLoops: usize = 0;
        var currentNode = startingNode;
        while (true) {

            // break out of the loop when we detect that this node has been used to start a moveCycle before.
            if (startingNodeToMoveCycle.get(currentNode)) |moveCycleSeen| {
                cycleStart = moveCycleSeen * moves.len;
                cycleEnd = moveLoops * moves.len;
                break;
            }

            try startingNodeToMoveCycle.put(currentNode, moveLoops);

            for (0.., moves) |idx, move| {
                // check if this is a Z node
                if (currentNode[currentNode.len - 1] == 'Z') {
                    try zList.append(moveLoops * moves.len + idx);
                }

                const dest = network.nodes.get(currentNode) orelse return error.NotInNetwork;
                currentNode = switch (move) {
                    .Left => dest.left,
                    .Right => dest.right,
                };
            }

            // do moves again
            moveLoops += 1;
        }

        // copy to new slice created with normal (non-arena) allocator
        const zListSlice = try alloc.alloc(usize, zList.items.len);
        @memcpy(zListSlice, zList.items);

        return Cycle{ .alloc = alloc, .start = cycleStart, .end = cycleEnd, .zList = zListSlice };
    }

    fn deinit(self: Cycle) void {
        self.alloc.free(self.zList);
    }
};

test "Cycle.fromNetwork" {
    const netMap = std.StringHashMap(Destinations).init(std.testing.allocator);
    defer netMap.deinit();

    netMap.put("AAA", Destinations{ .left = "ABC", .right = "" });
    netMap.put("ABC", Destinations{ .left = "", .right = "DEF" });
    netMap.put("DEF", Destinations{ .left = "", .right = "LOL" });
    netMap.put("LOL", Destinations{ .left = "", .right = "BFF" });
    netMap.put("BFF", Destinations{ .left = "XYZ", .right = "BFF" });
    netMap.put("XYZ", Destinations{ .left = "", .right = "" });

    const moves = [_]Move{ .Left, .Right, .Right, .Right, .Left };
    _ = moves;

    const network = Network{ .nodes = netMap };
    _ = network;
}

test "Cycle.nextAfter" {
    const testCycle = Cycle{ .zList = &[_]usize{ 5, 8, 12, 15, 23, 26 }, .alloc = std.testing.allocator, .start = 20, .end = 30 };

    try std.testing.expectEqual(@as(usize, 5), testCycle.nextAfter(0));
    try std.testing.expectEqual(@as(usize, 5), testCycle.nextAfter(1));
    try std.testing.expectEqual(@as(usize, 8), testCycle.nextAfter(5));
    try std.testing.expectEqual(@as(usize, 8), testCycle.nextAfter(6));
    try std.testing.expectEqual(@as(usize, 12), testCycle.nextAfter(11));
    try std.testing.expectEqual(@as(usize, 15), testCycle.nextAfter(12));
    try std.testing.expectEqual(@as(usize, 23), testCycle.nextAfter(15));
    try std.testing.expectEqual(@as(usize, 26), testCycle.nextAfter(23));
    try std.testing.expectEqual(@as(usize, 33), testCycle.nextAfter(26));
    try std.testing.expectEqual(@as(usize, 36), testCycle.nextAfter(35));
    try std.testing.expectEqual(@as(usize, 1286), testCycle.nextAfter(1284));
}
