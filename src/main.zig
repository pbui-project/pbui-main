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

pub fn usage(args: [][]u8) anyerror!u8 {
    try stdout.print(
        \\Usage: ./pbui APPLET [arguments]
        \\
        \\Applets list:
        \\basename
        \\dirname
        \\false
        \\head
        \\ls
        \\mkdir
        \\rm
        \\sleep
        \\tail
        \\true
        \\
    , .{});

    const r: u8 = 1;
    return r;
}

var func_map = std.StringHashMap(fn ([][]u8) anyerror!u8).init(std.heap.direct_allocator);

pub fn main() anyerror!u8 {
    const r: anyerror!u8 = 1;

    // Out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return r;
    };

    defer std.process.argsFree(std.heap.page_allocator, args);

    var it = opt.FlagIterator(mainFlags).init(flags[0..], args);

    // TODO FLAGS DONT WORK
    // Find where the applet name is if it is there...
    // then splice the array
    // look for pbui flags on the left
    // then applet on right

    while (it.next_flag() catch {
        return r;
    }) |flag| {
        switch (flag.name) {
            mainFlags.Help => {
                return usage(it.argv);
            },

            else => {
                return usage(it.argv);
            },
        }
    }

    _ = try func_map.put("basename", basename.main);
    _ = try func_map.put("false", fls.main);
    _ = try func_map.put("dirname", dirname.main);
    _ = try func_map.put("head", head.main);
    _ = try func_map.put("mkdir", mkdir.main);
    _ = try func_map.put("rm", rm.main);
    _ = try func_map.put("sleep", sleep.main);
    _ = try func_map.put("tail", tail.main);
    _ = try func_map.put("true", tru.main);
    _ = try func_map.put("wc", wc.main);

    if (it.argv.len < 2) {
        return usage(it.argv);
    }

    var applet_name = it.next_arg().?;

    var ab = func_map.getValue(applet_name) orelse usage;

    return ab(it.argv[1..]);
}

test "Test assertion: addition" {
    testing.expect(add(3, 7) == 10);
}
