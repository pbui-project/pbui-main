const basename = @import("basename.zig");
const dirname = @import("dirname.zig");
const fls = @import("false.zig");
const ls = @import("ls.zig");
const mkdir = @import("mkdir.zig");
const rm = @import("rm.zig");
const sleep = @import("sleep.zig");
const tail = @import("tail.zig");
const tru = @import("true.zig");
const head = @import("head.zig");

const std = @import("std");
const opt = @import("opt.zig");
const stdout = &std.io.getStdOut().outStream().stream;
const warn = std.debug.warn;
const testing = std.testing;

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

var flags = [_]opt.Flag(mainFlags){
    .{
        .name = mainFlags.Help,
        .short = 'h',
        .long = "help",
    },
    .{
        .name = mainFlags.Basename,
        .long = "basename",
    },
    .{
        .name = mainFlags.Dirname,
        .long = "dirname",
    },
    .{
        .name = mainFlags.False,
        .long = "false",
    },
    .{
        .name = mainFlags.Head,
        .long = "head",
    },
    .{
        .name = mainFlags.LS,
        .long = "ls",
    },
    .{
        .name = mainFlags.MKDir,
        .long = "mkdir",
    },
    .{
        .name = mainFlags.RM,
        .long = "rm",
    },
    .{
        .name = mainFlags.Sleep,
        .long = "sleep",
    },
    .{
        .name = mainFlags.Tail,
        .long = "tail",
    },
    .{
        .name = mainFlags.True,
        .long = "true",
    },
};

pub fn usage() anyerror!u8 {
    try stdout.print("Usage: ./pbui APPLET [arguments]\n\nApplets list: \n  basename\n  dirname\n  false\n  head\n  ls\n  mkdir\n  rm\n  sleep\n  tail\n  true\n", .{});

    const r: u8 = 1;
    return r;
}

pub fn main() anyerror!u8 {
    const r: anyerror!u8 = 1;

    // Out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return r;
    };

    defer std.process.argsFree(std.heap.page_allocator, args);

    // Check arg length
    if (args.len < 2) {
        return usage();
    }

    var it = opt.FlagIterator(mainFlags).init(flags[0..], args);

    // TODO CHECK FOR HELP OR VERSION FLAG

    // HAS to be ./pbui APPLET_NAME jaklsfjljdklsafjldasjlfalkdsjf
    var applet_name = it.next_arg().?;

    if (std.mem.eql(u8, applet_name, "basename")) {
        warn("Call to basename (missing arguments)\n", .{});
        return basename.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "false")) {
        warn("Call to false (missing arguments)\n", .{});
        return fls.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "dirname")) {
        warn("Call to dirname (missing arguments)\n", .{});
        return dirname.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "head")) {
        warn("Call to head (missing arguments)\n", .{});
        return head.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "ls")) {
        warn("Call to ls (missing arguments)\n", .{});
        return ls.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "mkdir")) {
        warn("Call to mkdir (missing arguments)\n", .{});
        return mkdir.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "rm")) {
        warn("Call to rm (missing arguments)\n", .{});
        return rm.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "sleep")) {
        warn("Call to sleep (missing arguments)\n", .{});
        return sleep.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "tail")) {
        warn("Call to tail (missing arguments)\n", .{});
        return tail.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "true")) {
        warn("Call to true (missing arguments)\n", .{});
        return tru.main(it.argv[1..]);
    } else {
        warn("Bleh", .{});
    }
    return r;
}

test "Test assertion: addition" {
    testing.expect(add(3, 7) == 10);
}
