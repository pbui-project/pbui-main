const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

pub fn basename(path: []const u8) !void {
    // basename calls basenameposix if not windows... more robust
    // to just use basename
    try stdout.print("{}\n", .{std.fs.path.basename(path)});
}

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    // check len of args
    if (args.len != 2) {
        try stdout.print("usage: ./basename FILENAME\n", .{});
        return;
    }

    // run command
    try basename(args[1]);
}
