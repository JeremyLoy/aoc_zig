const std = @import("std");
const helpers = @import("../helpers.zig");
const grid = @import("../types/grid.zig");

const sample =
    \\162,817,812
    \\57,618,57
    \\906,360,560
    \\592,479,940
    \\352,342,300
    \\466,668,158
    \\542,29,236
    \\431,825,988
    \\739,650,466
    \\52,470,668
    \\216,146,977
    \\819,987,18
    \\117,168,530
    \\805,96,715
    \\346,949,466
    \\970,615,88
    \\941,993,340
    \\862,61,35
    \\984,92,344
    \\425,690,689
;

const input_path = "input/2025/8.txt";
const Point = grid.Point3D(u64);
const Circuit = std.AutoHashMap(Point, void).Unmanaged;
const PointDistance = struct { f64, Point, Point };
fn lessThanPointDistance(_: void, a: PointDistance, b: PointDistance) bool {
    return a.@"0" < b.@"0";
}

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Point) {
    var points = std.ArrayList(Point).empty;
    errdefer points.deinit(allocator);
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var numbers = std.mem.splitScalar(u8, line, ',');
        const point: Point = .{
            .x = try std.fmt.parseInt(u64, numbers.next().?, 10),
            .y = try std.fmt.parseInt(u64, numbers.next().?, 10),
            .z = try std.fmt.parseInt(u64, numbers.rest(), 10),
        };
        try points.append(allocator, point);
    }
    return points;
}

fn sortBySize(_: void, a: *Circuit, b: *Circuit) bool {
    return a.*.size < b.*.size;
}

pub fn part1(allocator: std.mem.Allocator, points: []Point, max_connections: usize) !u64 {
    var point_to_circuit = std.AutoHashMap(Point, *Circuit).Unmanaged.empty;
    var owned_circuits = std.ArrayList(*Circuit).empty;
    for (points) |point| {
        const new_circuit = try allocator.create(Circuit);
        new_circuit.* = Circuit.empty;
        try owned_circuits.append(allocator, new_circuit);
        try new_circuit.put(allocator, point, {});
        try point_to_circuit.put(allocator, point, new_circuit);
    }
    defer {
        for (owned_circuits.items) |circuit| {
            circuit.*.deinit(allocator);
            allocator.destroy(circuit);
        }
        owned_circuits.deinit(allocator);
        point_to_circuit.deinit(allocator);
    }
    var sorted_point_distances = std.ArrayList(PointDistance).empty;
    defer sorted_point_distances.deinit(allocator);

    for (points[0 .. points.len - 1], 0..) |a, i| {
        for (points[i + 1 ..]) |b| {
            if (std.meta.eql(a, b)) continue;
            try sorted_point_distances.append(allocator, PointDistance{ a.euclid_distance(f64, b), a, b });
        }
    }
    std.mem.sort(PointDistance, sorted_point_distances.items, {}, lessThanPointDistance);

    // const epsilon = 0.000_001; // Tolerance for float comparison
    var connections_made: usize = 0;
    for (sorted_point_distances.items) |pd| {
        connections_made += 1;
        if (connections_made > max_connections) break;
        _, const a, const b = pd;
        const a_circuit = point_to_circuit.get(a) orelse return error.CircuitANotFound;
        const b_circuit = point_to_circuit.get(b) orelse return error.CircuitBNotFound;
        if (a_circuit != b_circuit) {
            // connections_made += 1;
            var dest = a_circuit;
            var src = b_circuit;
            if (src.size > dest.size) {
                dest = b_circuit;
                src = a_circuit;
            }
            var src_iter = src.keyIterator();
            while (src_iter.next()) |p| {
                try dest.put(allocator, p.*, {});
                try point_to_circuit.put(allocator, p.*, dest);
            }
            src.clearRetainingCapacity();
        }
    }

    std.mem.sort(*Circuit, owned_circuits.items, {}, sortBySize);
    std.mem.reverse(*Circuit, owned_circuits.items);

    return owned_circuits.items[0].size * owned_circuits.items[1].size * owned_circuits.items[2].size;
}

pub fn part2(allocator: std.mem.Allocator, points: []Point) !u64 {
    var point_to_circuit = std.AutoHashMap(Point, *Circuit).Unmanaged.empty;
    var owned_circuits = std.ArrayList(*Circuit).empty;
    for (points) |point| {
        const new_circuit = try allocator.create(Circuit);
        new_circuit.* = Circuit.empty;
        try owned_circuits.append(allocator, new_circuit);
        try new_circuit.put(allocator, point, {});
        try point_to_circuit.put(allocator, point, new_circuit);
    }
    defer {
        for (owned_circuits.items) |circuit| {
            circuit.*.deinit(allocator);
            allocator.destroy(circuit);
        }
        owned_circuits.deinit(allocator);
        point_to_circuit.deinit(allocator);
    }
    var sorted_point_distances = std.ArrayList(PointDistance).empty;
    defer sorted_point_distances.deinit(allocator);

    for (points[0 .. points.len - 1], 0..) |a, i| {
        for (points[i + 1 ..]) |b| {
            if (std.meta.eql(a, b)) continue;
            try sorted_point_distances.append(allocator, PointDistance{ a.euclid_distance(f64, b), a, b });
        }
    }
    std.mem.sort(PointDistance, sorted_point_distances.items, {}, lessThanPointDistance);

    for (sorted_point_distances.items) |pd| {
        _, const a, const b = pd;
        const a_circuit = point_to_circuit.get(a) orelse return error.CircuitANotFound;
        const b_circuit = point_to_circuit.get(b) orelse return error.CircuitBNotFound;
        if (a_circuit != b_circuit) {
            // connections_made += 1;
            var dest = a_circuit;
            var src = b_circuit;
            if (src.size > dest.size) {
                dest = b_circuit;
                src = a_circuit;
            }
            var src_iter = src.keyIterator();
            while (src_iter.next()) |p| {
                try dest.put(allocator, p.*, {});
                try point_to_circuit.put(allocator, p.*, dest);
            }
            src.clearRetainingCapacity();
            if (dest.size == points.len) {
                return a.x * b.x;
            }
        }
    }
    return error.UnexpectedlyReachedEndOfPoints;
}

test "part 1 sample" {
    const allocator = std.testing.allocator;
    var points = try parseInput(allocator, sample);
    defer points.deinit(allocator);

    const result = try part1(allocator, points.items, 10);
    try std.testing.expectEqual(40, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var points = try parseInput(allocator, input);
    defer points.deinit(allocator);

    const result = try part1(allocator, points.items, 1_000);
    try std.testing.expectEqual(123_234, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;
    var points = try parseInput(allocator, sample);
    defer points.deinit(allocator);

    const result = try part2(allocator, points.items);
    try std.testing.expectEqual(25_272, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var points = try parseInput(allocator, input);
    defer points.deinit(allocator);

    const result = try part2(allocator, points.items);
    try std.testing.expectEqual(9_259_958_565, result);
}
