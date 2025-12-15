const std = @import("std");
const helpers = @import("../helpers.zig");

const sample =
    \\3-5
    \\10-14
    \\16-20
    \\12-18
    \\
    \\1
    \\5
    \\8
    \\11
    \\17
    \\32
;

const input_path = "input/2025/5.txt";

pub const Range = struct {
    start: u64,
    end: u64,

    pub fn contains(self: @This(), i: u64) bool {
        return self.start <= i and i <= self.end;
    }

    pub fn lessThan(_: void, a: Range, b: Range) bool {
        return a.start < b.start;
    }
};

pub const Kitchen = struct {
    ranges: std.ArrayList(Range),
    ingredients: std.ArrayList(u64),

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.ranges.deinit(allocator);
        self.ingredients.deinit(allocator);
    }

    pub fn freshIngredients(self: @This()) u64 {
        var total: u64 = 0;
        for (self.ingredients.items) |ingredient| {
            ranges: for (self.ranges.items) |range| {
                if (range.contains(ingredient)) {
                    total += 1;
                    break :ranges;
                }
            }
        }
        return total;
    }

    pub fn totalPossibleFresh(self: @This()) u64 {
        var total: u64 = 0;

        const ranges = self.ranges.items;

        var current: ?Range = null;
        for (ranges) |range| {
            if (current == null) {
                current = range;
                continue;
            } else if (range.start > current.?.end) {
                total += current.?.end - current.?.start + 1;
                current = range;
            } else {
                current.?.end = @max(range.end, current.?.end);
            }
        }
        if (current) |c| {
            total += c.end - c.start + 1;
        }

        return total;
    }
};

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Kitchen {
    var ranges = std.ArrayList(Range).empty;
    var ingredients = std.ArrayList(u64).empty;
    errdefer ranges.deinit(allocator);
    errdefer ingredients.deinit(allocator);

    var iter = std.mem.splitSequence(u8, input, "\n\n");
    const ranges_str = iter.first();
    const ingredients_str = iter.rest();

    var ranges_iter = std.mem.splitScalar(u8, ranges_str, '\n');
    while (ranges_iter.next()) |range_str| {
        const cut = std.mem.indexOf(u8, range_str, "-") orelse return error.RangeSeparatorMissing;
        const start = range_str[0..cut];
        const end = range_str[cut + 1 ..];
        try ranges.append(allocator, Range{
            .start = try std.fmt.parseInt(u64, start, 10),
            .end = try std.fmt.parseInt(u64, end, 10),
        });
    }

    var ingredients_iter = std.mem.splitScalar(u8, ingredients_str, '\n');
    while (ingredients_iter.next()) |ingredient_str| {
        try ingredients.append(allocator, try std.fmt.parseInt(u64, ingredient_str, 10));
    }

    std.mem.sort(Range, ranges.items, {}, Range.lessThan);

    return Kitchen{
        .ranges = ranges,
        .ingredients = ingredients,
    };
}

pub fn part1(kitchen: Kitchen) u64 {
    return kitchen.freshIngredients();
}

pub fn part2(kitchen: Kitchen) u64 {
    return kitchen.totalPossibleFresh();
}

test "parse input" {
    const allocator = std.testing.allocator;
    var kitchen = try parseInput(allocator, sample);
    defer kitchen.deinit(allocator);

    try std.testing.expectEqual(4, kitchen.ranges.items.len);
    try std.testing.expectEqual(6, kitchen.ingredients.items.len);
    try std.testing.expectEqual(20, kitchen.ranges.items[3].end);
    try std.testing.expectEqual(16, kitchen.ranges.items[3].start);
    try std.testing.expectEqual(32, kitchen.ingredients.items[5]);
}

test "part 1 sample" {
    const allocator = std.testing.allocator;

    var kitchen = try parseInput(allocator, sample);
    defer kitchen.deinit(allocator);

    const result = part1(kitchen);
    try std.testing.expectEqual(3, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var kitchen = try parseInput(allocator, input);
    defer kitchen.deinit(allocator);

    const result = part1(kitchen);
    try std.testing.expectEqual(517, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;

    var kitchen = try parseInput(allocator, sample);
    defer kitchen.deinit(allocator);

    const result = part2(kitchen);
    try std.testing.expectEqual(14, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var kitchen = try parseInput(allocator, input);
    defer kitchen.deinit(allocator);

    const result = part2(kitchen);
    try std.testing.expectEqual(336_173_027_056_994, result);
}
