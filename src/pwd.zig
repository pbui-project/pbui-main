const std = @import("std");
const opt = @import("opt.zig");

const warn = std.debug.warn;
const stdout = &std.io.getStdOut().writer();
const BUFSIZ: u16 = 4096;


const PwdFlags = enum {
    Help,
    Logical,
    Physical,
};


var flags = [_]opt.Flag(PwdFlags){
    .{
        .name = PwdFlags.Help,
        .short = 'h',
        .long = "help",
    },
    .{
        .name = PwdFlags.Logical,
        .short = 'L',
        .long = "logical",
    },
    .{
        .name = PwdFlags.Physical,
        .short = 'P',
        .long = "physical",
    },
};


pub fn main(args: [][]u8) anyerror!u8 {

    // Parse args
    var phys: bool = false;
    var it = opt.FlagIterator(PwdFlags).init(flags[0..], args);

    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            PwdFlags.Help => {
                warn("pwd [-LP]\n", .{});
                return 1;
            },
            PwdFlags.Logical => {
                phys = false;
            },
            PwdFlags.Physical => {
                phys = true;
            },
        }
    }


    //read $PWD to get pwd including symlinks
    const pwd = std.os.getenv("PWD");


    // send pwd to stdout
    if(phys){ //physical pwd
        var buffer: [BUFSIZ]u8 = undefined;
        var phys_pwd = try std.os.realpath(pwd.?, &buffer);
        try stdout.print("{s}\n", .{phys_pwd});
    }else{ //logical pwd
        try stdout.print("{s}\n", .{pwd});
    }


    return 0;
}