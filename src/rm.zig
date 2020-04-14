const std = @import("std");
const stdout = &std.io.getStdOut().outStream();

pub fn remove(name: []const u8) !void {
    std.fs.cwd().deleteTree(name) catch |err| {
        try stdout.print("Error Removing Object: {}\n", .{err});
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
            remove(arg) catch |err| {
                try stdout.print("Error: {}\n", .{err});
                return 1;
            };
        }
    }

    return 0;
}
