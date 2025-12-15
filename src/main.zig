const std = @import("std");
const aoc = @import("aoc");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const day_1_input = try aoc.helpers.readInputFile(allocator, "input/2025/1.txt");
    defer allocator.free(day_1_input);
    const day_2_input = try aoc.helpers.readInputFile(allocator, "input/2025/2.txt");
    defer allocator.free(day_2_input);
    const day_3_input = try aoc.helpers.readInputFile(allocator, "input/2025/3.txt");
    defer allocator.free(day_3_input);
    const day_4_input = try aoc.helpers.readInputFile(allocator, "input/2025/4.txt");
    defer allocator.free(day_4_input);
    const day_5_input = try aoc.helpers.readInputFile(allocator, "input/2025/5.txt");
    defer allocator.free(day_5_input);
    const day_6_input = try aoc.helpers.readInputFile(allocator, "input/2025/6.txt");
    defer allocator.free(day_6_input);
    const day_7_input = try aoc.helpers.readInputFile(allocator, "input/2025/7.txt");
    defer allocator.free(day_7_input);
    const day_9_input = try aoc.helpers.readInputFile(allocator, "input/2025/9.txt");
    defer allocator.free(day_9_input);
    const day_11_input = try aoc.helpers.readInputFile(allocator, "input/2025/11.txt");
    defer allocator.free(day_11_input);
    const day_12_input = try aoc.helpers.readInputFile(allocator, "input/2025/12.txt");
    defer allocator.free(day_12_input);

    var total: u64 = 0;

    var actions = try aoc.year2025.day_1.parseInputToActions(allocator, day_1_input);
    defer actions.deinit(allocator);
    total += try aoc.helpers.timeIt("1-1", aoc.year2025.day_1.part1, .{ 50, actions.items });
    total += try aoc.helpers.timeIt("1-2", aoc.year2025.day_1.part2, .{ 50, actions.items });

    var ranges = try aoc.year2025.day_2.parseInput(allocator, day_2_input);
    defer ranges.deinit(allocator);
    total += try aoc.helpers.timeIt("2-1", aoc.year2025.day_2.part1, .{ranges.items});
    total += try aoc.helpers.timeIt("2-2", aoc.year2025.day_2.part2, .{ranges.items});

    var banks = try aoc.year2025.day_3.parseInput(allocator, day_3_input);
    defer {
        for (banks.items) |bank| allocator.free(bank);
        banks.deinit(allocator);
    }
    total += try aoc.helpers.timeIt("3-1", aoc.year2025.day_3.part1, .{banks.items});
    total += try aoc.helpers.timeIt("3-2", aoc.year2025.day_3.part2, .{banks.items});

    var paper_rolls = try aoc.year2025.day_4.parseInput(allocator, day_4_input);
    defer paper_rolls.deinit(allocator);

    total += try aoc.helpers.timeIt("4-1", aoc.year2025.day_4.part1, .{ allocator, paper_rolls });
    total += try aoc.helpers.timeIt("4-2", aoc.year2025.day_4.part2, .{ allocator, &paper_rolls });

    var kitchen = try aoc.year2025.day_5.parseInput(allocator, day_5_input);
    defer kitchen.deinit(allocator);

    total += try aoc.helpers.timeIt("5-1", aoc.year2025.day_5.part1, .{kitchen});
    total += try aoc.helpers.timeIt("5-2", aoc.year2025.day_5.part2, .{kitchen});

    var problems = try aoc.year2025.day_6.parseInput(allocator, day_6_input);
    defer {
        for (problems.items) |*problem| {
            problem.deinit(allocator);
        }
        problems.deinit(allocator);
    }
    var problems_2 = try aoc.year2025.day_6.parseInput2(allocator, day_6_input);
    defer {
        for (problems_2.items) |*problem| {
            problem.deinit(allocator);
        }
        problems_2.deinit(allocator);
    }

    total += try aoc.helpers.timeIt("6-1", aoc.year2025.day_6.part1, .{problems.items});
    total += try aoc.helpers.timeIt("6-2", aoc.year2025.day_6.part2, .{problems_2.items});

    var manifold = try aoc.year2025.day_7.parseInput(allocator, day_7_input);
    defer manifold.deinit(allocator);

    total += try aoc.helpers.timeIt("7-1", aoc.year2025.day_7.part1, .{ allocator, &manifold });
    total += try aoc.helpers.timeIt("7-2", aoc.year2025.day_7.part2, .{ allocator, manifold });

    var red_tiles, var perimeter = try aoc.year2025.day_9.parseInput(allocator, day_9_input);
    defer red_tiles.deinit(allocator);
    defer perimeter.deinit(allocator);

    total += try aoc.helpers.timeIt("9-1", aoc.year2025.day_9.part1, .{red_tiles.items});
    total += try aoc.helpers.timeIt("9-2", aoc.year2025.day_9.part2, .{ red_tiles.items, perimeter.items });

    var server_rack = try aoc.year2025.day_11.parseInput(allocator, day_11_input);
    defer server_rack.deinit(allocator);

    total += try aoc.helpers.timeIt("11-1", aoc.year2025.day_11.part1, .{ allocator, &server_rack });
    total += try aoc.helpers.timeIt("11-2", aoc.year2025.day_11.part2, .{ allocator, &server_rack });

    var farm = try aoc.year2025.day_12.parseInput(allocator, day_12_input);
    defer farm.deinit(allocator);

    total += try aoc.helpers.timeIt("12-1", aoc.year2025.day_12.part1, .{farm});

    std.debug.print("Total taken: {d:.3} ms\n", .{@as(f64, @floatFromInt(total)) / 1_000_000.0});
}
