const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

pub fn remove(name: []const u8) !void {
    std.fs.deleteTree(name) catch |err| {
        try stdout.print("Error Removing Object: {}\n", .{err});
        return;
    };
}

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    // check len of args
    if (args.len < 2) {
        try stdout.print("mkdir: missing operands\n", .{});
        return;
    }

    // run command
    for (args) |arg, i| {
        if (i != 0) {
            remove(arg) catch |err| {
                try stdout.print("Error: {}\n", .{err});
                return;
            };
        }
    }
}
