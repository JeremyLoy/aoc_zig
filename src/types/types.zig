const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

/// A dynamic, unmanaged Ring Buffer (Queue/Stack).
/// Backed by a raw slice []T.
pub fn RingBuffer(comptime T: type) type {
    return struct {
        data: []T = &[_]T{},
        head: usize = 0,
        count: usize = 0,

        const Self = @This();

        pub const empty: Self = .{
            .head = 0,
            .count = 0,
            .data = &.{},
        };

        pub fn deinit(self: *Self, allocator: Allocator) void {
            allocator.free(self.data);
            self.* = undefined;
        }

        pub fn push(self: *Self, allocator: Allocator, item: T) !void {
            try self.ensureCapacity(allocator);
            const tail = (self.head + self.count) % self.data.len;
            self.data[tail] = item;
            self.count += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.count == 0) return null;
            const tail = (self.head + self.count - 1) % self.data.len;
            self.count -= 1;
            return self.data[tail];
        }

        pub fn dequeue(self: *Self) ?T {
            if (self.count == 0) return null;
            const item = self.data[self.head];
            self.head = (self.head + 1) % self.data.len;
            self.count -= 1;
            return item;
        }

        pub const enqueue = push;

        pub fn peekFront(self: *Self) ?T {
            if (self.count == 0) return null;
            return self.data[self.head];
        }

        pub fn peekBack(self: *Self) ?T {
            if (self.count == 0) return null;
            const tail = (self.head + self.count - 1) % self.data.len;
            return self.data[tail];
        }

        pub fn len(self: Self) usize {
            return self.count;
        }

        pub fn capacity(self: Self) usize {
            return self.data.len;
        }

        fn ensureCapacity(self: *Self, allocator: Allocator) !void {
            if (self.count < self.data.len) return;

            const new_cap = if (self.data.len == 0) 8 else self.data.len * 2;
            const new_data = try allocator.alloc(T, new_cap);

            // Linearize the data into the new buffer
            var i: usize = 0;
            while (i < self.count) : (i += 1) {
                const old_index = (self.head + i) % self.data.len;
                new_data[i] = self.data[old_index];
            }

            if (self.data.len > 0) allocator.free(self.data);
            self.data = new_data;
            self.head = 0;
        }
    };
}

test "RingBuffer basic queue behavior (FIFO)" {
    const allocator = testing.allocator;
    var rb = RingBuffer(i32){};
    defer rb.deinit(allocator);

    // Test Empty
    try testing.expect(rb.dequeue() == null);
    try testing.expect(rb.len() == 0);

    // Enqueue
    try rb.enqueue(allocator, 10);
    try rb.enqueue(allocator, 20);
    try rb.enqueue(allocator, 30);

    try testing.expectEqual(@as(usize, 3), rb.len());
    try testing.expectEqual(@as(i32, 10), rb.peekFront().?);

    // Dequeue
    try testing.expectEqual(@as(i32, 10), rb.dequeue().?);
    try testing.expectEqual(@as(i32, 20), rb.dequeue().?);
    try testing.expectEqual(@as(i32, 30), rb.dequeue().?);

    // Test Empty Again
    try testing.expect(rb.dequeue() == null);
    try testing.expectEqual(@as(usize, 0), rb.len());
}

test "RingBuffer basic stack behavior (LIFO)" {
    const allocator = testing.allocator;
    var rb = RingBuffer(i32){};
    defer rb.deinit(allocator);

    try rb.push(allocator, 100);
    try rb.push(allocator, 200);
    try rb.push(allocator, 300);

    try testing.expectEqual(@as(i32, 300), rb.peekBack().?);

    try testing.expectEqual(@as(i32, 300), rb.pop().?);
    try testing.expectEqual(@as(i32, 200), rb.pop().?);
    try testing.expectEqual(@as(i32, 100), rb.pop().?);
    try testing.expect(rb.pop() == null);
}

test "RingBuffer mixed operations" {
    const allocator = testing.allocator;
    var rb = RingBuffer(u8){};
    defer rb.deinit(allocator);

    // Add 1, 2
    try rb.enqueue(allocator, 1);
    try rb.enqueue(allocator, 2);

    // Remove 1 (Queue behavior)
    try testing.expectEqual(@as(u8, 1), rb.dequeue().?); // Remaining: [2]

    // Push 3 (Stack/Queue behavior - adds to end)
    try rb.push(allocator, 3); // Remaining: [2, 3]

    // Pop 3 (Stack behavior)
    try testing.expectEqual(@as(u8, 3), rb.pop().?); // Remaining: [2]

    // Dequeue 2
    try testing.expectEqual(@as(u8, 2), rb.dequeue().?); // Remaining: []

    try testing.expectEqual(@as(usize, 0), rb.len());
}

test "RingBuffer capacity growth and wrapping" {
    const allocator = testing.allocator;
    var rb = RingBuffer(usize){};
    defer rb.deinit(allocator);

    // 1. Force initial capacity (likely 8 based on logic)
    // Push 0..7
    for (0..8) |i| {
        try rb.enqueue(allocator, i);
    }
    try testing.expectEqual(@as(usize, 8), rb.capacity());
    try testing.expectEqual(@as(usize, 8), rb.len());

    // 2. Dequeue 4 items. Head moves to index 4.
    // [ _, _, _, _, 4, 5, 6, 7 ]
    for (0..4) |i| {
        try testing.expectEqual(i, rb.dequeue().?);
    }
    try testing.expectEqual(@as(usize, 4), rb.len());

    // 3. Enqueue 4 more items.
    // The tail should wrap around to the beginning.
    // [ 8, 9, 10, 11, 4, 5, 6, 7 ] (Physical Layout)
    for (8..12) |i| {
        try rb.enqueue(allocator, i);
    }

    // Current state: 8 items full, but head is in middle (index 4).
    try testing.expectEqual(@as(usize, 8), rb.len());

    // 4. Enqueue one more to FORCE RESIZE.
    // This is the critical moment. The buffer must grow (to 16),
    // and the wrapped data [ 8, 9, 10, 11 ] must be moved to the end
    // so the logical order 4..12 is contiguous (or at least correct).
    try rb.enqueue(allocator, 12);

    try testing.expect(rb.capacity() >= 9); // likely 16
    try testing.expectEqual(@as(usize, 9), rb.len());

    // 5. Verify ALL data comes out in correct FIFO order
    for (4..13) |i| {
        const val = rb.dequeue();
        try testing.expectEqual(i, val.?);
    }

    try testing.expectEqual(@as(usize, 0), rb.len());
}