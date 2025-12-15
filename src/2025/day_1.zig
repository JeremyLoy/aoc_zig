const std = @import("std");
const helpers = @import("../helpers.zig");

const sample =
    \\L68
    \\L30
    \\R48
    \\L5
    \\R60
    \\L55
    \\L1
    \\L99
    \\R14
    \\L82
;

const input_path = "input/2025/1.txt";

pub const Action = union(enum) {
    left: i32,
    right: i32,
};

pub fn part1(start: i32, actions: []const Action) i32 {
    var current: i32 = start;
    var zero_count: i32 = 0;

    for (actions) |action| {
        const steps = switch (action) {
            // it's easier to think about rotating left as
            // rotating to the right a different amount
            // to account for rotating to the left more than 100 degrees, first mod 100
            .left => |v| -v,
            .right => |v| v,
        };
        current = @mod((current + steps), 100);
        if (current == 0) zero_count += 1;
    }
    return zero_count;
}

pub fn part2(start: u32, actions: []const Action) u32 {
    var current: u32 = start;
    var cross_zero_count: u32 = 0;

    for (actions) |action| {
        const steps = switch (action) {
            // it's easier to think about rotating left as
            // adding a negative amount
            .left => |v| -v,
            .right => |v| v,
        };
        const raw: i32 = @as(i32, @intCast(current)) + steps;
        const new_pos: u32 = @as(u32, @intCast(@mod(raw, 100)));

        var cross_zero_incr: u32 = @abs(@divFloor(raw, 100));
        if (new_pos == 0) {
            cross_zero_incr += 1;
        }
        if (current == 0 and raw < 0) {
            cross_zero_incr -= 1;
        }
        if (new_pos == 0 and raw > 0) {
            cross_zero_incr -= 1;
        }

        cross_zero_count += cross_zero_incr;

        current = new_pos;
    }
    return cross_zero_count;
}

pub fn parseInputToActions(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Action) {
    var actions = std.ArrayList(Action).empty;
    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len < 2) continue;
        const direction = line[0];
        const value = try std.fmt.parseInt(i32, line[1..], 10);

        const action: Action = switch (direction) {
            'L' => .{ .left = value },
            'R' => .{ .right = value },
            else => return error.InvalidDirection,
        };
        try actions.append(allocator, action);
    }
    return actions;
}

test "parse actions" {
    const allocator = std.testing.allocator;
    var actions = try parseInputToActions(allocator, sample);
    defer actions.deinit(allocator);

    try std.testing.expectEqual(10, actions.items.len);
    try std.testing.expectEqual(Action{ .left = 68 }, actions.items[0]);
    try std.testing.expectEqual(Action{ .right = 14 }, actions.items[8]);
}

test "part 1 sample" {
    const allocator = std.testing.allocator;

    var actions = try parseInputToActions(allocator, sample);
    defer actions.deinit(allocator);

    const result = part1(50, actions.items);
    try std.testing.expectEqual(3, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var actions = try parseInputToActions(allocator, input);
    defer actions.deinit(allocator);

    const result = part1(50, actions.items);
    try std.testing.expectEqual(1_180, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;

    var actions = try parseInputToActions(allocator, sample);
    defer actions.deinit(allocator);

    const result = part2(50, actions.items);
    try std.testing.expectEqual(6, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var actions = try parseInputToActions(allocator, input);
    defer actions.deinit(allocator);

    const result = part2(50, actions.items);
    try std.testing.expectEqual(6_892, result);
}
