const std = @import("std");
const deanread = @import("../deanread/read.zig");

test "part 1" {
    const content = @embedFile("./cards.txt");
    var points: u32 = 0;
    var linesIter = std.mem.splitScalar(u8, content, '\n');
    while (linesIter.next()) |line| {
        var card = Card.fromLine(line) catch continue;
        points += card.points();
    }
    try std.testing.expectEqual(@as(u32, 20855), points);
}

test "part 2" {
    const content = @embedFile("./cards.txt");

    const alloc = std.heap.page_allocator;

    // store list of all cards
    var allCards = std.ArrayList(Card).init(alloc);
    defer allCards.deinit();
    var linesIter = std.mem.splitScalar(u8, content, '\n');
    while (linesIter.next()) |line| {
        try allCards.append(Card.fromLine(line) catch continue);
    }

    // play game
    // i realize that i could've probably just used a hashmap to count
    // how many copies of each card i have, but this is way more fun
    const CardList = std.DoublyLinkedList(Card);
    var cards = CardList{};

    // add original cards
    for (allCards.items) |card| {
        const node = try alloc.create(CardList.Node);
        node.data = card;
        cards.append(node);
    }

    var scratchCards: u32 = 0;
    while (cards.popFirst()) |popped| {
        const card = popped.data;
        alloc.destroy(popped);

        scratchCards += 1;
        const firstCardToAdd = card.id + 1;
        const lastCardToAddExcl = firstCardToAdd + card.winningNumbers();
        for (firstCardToAdd..lastCardToAddExcl) |cardToAdd| {
            var node = try alloc.create(CardList.Node);
            node.data = allCards.items[cardToAdd - 1];
            cards.append(node);
        }
    }

    try std.testing.expectEqual(@as(u32, 5489600), scratchCards);
}

fn part2(alloc: std.mem.Allocator, lines: []const []const u8) !u32 {
    _ = alloc;
    _ = lines;
    return 0;
}

const Card = struct {
    id: usize,
    winning: [10]u8,
    player: [25]u8,

    pub fn fromLine(line: []const u8) !Card {
        if (line.len != 116) {
            return error.InvalidLine;
        }
        const id = try std.fmt.parseInt(usize, std.mem.trimLeft(u8, line[5..8], " "), 10);
        // winning numbers
        const winning = try parseNumbers(line[10..40], 10);
        const player = try parseNumbers(line[42..116], 25);

        var card = Card{
            .id = id,
            .winning = winning,
            .player = player,
        };
        card.sortNumbers();

        return card;
    }

    pub fn points(self: Card) u32 {
        const winningPlayerNumbers = self.winningNumbers();
        if (winningPlayerNumbers == 0) {
            return 0;
        }
        return std.math.powi(u32, 2, winningPlayerNumbers - 1) catch unreachable;
    }

    fn sortNumbers(self: *Card) void {
        std.mem.sort(u8, &self.winning, {}, std.sort.asc(u8));
        std.mem.sort(u8, &self.player, {}, std.sort.asc(u8));
    }

    // assumes the list is sorted
    pub fn winningNumbers(self: Card) u32 {
        var winning: u32 = 0;
        var wIndex: usize = 0;
        var pIndex: usize = 0;

        while (wIndex < self.winning.len and pIndex < self.player.len) {
            if (self.winning[wIndex] > self.player[pIndex]) {
                pIndex += 1;
                continue;
            }
            if (self.player[pIndex] > self.winning[wIndex]) {
                wIndex += 1;
                continue;
            }
            if (self.player[pIndex] == self.winning[wIndex]) {
                pIndex += 1;
                winning += 1;
                continue;
            }
        }

        return winning;
    }

    fn parseNumbers(str: []const u8, comptime num: usize) ![num]u8 {
        var numbers: [num]u8 = undefined;
        for (0..num) |index| {
            const numStart = index * 3;
            const numString = std.mem.trimLeft(u8, str[numStart .. numStart + 2], " ");
            const number = try std.fmt.parseInt(u8, numString, 10);
            numbers[index] = number;
        }
        return numbers;
    }
};
