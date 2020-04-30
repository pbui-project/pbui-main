const std = @import("std");

pub fn main(args: [][]u8) anyerror!u8 {

    //read $PWD to get pwd including symlinks
    const pwd = std.os.getenv("PWD");


    // send pwd to stdout
    const stdout = std.io.getStdOut().outStream();
    try stdout.print("{}\n", .{pwd});

    return 0;
}