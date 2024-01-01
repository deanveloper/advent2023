const std = @import("std");

pub const Direction = enum {
    North,
    East,
    South,
    West,

    pub fn opposite(self: Direction) Direction {
        return switch (self) {
            .North => .South,
            .East => .West,
            .South => .North,
            .West => .East,
        };
    }
};

pub const PipeType = enum {
    Vertical,
    Horizontal,
    NorthEast,
    NorthWest,
    SouthWest,
    SouthEast,
    Ground,
    Start,

    pub fn fromChar(char: u8) ?PipeType {
        return switch (char) {
            '|' => .Vertical,
            '-' => .Horizontal,
            'L' => .NorthEast,
            'J' => .NorthWest,
            '7' => .SouthWest,
            'F' => .SouthEast,
            '.' => .Ground,
            'S' => .Start,
            else => null,
        };
    }

    pub fn pointingDirections(self: PipeType) ?[2]Direction {
        return switch (self) {
            .Vertical => .{ .North, .South },
            .Horizontal => .{ .East, .West },
            .NorthEast => .{ .North, .East },
            .NorthWest => .{ .North, .West },
            .SouthWest => .{ .South, .West },
            .SouthEast => .{ .South, .East },
            .Ground => null,
            .Start => null,
        };
    }

    pub fn pointsAt(self: PipeType, inDirection: Direction) bool {
        return switch (inDirection) {
            .North => self == .Vertical or self == .NorthWest or self == .NorthEast,
            .East => self == .Horizontal or self == .SouthEast or self == .NorthEast,
            .South => self == .Vertical or self == .SouthWest or self == .SouthEast,
            .West => self == .Horizontal or self == .NorthWest or self == .SouthWest,
        };
    }

    pub fn inferPipeType(north: PipeType, east: PipeType, south: PipeType, west: PipeType) ?PipeType {
        const connectNorth = north.pointsAt(.South);
        const connectEast = east.pointsAt(.West);
        const connectSouth = south.pointsAt(.North);
        const connectWest = west.pointsAt(.East);

        if (connectNorth and connectEast) {
            return .NorthEast;
        }
        if (connectNorth and connectSouth) {
            return .Vertical;
        }
        if (connectNorth and connectWest) {
            return .NorthWest;
        }
        if (connectEast and connectSouth) {
            return .SouthEast;
        }
        if (connectEast and connectWest) {
            return .Horizontal;
        }
        if (connectSouth and connectWest) {
            return .SouthWest;
        }
        return null;
    }
};

pub const Coord = struct { x: i32, y: i32 };

pub const Pipe = struct { coord: Coord, type: PipeType };

