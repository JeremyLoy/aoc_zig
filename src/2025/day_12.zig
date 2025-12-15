const std = @import("std");
const helpers = @import("../helpers.zig");

pub const Tree = struct {
        area: i64,
        present_requirements: [6]i64,
};
pub const Farm = struct {
    const Self = @This();
    present_shapes: [6]i64,
    trees: []Tree,

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.trees);
        self.* = undefined;
    }
};

// very hard coded because there is only 1 part and the sample is actually a different problem!
pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Farm {
    var farm: Farm = .{
        .present_shapes = .{0,0,0,0,0,0},
        .trees = undefined,
    };
    var shapes_iter = std.mem.splitSequence(u8, input, "\n\n");
    farm.present_shapes[0] = @intCast(std.mem.count(u8, shapes_iter.next().?, "#"));
    farm.present_shapes[1] = @intCast(std.mem.count(u8, shapes_iter.next().?, "#"));
    farm.present_shapes[2] = @intCast(std.mem.count(u8, shapes_iter.next().?, "#"));
    farm.present_shapes[3] = @intCast(std.mem.count(u8, shapes_iter.next().?, "#"));
    farm.present_shapes[4] = @intCast(std.mem.count(u8, shapes_iter.next().?, "#"));
    farm.present_shapes[5] = @intCast(std.mem.count(u8, shapes_iter.next().?, "#"));

    var tree_list = std.ArrayList(Tree).empty;
    errdefer tree_list.deinit(allocator);
    var tree_iter = std.mem.splitScalar(u8, shapes_iter.rest(),'\n');
    while (tree_iter.next()) |tree_str| {
        var tree: Tree = undefined;
        const area, const requirements = std.mem.cut(u8, tree_str, ": ") orelse return error.CouldNotCut;
        const width, const height = std.mem.cut(u8,area, "x") orelse return error.CouldNotCut;
        tree.area = try std.fmt.parseInt(i64, width, 10) * try std.fmt.parseInt(i64, height, 10);
        var requirement_iter = std.mem.splitScalar(u8, requirements, ' ');
        var i:usize = 0;
        while (requirement_iter.next()) |requirement| :(i += 1) {
            tree.present_requirements[i] = try std.fmt.parseInt(i64, requirement, 10);
        }
        try tree_list.append(allocator, tree);
    }

    farm.trees = try tree_list.toOwnedSlice(allocator);
    return farm;
}

const input_path = "input/2025/12.txt";

pub fn part1(farm: Farm) i64 {
    var count: i64 = 0;

    for (farm.trees)|tree|{
        var remaining_area: i64 = @intCast(tree.area);
        for (tree.present_requirements, 0..)|requirement, i|{
            remaining_area -= farm.present_shapes[i] * requirement;
        }
        if (remaining_area >= 0) count+=1;
    }
    return count;
}


test "part 1" {
    const allocator = std.testing.allocator;

    const input = try helpers.readInputFile(allocator, input_path);
    defer allocator.free(input);
    var farm = try parseInput(allocator, input);
    defer farm.deinit(allocator);

    const result = part1( farm);
    try std.testing.expectEqual(546, result);
}

