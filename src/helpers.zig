const std = @import("std");

pub fn readInputFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const stat = try file.stat();

    // Allocate a buffer of the exact size
    const buffer = try allocator.alloc(u8, stat.size);
    errdefer allocator.free(buffer);

    // Read the content into the buffer
    const bytes_read = try file.read(buffer);

    // Ideally, bytes_read should equal stat.size.
    if (bytes_read != stat.size) {
        // This can happen if the file changed size between stat() and read()
        // or on some special file systems.
        return error.FileChangedSize;
    }

    return buffer;
}

pub fn timeIt(label: []const u8, func: anytype, args: anytype) !u64 {
    var timer = try std.time.Timer.start();
    const result = @call(.auto, func, args);

    const elapsed = timer.read();
    // If the result is an error union, we try it to propagate the error.
    // We check the type information at compile time.
    if (@typeInfo(@TypeOf(result)) == .error_union) {
        _ = try result;
    }
    std.debug.print("[{s}] took {d:.6} ms\n", .{ label, @as(f64, @floatFromInt(elapsed)) / 1_000_000.0 });
    return elapsed;
}
