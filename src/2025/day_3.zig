const std = @import("std");
const helpers = @import("../helpers.zig");

const sample =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
;

const input_path = "input/2025/3.txt";

pub fn part1(banks: []const []const u64) u64 {
    var sum: u64 = 0;
    for (banks) |bank| {
        sum += largestJoltage(bank, 2);
    }
    return sum;
}

pub fn part2(banks: []const []const u64) !u64 {
    var sum: u64 = 0;
    for (banks) |bank| {
        sum += largestJoltage(bank, 12);
    }
    return sum;
}

fn largestJoltage(bank: []const u64, digits: u64) u64 {
    var sum: u64 = 0;

    var current_digit = digits;
    var window_start: usize = 0;

    while (current_digit > 0) : (current_digit -= 1) {
        const window = bank[window_start .. bank.len - current_digit + 1];

        var current = window[0];

        var new_window_start = window_start + 1;
        for (window, 1..) |battery, i| {
            if (battery > current) {
                current = battery;
                new_window_start = window_start + i;
            }
        }

        const power_exp = current_digit - 1;
        const term = std.math.pow(u64, 10, power_exp);
        sum += current * term;
        window_start = new_window_start;
    }
    return sum;
}

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList([]const u64) {
    var banks = std.ArrayList([]const u64).empty;
    errdefer {
        for (banks.items) |bank| allocator.free(bank);
        banks.deinit(allocator);
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var bank = try allocator.alloc(u64, line.len);
        for (line, 0..) |battery, i| {
            bank[i] = @as(u64, battery - '0');
        }
        try banks.append(allocator, bank);
    }

    return banks;
}

test "parse input" {
    const allocator = std.testing.allocator;
    var banks = try parseInput(allocator, sample);
    defer {
        for (banks.items) |bank| allocator.free(bank);
        banks.deinit(allocator);
    }

    try std.testing.expectEqual(4, banks.items.len);
    try std.testing.expectEqual(9, banks.items[0][0]);
    try std.testing.expectEqual(1, banks.items[3][14]);
}

test "part 1 sample" {
    const allocator = std.testing.allocator;

    var banks = try parseInput(allocator, sample);
    defer {
        for (banks.items) |bank| allocator.free(bank);
        banks.deinit(allocator);
    }

    const result = part1(banks.items);
    try std.testing.expectEqual(357, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var banks = try parseInput(allocator, input);
    defer {
        for (banks.items) |bank| allocator.free(bank);
        banks.deinit(allocator);
    }

    const result = part1(banks.items);
    try std.testing.expectEqual(17_278, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;

    var banks = try parseInput(allocator, sample);
    defer {
        for (banks.items) |bank| allocator.free(bank);
        banks.deinit(allocator);
    }

    const result = try part2(banks.items);
    try std.testing.expectEqual(3_121_910_778_619, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var banks = try parseInput(allocator, input);
    defer {
        for (banks.items) |bank| allocator.free(bank);
        banks.deinit(allocator);
    }

    const result = part2(banks.items);
    try std.testing.expectEqual(171_528_556_468_625, result);
}
