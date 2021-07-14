const std = @import("std");
const stdout = &std.io.getStdOut().writer();

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

test "see if file got deleted" {
    var ret = std.fs.cwd().createFile("/tmp/testrm", std.fs.File.CreateFlags{});

    try remove("/tmp/testrm");

    var file = std.fs.cwd().access("/tmp/testrm", .{}) catch |err| switch (err) {
        error.FileNotFound => std.debug.assert(true),
        else => std.debug.assert(false),
    };
}
