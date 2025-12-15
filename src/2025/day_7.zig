const std = @import("std");
const helpers = @import("../helpers.zig");
const grid = @import("../types/grid.zig");
const types = @import("../types/types.zig");

const sample =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
;

const input_path = "input/2025/7.txt";

const ManifoldPoint = enum {
    const Self = @This();
    start,
    beam,
    splitter,
    empty,

    pub fn parse(s: u8) !Self {
        return switch (s) {
            'S' => .start,
            '|' => .beam,
            '^' => .splitter,
            '.' => .empty,
            else => return error.UnknownManifoldPoint,
        };
    }

    pub fn format(
        self: Self,
        writer: anytype,
    ) !void {
        switch (self) {
            .start => {
                try writer.print("S", .{});
            },
            .beam => {
                try writer.print("|", .{});
            },
            .splitter => {
                try writer.print("^", .{});
            },
            .empty => {
                try writer.print(".", .{});
            },
        }
    }
};

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !grid.@"2D"(ManifoldPoint) {
    const height = std.mem.count(u8, input, "\n") + 1;
    const width = std.mem.indexOf(u8, input, "\n") orelse return error.CouldNotDetermineWidth;
    var g = try grid.@"2D"(ManifoldPoint).init(allocator, width, height, null);
    errdefer g.deinit(allocator);
    var rows = std.mem.splitScalar(u8, input, '\n');

    var y: usize = 0;
    while (rows.next()) |row| : (y += 1) {
        for (row, 0..) |c, x| {
            try g.set(x, y, try ManifoldPoint.parse(c));
        }
    }
    return g;
}

pub fn part1(allocator: std.mem.Allocator, manifold: *grid.@"2D"(ManifoldPoint)) !u64 {
    var queue = types.RingBuffer(grid.Point2D(isize)).empty;
    defer queue.deinit(allocator);
    const start = manifold.findPoint(.start) orelse return error.CouldNotFindStart;
    try queue.enqueue(allocator,  start);
    var splitters: u64 = 0;
    var current = queue.dequeue();
    queue: while (current) |c| : (current = queue.dequeue()) {
        var next = grid.Point2D(isize){ .x = c.x, .y = c.y + 1 };
        while (manifold.inBoundsPoint(next)) : (next.y += 1) {
            switch (manifold.getPoint(next).?) {
                .empty => {
                    try manifold.setPoint(next, .beam);
                },
                .splitter => {
                    splitters += 1;
                    try queue.enqueue(allocator, grid.Point2D(isize){ .x = next.x - 1, .y = next.y });
                    try queue.enqueue(allocator,  grid.Point2D(isize){ .x = next.x + 1, .y = next.y });
                    continue :queue;
                },
                .start => return error.EncounteredSecondStart,
                .beam => continue :queue,
            }
        }
    }

    return splitters;
}
fn recur(p: grid.Point2D(isize), manifold: grid.@"2D"(ManifoldPoint), memo: *std.AutoHashMap(grid.Point2D(isize), u64)) !u64 {
    var next = grid.Point2D(isize){ .x = p.x, .y = p.y + 1 };
    while (manifold.inBoundsPoint(next)) : (next.y += 1) {
        if (memo.get(next)) |cached| {
            return cached;
        }
        switch (manifold.getPoint(next).?) {
            .empty, .beam => continue,
            .splitter => {
                const left = grid.Point2D(isize){ .x = next.x - 1, .y = next.y };
                const right = grid.Point2D(isize){ .x = next.x + 1, .y = next.y };
                var total: u64 = 0;
                if (manifold.inBoundsPoint(left)) {
                    total += try recur(left, manifold, memo);
                }
                if (manifold.inBoundsPoint(right)) {
                    total += try recur(right, manifold, memo);
                }
                try memo.put(next, total);
                return total;
            },
            .start => return error.EncounteredSecondStart,
        }
    }
    return 1;
}
pub fn part2(allocator: std.mem.Allocator, manifold: grid.@"2D"(ManifoldPoint)) !u64 {
    var memo = std.AutoHashMap(grid.Point2D(isize),u64).init(allocator);
    defer memo.deinit();
    const start = manifold.findPoint(.start) orelse return error.CouldNotFindStart;
    return recur(start, manifold, &memo);
}

test "parse input" {
    const allocator = std.testing.allocator;
    var manifold = try parseInput(allocator, sample);
    defer manifold.deinit(allocator);

    try std.testing.expectEqual(grid.Point2D(isize){ .x = 7, .y = 0 }, manifold.findPoint(.start));
}

test "part 1 sample" {
    const allocator = std.testing.allocator;
    var manifold = try parseInput(allocator, sample);
    defer manifold.deinit(allocator);

    const result = try part1(allocator, &manifold);
    try std.testing.expectEqual(21, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var manifold = try parseInput(allocator, input);
    defer manifold.deinit(allocator);

    const result = try part1(allocator, &manifold);
    try std.testing.expectEqual(1_698, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;
    var manifold = try parseInput(allocator, sample);
    defer manifold.deinit(allocator);

    const result = try part2(allocator, manifold);
    try std.testing.expectEqual(40, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var manifold = try parseInput(allocator, input);
    defer manifold.deinit(allocator);

    const result = try part2(allocator, manifold);
    try std.testing.expectEqual(95_408_386_769_474, result);
}
