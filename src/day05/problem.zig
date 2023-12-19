const std = @import("std");

test "part 1" {
    const alloc = std.testing.allocator;

    const problem = @embedFile("./almanac.txt");
    var lineIter = std.mem.splitScalar(u8, problem, '\n');

    const almanac = try Almanac.fromLineIter(alloc, &lineIter);
    defer almanac.deinit();

    var minLocation: u64 = std.math.maxInt(u64);
    var minLocationSeed: u64 = std.math.maxInt(u64);
    for (almanac.seeds.items) |seed| {
        const rangeResult = almanac.resolveLocationOfSeed(seed);
        if (rangeResult.value < minLocation) {
            minLocation = rangeResult.value;
            minLocationSeed = seed;
        }
    }

    try std.testing.expectEqual(@as(u64, 111627841), minLocation);
}

test "part 2" {
    const alloc = std.testing.allocator;

    const problem = @embedFile("./almanac.txt");
    var lineIter = std.mem.splitScalar(u8, problem, '\n');

    const almanac = try Almanac.fromLineIter(alloc, &lineIter);
    defer almanac.deinit();

    var minLocation: u64 = std.math.maxInt(u64);
    var minLocationSeed: u64 = std.math.maxInt(u64);

    var seedRangeStartIdx: usize = 0;
    while (seedRangeStartIdx < almanac.seeds.items.len) : (seedRangeStartIdx += 2) {
        const seedRangeStart = almanac.seeds.items[seedRangeStartIdx];
        const seedRangeEnd = seedRangeStart + almanac.seeds.items[seedRangeStartIdx + 1];

        var seed = seedRangeStart;
        while (seed < seedRangeEnd) {
            const rangeResult = almanac.resolveLocationOfSeed(seed);
            if (rangeResult.value < minLocation) {
                minLocation = rangeResult.value;
                minLocationSeed = seed;
            }
            seed += rangeResult.nextRangeChange;
        }
    }

    try std.testing.expectEqual(@as(u64, 1), minLocation);
}

pub const Resource = enum {
    seed,
    soil,
    fertilizer,
    water,
    light,
    temperature,
    humidity,
    location,

    pub const len = @typeInfo(Resource).Enum.fields.len;

    pub fn fromString(str: []const u8) !Resource {
        for (@typeInfo(Resource).Enum.fields) |field| {
            if (std.mem.eql(u8, str, field.name)) {
                return field.value;
            }
        }
    }
};

pub const MappingRange = struct {
    destStart: u64,
    srcStart: u64,
    len: u64,

    pub fn fromString(str: []const u8) !MappingRange {
        var tokens = std.mem.tokenizeScalar(u8, str, ' ');
        const destStartStr = tokens.next() orelse return error.NoDestStart;
        const srcStartStr = tokens.next() orelse return error.NoSrcStart;
        const lenStr = tokens.next() orelse return error.NoLen;

        const destStart = std.fmt.parseInt(u64, destStartStr, 10) catch return error.DestStartNotANumber;
        const srcStart = std.fmt.parseInt(u64, srcStartStr, 10) catch return error.SrcStartNotANumber;
        const len = std.fmt.parseInt(u64, lenStr, 10) catch return error.LenNotANumber;

        return MappingRange{
            .destStart = destStart,
            .srcStart = srcStart,
            .len = len,
        };
    }

    pub fn resolve(self: MappingRange, src: u64) ?u64 {
        if (self.srcStart <= src and src < self.srcStart + self.len) {
            if (self.srcStart > self.destStart) {
                return src - (self.srcStart - self.destStart);
            } else {
                return src + (self.destStart - self.srcStart);
            }
        }
        return null;
    }
};

const RangeResult = struct {
    /// the result of the range
    value: u64,
    /// difference between current input and next range change
    nextRangeChange: u64,
};

pub const Mapping = struct {
    ranges: std.ArrayList(MappingRange),

    pub fn fromLineIter(alloc: std.mem.Allocator, lineIter: *std.mem.SplitIterator(u8, .scalar)) !Mapping {
        // consume "src-to-dest map:" line
        _ = lineIter.next() orelse return error.NoSrcToDestLine;

        var ranges = std.ArrayList(MappingRange).init(alloc);

        while (true) {
            const line = lineIter.next() orelse "";
            if (line.len == 0) {
                break;
            }
            try ranges.append(try MappingRange.fromString(line));
        }

        return Mapping{
            .ranges = ranges,
        };
    }

    pub fn deinit(self: Mapping) void {
        self.ranges.deinit();
    }

    pub fn resolve(self: Mapping, resourceId: u64) RangeResult {
        for (self.ranges.items) |range| {
            if (range.resolve(resourceId)) |destId| {
                return RangeResult{ .value = destId, .nextRangeChange = range.srcStart + range.len - resourceId };
            }
        }

        // any source numbers that aren't mapped correspond to the same destination number.
        var nextRangeChange: u64 = std.math.maxInt(u64);
        for (self.ranges.items) |range| {
            if (range.srcStart > resourceId and range.srcStart < nextRangeChange) {
                nextRangeChange = range.srcStart;
            }
        }
        return RangeResult{ .value = resourceId, .nextRangeChange = nextRangeChange - resourceId };
    }
};

pub const Almanac = struct {
    seeds: std.ArrayList(u64),
    mappings: [Resource.len - 1]Mapping,

    pub fn fromLineIter(alloc: std.mem.Allocator, lineIter: *std.mem.SplitIterator(u8, .scalar)) !Almanac {
        const firstLine = lineIter.first();
        const prefixLen = "seeds: ".len;
        const seedsStr = firstLine[prefixLen..];
        var seeds = std.ArrayList(u64).init(alloc);
        var seedStrIter = std.mem.tokenizeScalar(u8, seedsStr, ' ');
        while (seedStrIter.next()) |seedStr| {
            const seed = std.fmt.parseInt(u64, seedStr, 10) catch return error.SeedNotANumber;
            try seeds.append(seed);
        }

        _ = lineIter.next(); // consume empty line

        var mappings: [Resource.len - 1]Mapping = undefined;
        for (0..Resource.len - 1) |i| {
            mappings[i] = try Mapping.fromLineIter(alloc, lineIter);
        }

        return Almanac{
            .seeds = seeds,
            .mappings = mappings,
        };
    }

    pub fn deinit(self: Almanac) void {
        self.seeds.deinit();
        for (self.mappings) |mapping| {
            mapping.deinit();
        }
    }

    pub fn resolveLocationOfSeed(self: Almanac, seedId: u64) RangeResult {
        var rangeResult = self.mappings[0].resolve(seedId);
        var minimumRangeChange = rangeResult.nextRangeChange;
        inline for (self.mappings[1..], 2..) |mapping, i| {
            _ = i;

            rangeResult = mapping.resolve(rangeResult.value);
            if (rangeResult.nextRangeChange < minimumRangeChange) {
                minimumRangeChange = rangeResult.nextRangeChange;
            }
        }
        return RangeResult{ .value = rangeResult.value, .nextRangeChange = minimumRangeChange };
    }
};
