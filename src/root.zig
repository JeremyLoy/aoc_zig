const std = @import("std");

pub const year2025 = struct {
    pub const day_1 = @import("2025/day_1.zig");
    pub const day_2 = @import("2025/day_2.zig");
    pub const day_3 = @import("2025/day_3.zig");
    pub const day_4 = @import("2025/day_4.zig");
    pub const day_5 = @import("2025/day_5.zig");
    pub const day_6 = @import("2025/day_6.zig");
    pub const day_7 = @import("2025/day_7.zig");
    pub const day_9 = @import("2025/day_9.zig");
    pub const day_11 = @import("2025/day_11.zig");
    pub const day_12 = @import("2025/day_12.zig");
};

pub const helpers = @import("helpers.zig");
pub const types = @import("types/types.zig");
pub const grid = @import("types/grid.zig");

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(year2025);
}
