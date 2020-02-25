// sleep.zig
// nap time bb

const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

pub fn sleep(n: u32) anyerror!void {
    // TODO: docs say maybe spurious wakeups but no way to tell.. possible PR or issue maybe?
    std.os.nanosleep(n, 0);
}

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return 1;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    // check len of args
    if (args.len != 2) {
        try stdout.print("usage: ./sleep n\n", .{});
        return 1;
    }

    // must be a number
    const n = std.fmt.parseInt(u32, args[1], 10) catch |err| {
        try stdout.print("Error: sleep arg must be a number!\n", .{});
        return 1;
    };

    try sleep(n);

    // exit success
    return 0;
}
