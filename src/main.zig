const basename  = @import("basename.zig");
const dirname   = @import("dirname.zig");
const fls       = @import("false.zig");
const ls        = @import("ls.zig");
const mkdir     = @import("mkdir.zig");
const rm        = @import("rm.zig");
const sleep     = @import("sleep.zig");
const tail      = @import("tail.zig");
const tru       = @import("true.zig");     
const head      = @import("head.zig");

const std       = @import("std");
const opt       = @import("opt.zig");
const stdout    = &std.io.getStdOut().outStream().stream;
const warn      = std.debug.warn;
const testing   = std.testing;

const mainFlags = enum {
    Help,
    Basename,
    Dirname,
    False,
    Head,
    LS,
    MKDir,
    RM,
    Sleep,
    Tail,
    True,
};

var flags = [_]opt.Flag(mainFlags) {
    .{
        .name    = mainFlags.Help,
        .short  = 'h',
        .long   = "help"
    },
    .{ 
        .name   = mainFlags.Basename,
        .long   = "basename",
    },
    .{
        .name   = mainFlags.Dirname,
        .long   = "dirname",
    },
    .{
        .name   = mainFlags.False,
        .long   = "false",
    },
    .{
        .name   = mainFlags.Head,
        .long   = "head",
    },
    .{
        .name   = mainFlags.LS,
        .long   = "ls",
    },
    .{
        .name   = mainFlags.MKDir,
        .long   = "mkdir",
    },
    .{
        .name   = mainFlags.RM,
        .long   = "rm",
    },
    .{
        .name   = mainFlags.Sleep,
        .long   = "sleep",
    },
    .{
        .name   = mainFlags.Tail,
        .long   = "tail",
    },
    .{
        .name   = mainFlags.True,
        .long   = "true",
    },
};

pub fn usage() !void {
    try stdout.print("Usage: ./pbui APPLET [arguments]\n\nApplets list: \n  basename\n  dirname\n  false\n  head\n  ls\n  mkdir\n  rm\n  sleep\n  tail\n  true\n", .{});

    return;
}

pub fn main() !void {
    // Out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };

    defer std.process.argsFree(std.heap.page_allocator, args);

    // Check arg length
    if (args.len < 2) {
        try usage();
        return;
    }

    var it = opt.FlagIterator(mainFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return;
    }) |flag| {
        switch (flag.name) {
            mainFlags.Help => {
                try usage();
            },
            mainFlags.Basename => {
                warn("Call to basename (missing arguments)\n", .{});
                try basename.main();
            },
            mainFlags.Dirname => {
                warn("Call to dirname (missing arguments)\n", .{});
                try dirname.main();
            },
            mainFlags.False => {
                warn("Call to false (missing arguments)\n", .{});
                try fls.main();
            },
            mainFlags.Head => {
                warn("Call to head (missing arguments)\n", .{});
                try head.main();
            },
            mainFlags.LS => {
                warn("Call to ls (missing arguments)\n", .{});
                try ls.main();
            },
            mainFlags.MKDir => {
                warn("Call to mkdir (missing arguments)\n", .{});
                try mkdir.main();
            },
            mainFlags.RM => {
                warn("Call to rm (missing arguments)\n", .{});
                try rm.main();
            },
            mainFlags.Sleep => {
                warn("Call to sleep (missing arguments)\n", .{});
                try sleep.main();
            },
            mainFlags.Tail => {
                warn("Call to tail (missing arguments)\n", .{});
                try tail.main();
            },
            mainFlags.True => {
                warn("Call to true (missing arguments)\n", .{});
                try tru.main();
            },
        }
    }
}

test "Test assertion: addition" {
    testing.expect(add(3, 7) == 10);
}
