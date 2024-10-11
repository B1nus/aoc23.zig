const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const day = @src().file[0..1];
    const input = @embedFile(day ++ ".txt");
    var sum: usize = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var hands = [_][5]u8{undefined} ** 1000;
    var bids = [_]usize{0} ** hands.len;
    var hand_i: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) break;
        std.mem.copyForwards(u8, &hands[hand_i], line[0..5]);
        bids[hand_i] = try std.fmt.parseInt(usize, line[6..], 10);
        hand_i += 1;
    }

    for (hands, bids, 0..) |hand, bid, i| {
        var rank: usize = 1;
        for (hands, 0..) |opp_hand, opponent_i| {
            if (i != opponent_i and left_side_wins(&hand, &opp_hand)) {
                rank += 1;
            }
        }
        sum += rank * bid;
    }

    std.debug.print("Day " ++ day ++ " -> {d}\n", .{sum});
}

pub fn left_side_wins(hand: []const u8, opponent: []const u8) bool {
    const strength = hand_strength(hand);
    const opponent_strength = hand_strength(opponent);

    if (strength == opponent_strength) {
        for (hand, opponent) |card, opp_card| {
            const val = evaluate_card(card);
            const opp_val = evaluate_card(opp_card);
            if (val > opp_val) {
                return true;
            } else if (opp_val > val) {
                return false;
            }
        }
    }

    return strength > opponent_strength;
}

pub fn hand_strength(hand: []const u8) usize {
    const card_counts = count_cards(hand);
    const sorted_counts = sort_card_counts(card_counts);
    return switch (sorted_counts[0]) {
        5 => 6,
        4 => 5,
        3 => if (sorted_counts[1] == 2) 4 else 3,
        2 => if (sorted_counts[1] == 2) 2 else 1,
        else => 0,
    };
}

pub fn sort_card_counts(counts: [13]usize) [5]usize {
    var amounts = counts;
    var amount_ranking = [_]usize{0} ** 5;
    for (&amount_ranking) |*rank| {
        var max: usize = 0;
        var max_i: usize = 0;
        for (amounts, 0..) |amount, i| {
            if (amount > max) {
                max = amount;
                max_i = i;
            }
        }
        rank.* = max;
        amounts[max_i] = 0;
    }
    return amount_ranking;
}

pub fn count_cards(hand: []const u8) [13]usize {
    var amounts = [_]usize{0} ** 13;
    for (hand) |c| {
        amounts[evaluate_card(c)] += 1;
    }
    return amounts;
}

pub fn evaluate_card(card: u8) usize {
    return switch (card) {
        '2'...'9' => card - 50,
        'T' => 8,
        'J' => 9,
        'Q' => 10,
        'K' => 11,
        'A' => 12,
        else => unreachable,
    };
}

const expect = std.testing.expect;
const eql = std.mem.eql;

test "card_counts" {
    try expect(eql(usize, &count_cards("23456789TJQKA"), &[_]usize{1} ** 13));
    try expect(eql(usize, &count_cards("23456TJQKA"), &([_]usize{1} ** 5 ++ [_]usize{0} ** 3 ++ [_]usize{1} ** 5)));
    try expect(eql(usize, &count_cards("2"), &[_]usize{1} ++ [_]usize{0} ** 12));
}

test "count_ranking" {
    try expect(eql(usize, &sort_card_counts(count_cards("23456")), &[_]usize{1} ** 5));
    try expect(eql(usize, &sort_card_counts(count_cards("22333")), &[_]usize{ 3, 2, 0, 0, 0 }));
    try expect(eql(usize, &sort_card_counts(count_cards("22345")), &[_]usize{ 2, 1, 1, 1, 0 }));
}

test "strength" {
    try expect(hand_strength("AAQQQ") == 4);
    try expect(hand_strength("QAQAA") == 4);
    try expect(hand_strength("22222") == 6);
    try expect(hand_strength("22242") == 5);
    try expect(hand_strength("QAQAA") == 4);
    try expect(hand_strength("27877") == 3);
    try expect(hand_strength("99866") == 2);
    try expect(hand_strength("2A32Q") == 1);
    try expect(hand_strength("QJAK2") == 0);
}

test "winner" {
    try expect(left_side_wins("33332", "2AAAA"));
    try expect(left_side_wins("77888", "77788"));
    try expect(left_side_wins("KK677", "KTJJT"));
}
