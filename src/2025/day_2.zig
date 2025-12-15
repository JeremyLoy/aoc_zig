const std = @import("std");
const helpers = @import("../helpers.zig");

const sample = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

const input_path = "input/2025/2.txt";

pub const Range = struct {
    start: u64,
    end: u64,

    fn sumInvalidIds(self: Range) u64 {
        var sum: u64 = 0;
        for (self.start..self.end + 1) |i_usize| {
            const i: u64 = @intCast(i_usize);
            const num_digits = numDigits(i);
            if (!isEven(num_digits)) {
                continue;
            }
            const half_digits = num_digits / 2;
            const divisor = std.math.pow(u64, 10, half_digits);

            const left = i / divisor;
            const right = i % divisor;
            if (left == right) {
                sum += i;
            }
        }
        return sum;
    }
    fn sumInvalidIds2(self: Range) !u64 {
        var sum: u64 = 0;
        // the most number of base10 digits a u64 can be is 20.
        var buffer: [20]u8 = undefined;
        for (self.start..self.end + 1) |i_usize| {
            const i: u64 = @intCast(i_usize);
            const string_slice = try std.fmt.bufPrint(&buffer, "{}", .{i});
            if (isPeriodic(string_slice)) sum += i;
        }
        return sum;
    }
};

fn numDigits(n: u64) u64 {
    return std.math.log10_int(n) + 1;
}

fn isEven(n: u64) bool {
    return n % 2 == 0;
}

fn isPeriodic(s: []const u8) bool {
    const n = s.len;
    if (n < 2) return false;

    // Check sub-lengths: 1, 2, ..., n/2
    for (1..n / 2 + 1) |len| {
        // Must divide evenly
        if (n % len != 0) continue;

        const pattern = s[0..len];
        var all_match = true;

        // Verify remaining chunks
        var i: usize = len;
        while (i < n) : (i += len) {
            if (!std.mem.eql(u8, s[i .. i + len], pattern)) {
                all_match = false;
                break;
            }
        }

        if (all_match) return true;
    }
    return false;
}

pub fn part1(ranges: []const Range) u64 {
    var sum: u64 = 0;
    for (ranges) |range| {
        sum += range.sumInvalidIds();
    }
    return sum;
}
pub fn part2(ranges: []const Range) !u64 {
    var sum: u64 = 0;
    for (ranges) |range| {
        sum += try range.sumInvalidIds2();
    }
    return sum;
}

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Range) {
    var ranges = std.ArrayList(Range).empty;
    var lines = std.mem.splitScalar(u8, input, ',');

    while (lines.next()) |line| {
        var iter = std.mem.splitScalar(u8, line, '-');
        const start = iter.next() orelse return error.StartNotFound;
        const end = iter.rest();

        const range: Range = .{
            .start = try std.fmt.parseInt(u64, start, 10),
            .end = try std.fmt.parseInt(u64, end, 10),
        };
        try ranges.append(allocator, range);
    }
    return ranges;
}

test "parse input" {
    const allocator = std.testing.allocator;
    var ranges = try parseInput(allocator, sample);
    defer ranges.deinit(allocator);

    try std.testing.expectEqual(11, ranges.items.len);
    try std.testing.expectEqual(Range{ .start = 11, .end = 22 }, ranges.items[0]);
    try std.testing.expectEqual(Range{ .start = 824_824_821, .end = 824_824_827 }, ranges.items[9]);
}

test "part 1 sample" {
    const allocator = std.testing.allocator;

    var ranges = try parseInput(allocator, sample);
    defer ranges.deinit(allocator);

    const result = part1(ranges.items);
    try std.testing.expectEqual(1_227_775_554, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var ranges = try parseInput(allocator, input);
    defer ranges.deinit(allocator);

    const result = part1(ranges.items);
    try std.testing.expectEqual(23_039_913_998, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;

    var ranges = try parseInput(allocator, sample);
    defer ranges.deinit(allocator);

    const result = try part2(ranges.items);
    try std.testing.expectEqual(4_174_379_265, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var ranges = try parseInput(allocator, input);
    defer ranges.deinit(allocator);

    const result = try part2(ranges.items);
    try std.testing.expectEqual(35_950_619_148, result);
}
