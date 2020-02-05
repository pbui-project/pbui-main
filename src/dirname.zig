const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

pub fn dirname(paths: [][]const u8, zero: bool) !void {
    // dirname calls dirnameposix if not windows... more robust
    // to just use basename
    const terminator: u8 = if (zero) '\x00' else '\n';

    // loop through paths and call dirname
    var i: usize = 0;
    var name: ?[]const u8 = null;
    while (i < paths.len) : (i += 1) {
        name = std.fs.path.dirname(paths[i]) orelse ".";

        try stdout.print("{}{c}", .{ name, terminator });
    }
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
        try stdout.print("usage: ./dirname FILENAME...\n", .{});
        return;
    }
    // run command
    try dirname(args[1..], false);
}
