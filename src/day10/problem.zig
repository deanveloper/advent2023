const std = @import("std");
const types = @import("./types.zig");

test "part 1" {
    const alloc = std.testing.allocator;
    const file = @embedFile("./pipes.txt");

    var grid = try types.Grid.fromString(alloc, file);
    defer grid.deinit();

    var bfs = try grid.bfsIterator(grid.start);
    defer bfs.deinit();

    // because it is a breadth-first search, the last pipe iterated on is the furthest
    var furthestPipe: types.Pipe = undefined;
    while (bfs.next()) |pipe| {
        furthestPipe = pipe;
    } else |err| {
        if (err != error.EndOfIter) {
            return err;
        }
    }

    // now, we loop over visitedFrom to see how far we travelled
    var length: u32 = 0;
    var current = furthestPipe;
    while (bfs.visitedFrom.get(current)) |visitedFromOpt| {
        const visitedFrom = visitedFromOpt orelse break;
        current = visitedFrom;
        length += 1;
    }

    try std.testing.expectEqual(@as(u32, 6838), length);
}

test "part 2" {
    const alloc = std.testing.allocator;
    const file = @embedFile("./pipes.txt");

    var grid = try types.Grid.fromString(alloc, file);
    defer grid.deinit();

    // get the pipes that are part of the network of pipes
    var bfs = try grid.bfsIterator(grid.start);
    defer bfs.deinit();
    while (bfs.next()) |_| {} else |_| {} // consume the whole iterator, we just want the set of pipes
    const pipeLine = bfs.visitedFrom;

    // Color the grid. Check if the column used to be inside the line, and flip it whenever horizontal lines are encountered.

    var numInside: u32 = 0;
    var isColumnInside = try alloc.alloc(bool, grid.width);
    var lastCornerInColumn = try alloc.alloc(types.PipeType, grid.width);
    @memset(isColumnInside, false);
    @memset(lastCornerInColumn, types.PipeType.Ground);
    defer alloc.free(isColumnInside);
    defer alloc.free(lastCornerInColumn);

    for (grid.pipes) |line| {
        for (0.., line) |col, pipe| {
            // if this pipe is not part of the border, we should add to numInside if this column is marked as being inside
            if (!pipeLine.contains(pipe)) {
                if (isColumnInside[col]) {
                    numInside += 1;
                }
            } else {
                // if this pipe is part of the border, we should flip the insideness of the column.
                switch (pipe.type) {
                    .Horizontal => {
                        isColumnInside[col] = !isColumnInside[col];
                    },
                    // two corners with opposite horizontal directions is the same as a horizontal line
                    .NorthEast, .SouthEast, .SouthWest, .NorthWest => |pipeType| {
                        // if this there is no previous corner (if this is the "first corner" of the pair), just record that we've seen this and continue the loop.
                        if (lastCornerInColumn[col] == .Ground) {
                            lastCornerInColumn[col] = pipeType;
                            continue;
                        }

                        // if the previously seen corner is opposing this one, we are inside of the pipes now.
                        const lastHorizontalPointingDir = (lastCornerInColumn[col].pointingDirections() orelse unreachable)[1];
                        const thisHorizontalPointingDir = (pipeType.pointingDirections() orelse unreachable)[1];
                        if (lastHorizontalPointingDir != thisHorizontalPointingDir) {
                            isColumnInside[col] = !isColumnInside[col];
                        }
                        // now we've seen two corners, so we should reset the lastCornerInColumn
                        lastCornerInColumn[col] = .Ground;
                    },
                    else => {},
                }
            }
        }
    }
    try std.testing.expectEqual(@as(u32, 451), numInside);
}