pub const Grid = struct {
    alloc: std.mem.Allocator,
    width: usize,
    height: usize,
    start: Coord,
    pipes: []const []const Pipe,

    pub fn fromString(alloc: std.mem.Allocator, string: []const u8) !Grid {
        var lines = std.mem.splitScalar(u8, string, '\n');
        const width = blk: {
            const firstLine = lines.peek() orelse return error.BlankLine;
            break :blk firstLine.len;
        };

        var pipes = std.ArrayList([]const Pipe).init(alloc);
        errdefer {
            for (pipes.items) |line| {
                alloc.free(line);
            }
            pipes.deinit();
        }

        var maybeStartPtr: ?*Pipe = null;
        while (lines.next()) |line| {
            if (line.len == 0) {
                break;
            }
            const pipesThisLine = try alloc.alloc(Pipe, width);
            errdefer alloc.free(pipesThisLine);

            for (0.., pipesThisLine) |x, *pipe| {
                const char = line[x];
                const pipeType = PipeType.fromChar(char) orelse return error.InvalidChar;
                pipe.* = Pipe{
                    .coord = .{ .x = @intCast(x), .y = @intCast(pipes.items.len) },
                    .type = pipeType,
                };
                if (pipe.type == .Start) {
                    if (maybeStartPtr != null) {
                        return error.MultipleStartingPipe;
                    }
                    maybeStartPtr = pipe;
                }
            }
            const finalPipesThisLine = pipesThisLine;
            try pipes.append(finalPipesThisLine);
        }

        const startPtr = maybeStartPtr orelse return error.NoStartingPipe;

        const grid = Grid{
            .alloc = alloc,
            .height = pipes.items.len,
            .start = startPtr.coord,
            .width = width,
            .pipes = try pipes.toOwnedSlice(),
        };

        // assign starting pipe in grid to inferPipeType
        {
            const n = grid.inDirection(startPtr.coord, .North).type;
            const e = grid.inDirection(startPtr.coord, .East).type;
            const s = grid.inDirection(startPtr.coord, .South).type;
            const w = grid.inDirection(startPtr.coord, .West).type;
            startPtr.type = PipeType.inferPipeType(n, e, s, w) orelse return error.CouldNotInferStartPipe;
        }

        return grid;
    }

    pub fn deinit(self: Grid) void {
        for (self.pipes) |row| {
            self.alloc.free(row);
        }
        self.alloc.free(self.pipes);
    }

    pub fn at(self: Grid, coord: Coord) Pipe {
        if (coord.x < 0 or coord.y < 0) {
            return Pipe{ .coord = coord, .type = .Ground };
        }

        const x: usize = @intCast(coord.x);
        const y: usize = @intCast(coord.y);
        if (x >= self.width or y >= self.height) {
            return Pipe{ .coord = coord, .type = .Ground };
        }
        return self.pipes[y][x];
    }

    pub fn insideCornerOfPipe(self: Grid, coord: Coord) ?Pipe {
        const pipe = self.at(coord);
        return switch (pipe.type) {
            .NorthEast => self.at(Coord{ .x = coord.x + 1, .y = coord.y - 1 }),
            .SouthEast => self.at(Coord{ .x = coord.x + 1, .y = coord.y + 1 }),
            .SouthWest => self.at(Coord{ .x = coord.x - 1, .y = coord.y + 1 }),
            .NorthWest => self.at(Coord{ .x = coord.x - 1, .y = coord.y - 1 }),
            else => null,
        };
    }

    pub fn inDirection(self: Grid, coord: Coord, direction: Direction) Pipe {
        return switch (direction) {
            .North => self.at(Coord{ .x = coord.x, .y = coord.y - 1 }),
            .East => self.at(Coord{ .x = coord.x + 1, .y = coord.y }),
            .South => self.at(Coord{ .x = coord.x, .y = coord.y + 1 }),
            .West => self.at(Coord{ .x = coord.x - 1, .y = coord.y }),
        };
    }

    pub fn connections(self: Grid, coord: Coord) ?[2]Pipe {
        const pipe = self.at(coord);
        var result: [2]Pipe = undefined;
        const directions = pipe.type.pointingDirections() orelse return null;
        for (0.., directions) |idx, direction| {
            const pipeInDirection = self.inDirection(coord, direction);
            if (pipeInDirection.type.pointsAt(direction.opposite())) {
                result[idx] = pipeInDirection;
            }
        }

        return result;
    }

    pub fn bfsIterator(self: Grid, start: Coord) !BFSIterator {
        return BFSIterator.init(self.alloc, self, start);
    }

    pub const BFSIterator = struct {
        alloc: std.mem.Allocator,
        grid: Grid,
        visitedFrom: std.AutoHashMap(Pipe, ?Pipe),
        queue: std.DoublyLinkedList(Pipe),

        pub fn init(alloc: std.mem.Allocator, grid: Grid, start: Coord) !BFSIterator {
            var queue = std.DoublyLinkedList(Pipe){};
            var visitedFrom = std.AutoHashMap(Pipe, ?Pipe).init(alloc);
            const startPipe = grid.at(start);

            var firstNode = try alloc.create(std.DoublyLinkedList(Pipe).Node);
            firstNode.data = startPipe;
            queue.append(firstNode);
            try visitedFrom.put(startPipe, null);

            return BFSIterator{
                .alloc = alloc,
                .grid = grid,
                .visitedFrom = visitedFrom,
                .queue = queue,
            };
        }

        pub fn next(self: *BFSIterator) !Pipe {
            const node = self.queue.popFirst() orelse return error.EndOfIter;
            const pipe = node.data;
            self.alloc.destroy(node);

            const otherPipes = self.grid.connections(pipe.coord) orelse return pipe;
            for (otherPipes) |otherPipe| {
                if (!self.visitedFrom.contains(otherPipe)) {
                    const newNode = try self.alloc.create(std.DoublyLinkedList(Pipe).Node);
                    newNode.data = otherPipe;
                    self.queue.append(newNode);
                    try self.visitedFrom.put(otherPipe, pipe);
                }
            }

            return pipe;
        }

        /// deinits the queue and the `seen` set, does not deinit the grid.
        pub fn deinit(self: *BFSIterator) void {
            while (self.queue.pop()) |node| {
                self.alloc.destroy(node);
            }
            self.visitedFrom.deinit();
        }
    };
};
