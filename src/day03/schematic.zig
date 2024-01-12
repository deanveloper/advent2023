const std = @import("std");

pub const Schematic = struct {
    pub const Coord = struct { x: usize, y: usize };

    lines: []const []const u8,
    numbers: std.AutoArrayHashMap(Number, void),
    symbols: std.AutoArrayHashMap(Coord, u8),

    pub fn init(allocator: std.mem.Allocator, lines: []const []const u8) !Schematic {
        var schem = Schematic{
            .numbers = std.AutoArrayHashMap(Number, void).init(allocator),
            .symbols = std.AutoArrayHashMap(Coord, u8).init(allocator),
            .lines = lines,
        };

        try schem.initSymbols();
        try schem.initNumbers();

        return schem;
    }

    pub fn deinit(self: *Schematic) void {
        self.numbers.deinit();
        self.symbols.deinit();
    }

    pub const Number = struct {
        value: u32,
        startLocation: Coord,
        len: usize,
    };

    fn initNumbers(self: *Schematic) !void {
        for (0.., self.lines) |y, line| {
            var x: usize = 0;
            while (x < line.len) : (x += 1) {
                const number = self.numberAtRaw(x, y) catch |err| {
                    switch (err) {
                        error.NotANumber => continue,
                        error.OutOfBounds => unreachable,
                    }
                };
                try self.numbers.put(number, {});
                x += number.len - 1;
            }
        }
    }

    fn initSymbols(self: *Schematic) !void {
        for (0.., self.lines) |y, line| {
            var x: usize = 0;
            while (x < line.len) : (x += 1) {
                const symbol = self.symbolAtRaw(x, y) orelse continue;
                try self.symbols.put(.{ .x = x, .y = y }, symbol);
            }
        }
    }

    pub fn charAt(self: Schematic, x: usize, y: usize) ?u8 {
        if (y < 0 or y >= self.lines.len) {
            return null;
        }
        const line = self.lines[y];

        if (x < 0 or x >= line.len) {
            return null;
        }
        return line[x];
    }

    fn numberAtRaw(self: Schematic, x: usize, y: usize) !Number {
        if (y >= self.lines.len) {
            return error.OutOfBounds;
        }
        const line = self.lines[y];
        if (x >= line.len) {
            return error.OutOfBounds;
        }

        const numStart = if (lastIndexOfNonDigit(u8, line[0 .. x + 1])) |idx| idx + 1 else 0;
        const numEnd = indexOfNonDigitPos(u8, line, x) orelse line.len;
        if (numStart >= numEnd) {
            return error.NotANumber;
        }

        const value = std.fmt.parseInt(u32, line[numStart..numEnd], 10) catch return error.NotANumber;
        return Number{ .value = value, .startLocation = Coord{
            .x = numStart,
            .y = y,
        }, .len = numEnd - numStart };
    }

    pub fn numberAt(self: Schematic, x: usize, y: usize) ?Number {
        const keys = self.numbers.keys();
        for (keys) |number| {
            if (number.startLocation.y != y) {
                continue;
            }
            const numStart = number.startLocation.x;
            const numEnd = number.startLocation.x + number.len;
            if (x < numStart or x >= numEnd) {
                continue;
            }

            return number;
        }
        return null;
    }

    fn symbolAtRaw(self: Schematic, x: usize, y: usize) ?u8 {
        switch (self.charAt(x, y) orelse return null) {
            '0'...'9' => return null,
            '.' => return null,
            else => |c| return c,
        }
    }

    pub fn symbolAt(self: Schematic, x: usize, y: usize) ?u8 {
        return self.symbols.get(.{ .x = x, .y = y });
    }

    pub fn numbersAdjacentToSymbol(self: Schematic, x: usize, y: usize, list: *std.AutoArrayHashMap(Number, void)) !void {
        if (self.charAt(x, y) == null) {
            return;
        }

        // check top left
        if (x != 0 and y != 0) {
            const topLeft = self.numberAt(x - 1, y - 1);
            if (topLeft) |num| try list.put(num, {});
        }

        // check top row (excl top left)
        if (y != 0) {
            const top = self.numberAt(x, y - 1);
            if (top) |num| try list.put(num, {});

            const topRight = self.numberAt(x + 1, y - 1);
            if (topRight) |num| try list.put(num, {});
        }

        // check left column (excl top left)
        if (x != 0) {
            const left = self.numberAt(x - 1, y);
            if (left) |num| try list.put(num, {});

            const bottomLeft = self.numberAt(x - 1, y + 1);
            if (bottomLeft) |num| try list.put(num, {});
        }

        // check the rest
        const right = self.numberAt(x + 1, y);
        if (right) |num| try list.put(num, {});

        const bottom = self.numberAt(x, y + 1);
        if (bottom) |num| try list.put(num, {});

        const bottomRight = self.numberAt(x + 1, y + 1);
        if (bottomRight) |num| try list.put(num, {});
    }

    pub fn isSymbolAdjacentToNumber(self: Schematic, number: Number) ?bool {
        const x = number.startLocation.x;
        const y = number.startLocation.y;

        for (x..x + number.len) |charIdx| {
            if (self.charAt(charIdx, y) == null) {
                return null;
            }

            // check top left
            if (x != 0 and y != 0) {
                const topLeft = self.symbolAt(charIdx - 1, y - 1);
                if (topLeft != null) return true;
            }

            // check top row (excl top left)
            if (y != 0) {
                const top = self.symbolAt(charIdx, y - 1);
                if (top != null) return true;

                const topRight = self.symbolAt(charIdx + 1, y - 1);
                if (topRight != null) return true;
            }

            // check left column (excl top left)
            if (x != 0) {
                const left = self.symbolAt(charIdx - 1, y);
                if (left != null) return true;

                const bottomLeft = self.symbolAt(charIdx - 1, y + 1);
                if (bottomLeft != null) return true;
            }

            // check the rest
            const right = self.symbolAt(charIdx + 1, y);
            if (right != null) return true;

            const bottom = self.symbolAt(charIdx, y + 1);
            if (bottom != null) return true;

            const bottomRight = self.symbolAt(charIdx + 1, y + 1);
            if (bottomRight != null) return true;
        }

        return false;
    }
};

fn indexOfNonDigit(comptime T: type, haystack: []const T) ?usize {
    return indexOfNonDigitPos(T, haystack, 0);
}

fn indexOfNonDigitPos(comptime T: type, haystack: []const T, pos: usize) ?usize {
    for (haystack[pos..], pos..) |char, index| {
        if (char < '0' or char > '9') {
            return index;
        }
    }
    return null;
}

fn lastIndexOfNonDigit(comptime T: type, haystack: []const T) ?usize {
    var index = haystack.len;
    while (index != 0) {
        index -= 1;

        const char = haystack[index];
        if (char < '0' or char > '9') {
            return index;
        }
    }
    return null;
}
