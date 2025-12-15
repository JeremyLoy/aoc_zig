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

fn add(allocator: std.mem.Allocator, perimeter: *std.AutoHashMapUnmanaged(grid.Point2D(i64), void), lhs: grid.Point2D(i64), rhs: grid.Point2D(i64)) !void {
    const dx: i64 = @intCast(@abs(lhs.x - rhs.x));
    const dy: i64 = @intCast(@abs(lhs.y - rhs.y));
    const sx: i64 = if (lhs.x < rhs.x) 1 else -1;
    const sy: i64 = if (lhs.y < rhs.y) 1 else -1;
    var e = dx - dy;

    var x = lhs.x;
    var y = lhs.y;
    try perimeter.put(allocator, grid.Point2D(i64){ .x = rhs.x, .y = rhs.y }, {});
    while (x != rhs.x or y != rhs.y) {
        try perimeter.put(allocator, grid.Point2D(i64){ .x = x, .y = y }, {});
        const e2 = 2 * e;

        if (e2 > -dy) {
            e = e - dy;
            x = x + sx;
        }
        if (e2 < dx) {
            e = e + dx;
            y = y + sy;
        }
    }
}

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(grid.Point2D(i64)) {
    var points = std.ArrayList(grid.Point2D(i64)).empty;
    errdefer points.deinit(allocator);
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const x, const y = std.mem.cutScalar(u8, line, ',') orelse return error.CutNotFound;
        try points.append(allocator, grid.Point2D(i64){
            .x = try std.fmt.parseInt(i64, x, 10),
            .y = try std.fmt.parseInt(i64, y, 10),
        });
    }

    return points;
}

pub fn part1(points: []grid.Point2D(i64)) u64 {
    var largest_area: u64 = 0;
    for (points[0 .. points.len - 1]) |lhs| {
        for (points[1..]) |rhs| {
            const current_area = @abs(lhs.x - rhs.x + 1) * @abs(lhs.y - rhs.y + 1);
            largest_area = @max(largest_area, current_area);
        }
    }
    return largest_area;
}

pub const AreaAndPair = struct {
    area: u64,
    lhs: grid.Point2D(i64),
    rhs: grid.Point2D(i64),

    pub fn lessThan(_: void, a: AreaAndPair, b: AreaAndPair) bool {
        return a.area < b.area;
    }
};

pub fn part2(allocator: std.mem.Allocator, red_tiles: []grid.Point2D(i64)) !u64 {
    var perimeter = std.AutoHashMap(grid.Point2D(i64), void).Unmanaged{};
    var working_perimeter = std.AutoHashMap(grid.Point2D(i64), void).Unmanaged{};
    var area_and_pairs = std.ArrayList(AreaAndPair).empty;
    defer perimeter.deinit(allocator);
    defer working_perimeter.deinit(allocator);
    defer area_and_pairs.deinit(allocator);

    for (red_tiles[0 .. red_tiles.len - 1], red_tiles[1..]) |lhs, rhs| {
        try add(allocator, &perimeter, lhs, rhs);
    }
    try add(allocator, &perimeter, red_tiles[red_tiles.len - 1], red_tiles[0]);

    for (red_tiles[0 .. red_tiles.len - 1]) |lhs| {
        for (red_tiles[1..]) |rhs| {
            const current_area = @abs(lhs.x - rhs.x + 1) * @abs(lhs.y - rhs.y + 1);
            try area_and_pairs.append(allocator, .{ .area = current_area, .lhs = lhs, .rhs = rhs });
        }
    }
    std.mem.sort(AreaAndPair, area_and_pairs.items, {}, AreaAndPair.lessThan);
    std.mem.reverse(AreaAndPair, area_and_pairs.items);

    areas: for (area_and_pairs.items) |area_and_pair| {
        const area, const lhs, const rhs = .{area_and_pair.area ,area_and_pair.lhs, area_and_pair.rhs};
        working_perimeter.clearRetainingCapacity();

        try add(allocator, &working_perimeter, .{ .x = @min(lhs.x, rhs.x), .y = @min(lhs.y, rhs.y) }, .{ .x = @min(lhs.x, rhs.x), .y = @max(lhs.y, rhs.y) });
        try add(allocator, &working_perimeter, .{ .x = @min(lhs.x, rhs.x), .y = @max(lhs.y, rhs.y) }, .{ .x = @max(lhs.x, rhs.x), .y = @max(lhs.y, rhs.y) });
        try add(allocator, &working_perimeter, .{ .x = @max(lhs.x, rhs.x), .y = @max(lhs.y, rhs.y) }, .{ .x = @max(lhs.x, rhs.x), .y = @min(lhs.y, rhs.y) });
        try add(allocator, &working_perimeter, .{ .x = @max(lhs.x, rhs.x), .y = @min(lhs.y, rhs.y) }, .{ .x = @min(lhs.x, rhs.x), .y = @min(lhs.y, rhs.y) });

        var point_iter = working_perimeter.keyIterator();
        while (point_iter.next()) |point| {
            if (perimeter.contains(point.*)) {
                continue;
            }
            var p = point.*;
            // ray cast right
            var crosses: u32 = 0;
            while (p.x < 100_000) : (p.x += 1) {
                if (perimeter.contains(p)) {
                    crosses += 1;
                }
            }
            // outside of polygon, try next area
            if (crosses % 2 == 0) {
                continue :areas;
            }
        }
        // all points valid - return the area
        return area;
    }
    return 0;
}

test "parse input" {
    const allocator = std.testing.allocator;
    var points = try parseInput(allocator, sample);
    defer points.deinit(allocator);

    try std.testing.expectEqual(8, points.items.len);
    try std.testing.expectEqual(7, points.items[7].x);
    try std.testing.expectEqual(3, points.items[7].y);
}

test "part 1 sample" {
    const allocator = std.testing.allocator;
    var points = try parseInput(allocator, sample);
    defer points.deinit(allocator);

    const result = part1(points.items);
    try std.testing.expectEqual(50, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var points = try parseInput(allocator, input);
    defer points.deinit(allocator);

    const result = part1(points.items);
    try std.testing.expectEqual(4_755_429_952, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;
    var points = try parseInput(allocator, sample);
    defer points.deinit(allocator);

    const result = try part2(allocator, points.items);
    try std.testing.expectEqual(24, result);
}

// test "part 2" {
//     const allocator = std.testing.allocator;
//
//     const input = try helpers.readInputFile(allocator, input_path);
//     defer allocator.free(input);
//     var points = try parseInput(allocator, input);
//     defer points.deinit(allocator);
//
//     const result = try part2(allocator, points.items);
//     try std.testing.expectEqual(4_755_429_952, result);
// }
