// test.zig

pub fn _test() anyerror!void {}

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    // check len of args
    if (args.len < 2) {
        try stdout.print("usage: ./test expression\n", .{});
        return;
    }

    // run command
    _test(args[1..]) catch |err| {
        try stdout.print("Error: {}\n", .{err});
        return;
    };
}
