const std = @import("std");

const Card = enum {
    Joker,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Ten,
    Jack,
    Queen,
    King,
    Ace,

    pub fn format(self: Card, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        return writer.print("{c}", .{self.toChar()});
    }

    fn toChar(self: Card) u8 {
        return switch (self) {
            .Joker => 'J',
            .Two => '2',
            .Three => '3',
            .Four => '4',
            .Five => '5',
            .Six => '6',
            .Seven => '7',
            .Eight => '8',
            .Nine => '9',
            .Ten => 'T',
            .Jack => 'J',
            .Queen => 'Q',
            .King => 'K',
            .Ace => 'A',
        };
    }

    fn fromCharJack(char: u8) !Card {
        return switch (char) {
            '2' => .Two,
            '3' => .Three,
            '4' => .Four,
            '5' => .Five,
            '6' => .Six,
            '7' => .Seven,
            '8' => .Eight,
            '9' => .Nine,
            'T' => .Ten,
            'J' => .Jack,
            'Q' => .Queen,
            'K' => .King,
            'A' => .Ace,
            else => error.InvalidCard,
        };
    }

    fn fromCharJoker(char: u8) !Card {
        return switch (char) {
            'J' => .Joker,
            '2' => .Two,
            '3' => .Three,
            '4' => .Four,
            '5' => .Five,
            '6' => .Six,
            '7' => .Seven,
            '8' => .Eight,
            '9' => .Nine,
            'T' => .Ten,
            'Q' => .Queen,
            'K' => .King,
            'A' => .Ace,
            else => error.InvalidCard,
        };
    }

    fn lessThan(self: Card, rhs: Card) bool {
        return @intFromEnum(self) < @intFromEnum(rhs);
    }
};

// maybe should've made this a union(enum) and stored extra data for the hand - hopefully does not bite me in the ass in part 2
const HandType = enum {
    HighCard,
    OnePair,
    TwoPair,
    ThreeOfAKind,
    FullHouse,
    FourOfAKind,
    FiveOfAKind,

    fn lessThan(self: HandType, rhs: HandType) bool {
        return @intFromEnum(self) < @intFromEnum(rhs);
    }

    fn fromCards(cards: [5]Card) HandType {
        var singles: u8 = 0;
        var pairs: u8 = 0;
        var triples: u8 = 0;
        var quadruples: u8 = 0;

        var cardCounts = std.enums.EnumMultiset(Card).initEmpty();
        for (cards) |card| {
            cardCounts.add(card, 1) catch unreachable;
        }
        const jokers = cardCounts.getCount(Card.Joker);
        cardCounts.removeAll(Card.Joker);

        for (cardCounts.counts.values) |count| {
            switch (count) {
                0 => continue,
                1 => singles += 1,
                2 => pairs += 1,
                3 => triples += 1,
                4 => quadruples += 1,
                5 => return .FiveOfAKind,
                else => unreachable,
            }
        }

        if (quadruples == 1) {
            return if (jokers == 0) .FourOfAKind else .FiveOfAKind;
        }

        if (triples == 1) {
            if (pairs == 1) {
                return .FullHouse;
            } else {
                return switch (jokers) {
                    0 => .ThreeOfAKind,
                    1 => .FourOfAKind,
                    2 => .FiveOfAKind,
                    else => unreachable,
                };
            }
        }
        if (pairs == 2) {
            return if (jokers == 0) .TwoPair else .FullHouse;
        }
        if (pairs == 1) {
            return switch (jokers) {
                0 => .OnePair,
                1 => .ThreeOfAKind,
                2 => .FourOfAKind,
                3 => .FiveOfAKind,
                else => unreachable,
            };
        }
        return switch (jokers) {
            0 => .HighCard,
            1 => .OnePair,
            2 => .ThreeOfAKind,
            3 => .FourOfAKind,
            4 => .FiveOfAKind,
            else => unreachable,
        };
    }
};

const Player = struct {
    index: usize,
    cards: [5]Card,
    bid: u64,

    fn fromLine(index: usize, line: []const u8) !Player {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');

        const cardsStr = tokens.next() orelse return error.NoCards;
        std.debug.assert(cardsStr.len == 5);

        var cards: [5]Card = undefined;
        for (cardsStr, 0..) |char, i| {
            cards[i] = try Card.fromChar(char);
        }

        const bidStr = tokens.next() orelse return error.NoBid;
        const bid = std.fmt.parseInt(u64, bidStr, 10) catch return error.InvalidBid;

        return Player{ .index = index, .cards = cards, .bid = bid };
    }

    fn handLessThan(self: Player, other: Player) bool {
        const selfHandType = HandType.fromCards(self.cards);
        const otherHandType = HandType.fromCards(other.cards);
        if (selfHandType.lessThan(otherHandType)) {
            return true;
        } else if (selfHandType == otherHandType) {
            for (0..5) |i| {
                if (self.cards[i].lessThan(other.cards[i])) {
                    return true;
                } else if (other.cards[i].lessThan(self.cards[i])) {
                    return false;
                }
            }
        }

        return false;
    }

    pub fn format(self: Player, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        _ = try writer.write("cards: {");
        try writer.print(" {}", .{self.cards[0]});
        for (self.cards[1..]) |card| {
            try writer.print(", {}", .{card});
        }
        _ = try writer.write(" }");
        try writer.print(", bid: {}", .{self.bid});
    }
};
