const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

pub fn makeDirectory(name: []const u8) !void {
    std.fs.makeDir(name) catch |err| {
        try stdout.print("Error Creating Directory: {}\n", .{err});
        return;
    };
}

pub fn main(args: [][]u8) anyerror!u8 {
    // check len of args
    if (args.len < 2) {
        try stdout.print("mkdir: missing operands\n", .{});
        return 1;
    }

    // run command
    for (args) |arg, i| {
        if (i != 0) {
            makeDirectory(arg) catch |err| {
                try stdout.print("Error: {}\n", .{err});
                return 1;
            };
        }
    }

    return 0;
}
