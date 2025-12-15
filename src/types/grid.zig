const std = @import("std");

pub fn Point2D(comptime T: type) type {
    return struct {
        const Self = @This();
        x: T,
        y: T,
    };
}

/// A generic 2D Grid data structure.
/// It stores data in a contiguous 1D slice (row-major order).
pub fn @"2D"(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,
        width: usize,
        height: usize,

        /// Errors specific to Grid operations
        pub const Error = error{
            OutOfBounds,
        };

        /// Initialize the grid with specific dimensions.
        /// If `default_value` is provided, all cells are initialized to it.
        /// If `default_value` is null, memory is undefined (useful for performance if you plan to overwrite immediately).
        pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, default_value: ?T) !Self {
            const items = try allocator.alloc(T, width * height);

            if (default_value) |val| {
                @memset(items, val);
            }

            return Self{
                .items = items,
                .width = width,
                .height = height,
            };
        }

        /// Frees the underlying memory.
        pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
            allocator.free(self.items);
        }

        pub fn findPoint(self: Self, item: T) ?Point2D(isize) {
            const idx =  std.mem.indexOfScalar(T, self.items, item) orelse return null;
            return self.indexToCoords(idx);
        }

        fn indexToCoords(
            self: Self,
            index: usize,
        ) Point2D(isize) {
            return Point2D(isize){
                .x = @intCast(index % self.width),
                .y = @intCast(index / self.width),
            };
        }

        /// Helper to calculate 1D index from 2D coordinates.
        fn getIndex(self: Self, x: usize, y: usize) usize {
            return (y * self.width) + x;
        }

        pub fn inBoundsPoint(self: Self,point: Point2D(isize)) bool {
            if (point.x < 0 or point.y < 0) return false;
            return self.inBounds(@intCast(point.x), @intCast(point.y));
        }

        /// Check if coordinates are within bounds.
        pub fn inBounds(self: Self, x: usize, y: usize) bool {
            return x < self.width and y < self.height;
        }

        /// Set a value at (x, y). Returns error if out of bounds.
        pub fn set(self: *Self, x: usize, y: usize, value: T) !void {
            if (!self.inBounds(x, y)) return Error.OutOfBounds;
            self.items[self.getIndex(x, y)] = value;
        }

        pub fn setPoint(self: *Self, point: Point2D(isize), value: T) !void {
            if (!self.inBoundsPoint(point)) return Error.OutOfBounds;
            self.items[self.getIndex(@intCast(point.x), @intCast(point.y))] = value;
        }

        pub fn getPoint(self: Self,point: Point2D(isize)) ?T {
            if (!self.inBoundsPoint(point)) return null;
            return self.items[self.getIndex(@intCast(point.x), @intCast(point.y))];
        }

        /// Get a copy of the value at (x, y). Returns null if out of bounds.
        pub fn get(self: Self, x: usize, y: usize) ?T {
            if (!self.inBounds(x, y)) return null;
            return self.items[self.getIndex(x, y)];
        }
        /// Get a copy of the value at (x, y). Returns null if out of bounds.
        pub fn getCast(self: Self, x: anytype, y: anytype) ?T {
            return self.get(@as(usize, @intCast(x)), @as(usize, @intCast(y)));
        }

        pub fn getPtrPoint(self: *Self, point: Point2D(isize)) ?*T {
            if (!self.inBoundsPoint(point)) return null;
            return self.getPtr(@intCast(self.x), @intCast(self.y));
        }

        /// Get a pointer to the value at (x, y).
        /// Useful for modifying complex structs in place without copying.
        pub fn getPtr(self: *Self, x: usize, y: usize) ?*T {
            if (!self.inBounds(x, y)) return null;
            return &self.items[self.getIndex(x, y)];
        }

        /// Returns a slice representing a specific row.
        pub fn getRow(self: Self, y: usize) ?[]T {
            if (y >= self.height) return null;
            const start = y * self.width;
            return self.items[start .. start + self.width];
        }

        /// Fills the entire grid with a specific value.
        pub fn fill(self: *Self, value: T) void {
            @memset(self.items, value);
        }

        /// Prints the grid contents to the provided writer.
        /// Uses the default {any} formatter for values.
        ///
        pub fn debugPrint(self: @"2D"(T)) void {
            self.debugPrintf(null);
        }
        pub fn debugPrintf(self: Self, comptime fmt_string: ?[]const u8) void {
            var y: usize = 0;
            while (y < self.height) : (y += 1) {
                var x: usize = 0;
                while (x < self.width) : (x += 1) {
                    const val = self.items[self.getIndex(x, y)];
                    std.debug.print(fmt_string orelse "{f}", .{val});
                }
                std.debug.print("\n", .{});
            }
        }
    };
}
