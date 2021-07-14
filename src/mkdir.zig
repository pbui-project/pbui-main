const std = @import("std");
const stdout = &std.io.getStdOut().writer();

pub fn makeDirectory(name: []const u8) !void {
    std.fs.cwd().makeDir(name) catch |err| {
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

test "see if dir was made" {
    _ = std.fs.cwd().deleteDir("/tmp/testmkdir") catch |err| void;
    try makeDirectory("/tmp/testmkdir");

    var ret = std.fs.cwd().openDir("/tmp/testmkdir", .{}) catch |err| switch (err) {
        error.NotDir => return error.NotDir,
        else => {
            std.debug.assert(false);
            return error.FileSystem;
        },
    };
}
