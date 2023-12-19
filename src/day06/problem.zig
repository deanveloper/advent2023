const std = @import("std");

const Race = struct {
    timeLimit: u64,
    recordDistance: u64,
};

fn parseRaces(alloc: std.mem.Allocator, times: []const u8, distances: []const u8) !std.ArrayList(Race) {
    var list = std.ArrayList(Race).init(alloc);
    var timeNumbers = std.mem.tokenizeScalar(u8, times, ' ');
    _ = timeNumbers.next() orelse return error.NoTimePrefix;
    var distanceNumbers = std.mem.tokenizeScalar(u8, distances, ' ');
    _ = distanceNumbers.next() orelse return error.NoDistancePrefix;

    while (distanceNumbers.next()) |distanceStr| {
        const timeStr = timeNumbers.next() orelse return error.NotEnoughTimes;

        const distance = try std.fmt.parseInt(u64, distanceStr, 10);
        const time = try std.fmt.parseInt(u64, timeStr, 10);

        try list.append(Race{ .timeLimit = time, .recordDistance = distance });
    }

    return list;
}

fn parseRaceWithBadKerning(alloc: std.mem.Allocator, times: []const u8, distances: []const u8) !Race {
    var timesList = std.ArrayList(u8).init(alloc);
    var distancesList = std.ArrayList(u8).init(alloc);
    defer timesList.deinit();
    defer distancesList.deinit();

    var timeNumbers = std.mem.tokenizeScalar(u8, times["Time:".len..], ' ');
    var distanceNumbers = std.mem.tokenizeScalar(u8, distances["Distance:".len..], ' ');

    while (timeNumbers.next()) |time| {
        try timesList.appendSlice(time);
    }
    while (distanceNumbers.next()) |distance| {
        try distancesList.appendSlice(distance);
    }

    const time = try std.fmt.parseInt(u64, timesList.items, 10);
    const distance = try std.fmt.parseInt(u64, distancesList.items, 10);

    return Race{ .timeLimit = time, .recordDistance = distance };
}

fn getBoatDistance(holdMs: u64, timeLimit: u64) u64 {
    if (holdMs >= timeLimit) {
        return 0;
    }
    return holdMs * (timeLimit - holdMs);
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = @embedFile("races.txt");
    var lines = std.mem.splitScalar(u8, input, '\n');
    const times = lines.next().?;
    const distances = lines.next().?;

    const races = try parseRaces(alloc, times, distances);
    defer races.deinit();

    var product: u64 = 1;
    for (races.items) |race| {
        var numberOfWaysToWin: u64 = 0;
        for (0..race.timeLimit) |holdMs| {
            const distance = getBoatDistance(holdMs, race.timeLimit);
            if (distance > race.recordDistance) {
                numberOfWaysToWin += 1;
            }
        }
        product *= numberOfWaysToWin;
    }

    try std.testing.expectEqual(@as(u64, 1155175), product);
}

test "part 2" {
    const alloc = std.testing.allocator;
    const input = @embedFile("races.txt");
    var lines = std.mem.splitScalar(u8, input, '\n');
    const times = lines.next().?;
    const distances = lines.next().?;

    const race = try parseRaceWithBadKerning(alloc, times, distances);

    var numberOfWaysToWin: u64 = 0;
    for (0..race.timeLimit) |holdMs| {
        const distance = getBoatDistance(holdMs, race.timeLimit);
        if (distance > race.recordDistance) {
            numberOfWaysToWin += 1;
        }
    }

    try std.testing.expectEqual(@as(u64, 1), numberOfWaysToWin);
}
