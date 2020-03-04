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
const wc = @import("wc.zig");
const std = @import("std");
const opt = @import("opt.zig");
const stdout = &std.io.getStdOut().outStream().stream;
const warn = std.debug.warn;
const testing = std.testing;

const mainFlags = enum {
    Help,
};

var flags = [_]opt.Flag(mainFlags){
    .{
        .name = mainFlags.Help,
        .short = 'h',
        .long = "help",
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

    while (it.next_flag() catch {
        return r;
    }) |flag| {
        switch (flag.name) {
            mainFlags.Help => {
                return usage(); 
            },

            else => {
                return usage();
            },
        }
    }

    // HAS to be ./pbui APPLET_NAME [ARGS]
    var applet_name = it.next_arg().?;

    if (std.mem.eql(u8, applet_name, "basename")) {
        return basename.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "false")) {
        return fls.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "dirname")) {
        return dirname.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "head")) {
        return head.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "ls")) {
        return ls.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "mkdir")) {
        return mkdir.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "rm")) {
        return rm.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "sleep")) {
        return sleep.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "tail")) {
        return tail.main(it.argv[1..]);
    } else if (std.mem.eql(u8, applet_name, "true")) {
        return tru.main(it.argv[1..]);
    }
    else if (std.mem.eql(u8, applet_name, "wc")) {
        return wc.main(it.argv[1..]);
    } else {
        return usage();
    }
    return r;
}

test "Test assertion: addition" {
    testing.expect(add(3, 7) == 10);
}
