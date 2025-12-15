const std = @import("std");
const helpers = @import("../helpers.zig");

const sample =
    \\aaa: you hhh
    \\you: bbb ccc
    \\bbb: ddd eee
    \\ccc: ddd eee fff
    \\ddd: ggg
    \\eee: out
    \\fff: out
    \\ggg: out
    \\hhh: ccc fff iii
    \\iii: out
;

const sample2 =
    \\svr: aaa bbb
    \\aaa: fft
    \\fft: ccc
    \\bbb: tty
    \\tty: ccc
    \\ccc: ddd eee
    \\ddd: hub
    \\hub: fff
    \\eee: dac
    \\dac: fff
    \\fff: ggg hhh
    \\ggg: out
    \\hhh: out
;

const input_path = "input/2025/11.txt";

pub const Node = [3]u8;
const MemoCache = std.AutoHashMap(Node, u64).Unmanaged;
const Action = union(enum) {
    // PreOrder
    Process: Node,
    // PostOrder
    Accumulate: struct { from: Node, to: Node },
};
pub const NodeList = std.ArrayList(Node);
pub const ServerRack = struct {
    const Self = @This();
    adj_list: std.StringHashMapUnmanaged(NodeList) = .empty,

    const empty: Self = .{};

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        var it = self.adj_list.valueIterator();
        while (it.next()) |list| {
            list.deinit(allocator);
        }
        self.adj_list.deinit(allocator);
    }

    pub fn put(self: *Self, allocator: std.mem.Allocator, key: []const u8, value: NodeList) !void {
        return self.adj_list.put(allocator, key, value);
    }

    pub fn get(self: *const Self, key: []const u8) ?NodeList {
        return self.adj_list.get(key);
    }
};

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !(ServerRack) {
    var server_rack = ServerRack.empty;
    errdefer server_rack.deinit(allocator);
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const key, const edges = std.mem.cut(u8, line, ":") orelse return error.CouldNotCut;
        var edge_iter = std.mem.splitScalar(u8, std.mem.trim(u8, edges, " "), ' ');
        var edge_arr = NodeList.empty;
        errdefer edge_arr.deinit(allocator);
        while (edge_iter.next()) |edge| {
            std.debug.assert(edge.len >= 3);
            try edge_arr.append(allocator, edge[0..3].*);
        }
        try server_rack.put(allocator, key, edge_arr);
    }

    return server_rack;
}

fn traverse(allocator: std.mem.Allocator, server_rack: *const ServerRack, start_s: []const u8, goal_s: []const u8) !u64 {
    var cache = MemoCache.empty;
    var stack = std.ArrayList(Action).empty;
    defer cache.deinit(allocator);
    defer stack.deinit(allocator);

    const start = start_s[0..3].*;
    const goal = goal_s[0..3].*;

    try stack.append(allocator, .{ .Process = start });
    while (stack.pop()) |action| {
        switch (action) {
            // 1. PreOrder Step. Base cases or appending child steps.
            .Process => |parent| {
                if (cache.contains(parent)) continue;
                if (std.meta.eql(parent, goal)) {
                    try cache.put(allocator, parent, 1);
                    continue;
                }

                try cache.put(allocator, parent, 0);
                if (server_rack.get(&parent)) |children| {
                    for (children.items) |child| {
                        // appending reversed because it is a stack. Process will be first, then AddEdge
                        try stack.append(allocator, .{ .Accumulate = .{ .from = parent, .to = child } });
                        try stack.append(allocator, .{ .Process = child });
                    }
                }
            },
            // 2. PostOrder step - parent += child values.
            .Accumulate => |edge| {
                // We know 'edge.to' is already in cache (because we processed it previously).
                // We know 'edge.from' is in cache (initialized to 0 during Process).
                const child_val = cache.get(edge.to) orelse unreachable;

                // Add child's paths to parent's total
                const parent_ptr = cache.getPtr(edge.from).?;
                parent_ptr.* += child_val;
            },
        }
    }

    return cache.get(start) orelse 0;
}

pub fn part1(allocator: std.mem.Allocator, server_rack: *const ServerRack) !u64 {
    return traverse(allocator, server_rack, "you", "out");
}

pub fn part2(allocator: std.mem.Allocator, server_rack: *const ServerRack) !u64 {
    const svr_fft = try traverse(allocator, server_rack, "svr", "fft");
    const fft_dac = try traverse(allocator, server_rack, "fft", "dac");
    const dac_out = try traverse(allocator, server_rack, "dac", "out");

    return (svr_fft * fft_dac * dac_out);
}

test "parse input" {
    const allocator = std.testing.allocator;
    var server_rack = try parseInput(allocator, sample);
    defer server_rack.deinit(allocator);

    try std.testing.expectEqual(server_rack.adj_list.size, 10);
    try std.testing.expectEqual(server_rack.get("ccc").?.items.len, 3);
    try std.testing.expectEqual(server_rack.get("hhh").?.items.len, 3);
    try std.testing.expectEqual(server_rack.get("fff").?.items.len, 1);
}

test "part 1 sample" {
    const allocator = std.testing.allocator;
    var server_rack = try parseInput(allocator, sample);
    defer server_rack.deinit(allocator);

    const result = try part1(allocator, &server_rack);
    try std.testing.expectEqual(5, result);
}

test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var server_rack = try parseInput(allocator, input);
    defer server_rack.deinit(allocator);

    const result = try part1(allocator, &server_rack);
    try std.testing.expectEqual(552, result);
}

test "part 2 sample" {
    const allocator = std.testing.allocator;
    var server_rack = try parseInput(allocator, sample2);
    defer server_rack.deinit(allocator);

    const result = try part2(allocator, &server_rack);
    try std.testing.expectEqual(2, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var server_rack = try parseInput(allocator, input);
    defer server_rack.deinit(allocator);

    const result = try part2(allocator, &server_rack);
    try std.testing.expectEqual(307_608_674_109_300, result);
}
