const std = @import("std");
const helpers = @import("../helpers.zig");
const grid = @import("../types/grid.zig");

const sample =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
;

const input_path = "input/2025/9.txt";

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !struct { std.ArrayList(grid.Rectangle), std.ArrayList(grid.Rectangle) } {
    var points = std.ArrayList(grid.Point2D(i64)).empty;
    defer points.deinit(allocator);
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const x, const y = std.mem.cutScalar(u8, line, ',') orelse return error.CutNotFound;
        try points.append(allocator, grid.Point2D(i64){
            .x = try std.fmt.parseInt(i64, x, 10),
            .y = try std.fmt.parseInt(i64, y, 10),
        });
    }
    var rectangles = std.ArrayList(grid.Rectangle).empty;
    errdefer rectangles.deinit(allocator);
    for (points.items[0 .. points.items.len - 1]) |a| {
        for (points.items[1..]) |b| {
            try rectangles.append(allocator, grid.Rectangle.init(a, b));
        }
    }
    std.mem.sort(grid.Rectangle, rectangles.items, {}, grid.Rectangle.lessThanArea);
    std.mem.reverse(grid.Rectangle, rectangles.items);

    var perimeter = std.ArrayList(grid.Rectangle).empty;
    for (points.items[0 .. points.items.len - 1], points.items[1..]) |a, b| {
        try perimeter.append(allocator, grid.Rectangle.init(a, b));
    }
    try perimeter.append(allocator, grid.Rectangle.init(points.getLast(), points.items[0]));

    return .{ rectangles, perimeter };
}

pub fn part1(rectangles: []grid.Rectangle) i64 {
    return rectangles[0].area;
}

pub fn part2(red_tiles: []grid.Rectangle, perimeter: []grid.Rectangle) i64 {
    red: for (red_tiles) |red_tile| {
        const shrunk = red_tile.shrink();
        for (perimeter) |point| {
            if (point.overlaps(shrunk)) continue :red;
        }
        return red_tile.area;
    }
    return 0;
}

test "part 1 sample" {
    const allocator = std.testing.allocator;
    var rectangles, var perimeter = try parseInput(allocator, sample);
    defer rectangles.deinit(allocator);
    defer perimeter.deinit(allocator);

    const result = part1(rectangles.items);
    try std.testing.expectEqual(50, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var rectangles, var perimeter = try parseInput(allocator, input);
    defer rectangles.deinit(allocator);
    defer perimeter.deinit(allocator);

    const result = part1(rectangles.items);
    try std.testing.expectEqual(4_755_429_952, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;
    var rectangles, var perimeter = try parseInput(allocator, sample);
    defer rectangles.deinit(allocator);
    defer perimeter.deinit(allocator);

    const result = part2(rectangles.items, perimeter.items);
    try std.testing.expectEqual(24, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var rectangles, var perimeter = try parseInput(allocator, input);
    defer rectangles.deinit(allocator);
    defer perimeter.deinit(allocator);

    const result = part2(rectangles.items, perimeter.items);
    try std.testing.expectEqual(1_429_596_008, result);
}
