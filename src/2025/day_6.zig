const std = @import("std");
const helpers = @import("../helpers.zig");

const sample = "123 328  51 64 \n 45 64  387 23 \n  6 98  215 314\n*   +   *   +   ";

const input_path = "input/2025/6.txt";

pub const OpSpaceIter = struct {
    buf: []const u8,
    idx: usize = 0,

    pub fn init(buf: []const u8) OpSpaceIter {
        return .{ .buf = buf };
    }

    pub fn next(self: *OpSpaceIter) ?[]const u8 {
        const s = self.buf;
        var i = self.idx;
        const n = s.len;

        // Find next delimiter '*' or '+'
        while (i < n) : (i += 1) {
            const c = s[i];
            if (c == '*' or c == '+') {
                // Found an operator at i; now extend through following spaces
                var j = i + 1;
                while (j < n and s[j] == ' ') : (j += 1) {}
                self.idx = j; // advance iterator
                return s[i..j];
            }
        }

        // No more matches
        self.idx = n;
        return null;
    }
};

pub const Operator = enum { multiply, add };

pub const Problem = struct {
    const Self = @This();
    numbers: []u64,
    operator: Operator,

    pub fn evaluate(self: Self) u64 {
        var total: u64 = if (self.operator == .multiply) 1 else 0;
        for (self.numbers) |number| {
            switch (self.operator) {
                .add => total += number,
                .multiply => total *= number,
            }
        }
        return total;
    }
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.numbers);
        self.* = undefined;
    }
};

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Problem) {
    return parse(allocator, input, false);
}

fn parse(allocator: std.mem.Allocator, input: []const u8, swap: bool) !std.ArrayList(Problem) {
    var lines_iter = std.mem.splitScalar(u8, input, '\n');
    var lines = std.ArrayList([]const u8).empty;
    defer lines.deinit(allocator);
    while (lines_iter.next()) |line| {
        try lines.append(allocator, line);
    }
    var operators = lines.pop() orelse return error.CouldNotPopOperators;
    // account for trailing newline
    while (operators.len == 0) {
        operators = lines.pop() orelse return error.CouldNotPopOperators;
    }

    const capacity = std.mem.countScalar(u8, operators, '+') + std.mem.countScalar(u8, operators, '*');
    var problems = try std.ArrayList(Problem).initCapacity(allocator, capacity);
    errdefer problems.deinit(allocator);
    const lines_count = lines.items.len;
    var operators_iter = OpSpaceIter.init(operators);
    var grid_start: usize = 0;
    while (operators_iter.next()) |operator_str| {
        const width = operator_str.len - 1;
        if (swap) {
            var numbers: []u64 = try allocator.alloc(u64, width);
            errdefer allocator.free(numbers);

            for (grid_start..grid_start + width, 0..) |w, number_idx| {
                var number_str: []u8 = try allocator.alloc(u8, lines_count);
                defer allocator.free(number_str);
                for (0..lines_count) |h| {
                    number_str[h] = lines.items[h][w];
                }
                const trimmed = std.mem.trim(u8, number_str, " ");
                numbers[number_idx] = try std.fmt.parseInt(u64, trimmed, 10);
            }

            try problems.append(allocator, .{
                .numbers = numbers,
                .operator = if (std.meta.eql(operator_str[0], '+')) .add else .multiply,
            });
        } else {
            var numbers: []u64 = try allocator.alloc(u64, lines.items.len);
            errdefer allocator.free(numbers);

            for (0..lines_count) |h| {
                const number_str = lines.items[h][grid_start..grid_start + width];
                const trimmed = std.mem.trim(u8, number_str, " ");
                numbers[h] = try std.fmt.parseInt(u64, trimmed, 10);
            }

            try problems.append(allocator, .{
                .numbers = numbers,
                .operator = if (std.meta.eql(operator_str[0], '+')) .add else .multiply,
            });
        }
        grid_start += width + 1;
    }

    return problems;
}
pub fn parseInput2(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Problem) {
    return parse(allocator, input, true);
}

pub fn part1(problems: []Problem) u64 {
    var total: u64 = 0;
    for (problems) |problem| {
        total += problem.evaluate();
    }
    return total;
}

pub fn part2(problems: []Problem) u64 {
    var total: u64 = 0;
    for (problems) |problem| {
        total += problem.evaluate();
    }
    return total;
}

test "parse input" {
    const allocator = std.testing.allocator;
    var problems = try parseInput(allocator, sample);
    defer {
        for (problems.items) |*problem| {
            problem.deinit(allocator);
        }
        problems.deinit(allocator);
    }

    try std.testing.expectEqual(Operator.multiply, problems.items[0].operator);
    try std.testing.expectEqual(Operator.add, problems.items[1].operator);
    try std.testing.expectEqual(Operator.multiply, problems.items[2].operator);
    try std.testing.expectEqual(Operator.add, problems.items[3].operator);
}

test "part 1 sample" {
    const allocator = std.testing.allocator;
    var problems = try parseInput(allocator, sample);
    defer {
        for (problems.items) |*problem| {
            problem.deinit(allocator);
        }
        problems.deinit(allocator);
    }

    const result = part1(problems.items);
    try std.testing.expectEqual(4_277_556, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var problems = try parseInput(allocator, input);
    defer {
        for (problems.items) |*problem| {
            problem.deinit(allocator);
        }
        problems.deinit(allocator);
    }

    const result = part1(problems.items);
    try std.testing.expectEqual(7_644_505_810_277, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;
    var problems = try parseInput2(allocator, sample);
    defer {
        for (problems.items) |*problem| {
            problem.deinit(allocator);
        }
        problems.deinit(allocator);
    }

    const result = part2(problems.items);
    try std.testing.expectEqual(3_263_827, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var problems = try parseInput2(allocator, input);
    defer {
        for (problems.items) |*problem| {
            problem.deinit(allocator);
        }
        problems.deinit(allocator);
    }

    const result = part2(problems.items);
    try std.testing.expectEqual(12_841_228_084_455, result);
}
