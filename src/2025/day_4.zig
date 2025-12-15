const std = @import("std");
const helpers = @import("../helpers.zig");
const grid = @import("../types/grid.zig");

const sample =
    \\..@@.@@@@.
    \\@@@.@.@.@@
    \\@@@@@.@.@@
    \\@.@@@@..@.
    \\@@.@@@@.@@
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\@.@@@.@@@@
    \\.@@@@@@@@.
    \\@.@.@@@.@.
;

const input_path = "input/2025/4.txt";

pub const Point = struct { x: i32, y: i32 };

fn accessiblePoints(allocator: std.mem.Allocator, accessible_points: *std.ArrayList(Point), rolls: grid.@"2D"(u8)) !void {
    var y: i32 = 0;
    while (y < rolls.height) : (y += 1) {
        var x: i32 = 0;
        while (x < rolls.width) : (x += 1) {
            if (rolls.getCast(x, y) != '@') continue;
            var found: u8 = 0;
            const points = [_]Point{ .{ .x = x + 1, .y = y + 1 }, .{ .x = x + 1, .y = y }, .{ .x = x + 1, .y = y - 1 }, .{ .x = x, .y = y - 1 }, .{ .x = x - 1, .y = y - 1 }, .{ .x = x - 1, .y = y }, .{ .x = x - 1, .y = y + 1 }, .{ .x = x, .y = y + 1 } };
            for (points) |point| {
                if (point.x < 0 or point.y < 0) continue;
                if (rolls.getCast(point.x, point.y) == '@') found += 1;
            }
            if (found < 4) try accessible_points.append(allocator, Point{ .x = x, .y = y });
        }
    }
}

pub fn part1(allocator: std.mem.Allocator, rolls: grid.@"2D"(u8)) !u64 {
    var accessible_points = try std.ArrayList(Point).initCapacity(allocator, rolls.items.len);
    defer accessible_points.deinit(allocator);
    try accessiblePoints(allocator, &accessible_points, rolls);
    return accessible_points.items.len;
}

pub fn part2(allocator: std.mem.Allocator, rolls: *grid.@"2D"(u8)) !u64 {
    var total: u64 = 0;
    var accessible_points = try std.ArrayList(Point).initCapacity(allocator, rolls.items.len);
    defer accessible_points.deinit(allocator);
    while (true) {
        accessible_points.clearAndFree(allocator);
        try accessiblePoints(allocator, &accessible_points, rolls.*);
        if (accessible_points.items.len == 0) {
            break;
        }
        total += accessible_points.items.len;
        for (accessible_points.items) |point| {
            try rolls.set(@as(usize, @intCast(point.x)), @as(usize, @intCast(point.y)), '.');
        }
    }
    return total;
}

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !grid.@"2D"(u8) {
    const width = std.mem.indexOf(u8, input, "\n") orelse return error.NoRowsFound;
    const height = std.mem.count(u8, input, "\n") + 1;

    var rolls = try grid.@"2D"(u8).init(allocator, width, height, null);

    var lines = std.mem.splitScalar(u8, input, '\n');
    var y: usize = 0;
    while (lines.next()) |line| : (y += 1) {
        for (line, 0..) |v, x| {
            try rolls.set(x, y, v);
        }
    }
    return rolls;
}

test "parse input" {
    const allocator = std.testing.allocator;
    var rolls = try parseInput(allocator, sample);
    defer rolls.deinit(allocator);

    try std.testing.expectEqual(10, rolls.height);
    try std.testing.expectEqual(10, rolls.width);
    try std.testing.expectEqual('@', rolls.get(1, 4));
    const x: i32 = 1;
    const y: i32 = 4;
    try std.testing.expectEqual('@', rolls.getCast(x, y));
}

test "part 1 sample" {
    const allocator = std.testing.allocator;

    var rolls = try parseInput(allocator, sample);
    defer rolls.deinit(allocator);

    const result = try part1(allocator, rolls);
    try std.testing.expectEqual(13, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var rolls = try parseInput(allocator, input);
    defer rolls.deinit(allocator);

    const result = try part1(allocator, rolls);
    try std.testing.expectEqual(1_395, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;

    var rolls = try parseInput(allocator, sample);
    defer rolls.deinit(allocator);

    const result = try part2(allocator, &rolls);
    try std.testing.expectEqual(43, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var rolls = try parseInput(allocator, input);
    defer rolls.deinit(allocator);

    const result = try part2(allocator, &rolls);
    try std.testing.expectEqual(8_451, result);
}
