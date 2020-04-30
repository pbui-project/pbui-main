const std = @import("std");

pub fn main(args: [][]u8) anyerror!u8 {
    const stdout = std.io.getStdOut().outStream();
    try stdout.print("Hello, {}!\n", .{"zig"});

    return 0;
}