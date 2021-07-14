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
const zigsay = @import("zigsay.zig");
const cat = @import("cat.zig");
const std = @import("std");
const du = @import("du.zig");
const uniq = @import("uniq.zig");
const shuf = @import("shuf.zig");
const sha1 = @import("sha1.zig");
const sort = @import("sort.zig");
const pwd = @import("pwd.zig");
const stdout = &std.io.getStdOut().writer();
const warn = std.debug.warn;
const testing = std.testing;
const assert = @import("std").debug.assert;

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
        \\zigsay
        \\cat
        \\du
        \\uniq
        \\shuf
        \\sha1
        \\sort
        \\pwd
        \\
    , .{});

    const r: u8 = 1;
    return r;
}

var func_map = std.StringHashMap(fn ([][]u8) anyerror!u8).init(std.heap.page_allocator);

pub fn main() anyerror!u8 {
    const r: anyerror!u8 = 1;

    // Out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return r;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

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
    _ = try func_map.put("cat", cat.main);
    _ = try func_map.put("zigsay", zigsay.main);
    _ = try func_map.put("du", du.main);
    _ = try func_map.put("uniq", uniq.main);
    _ = try func_map.put("ls", ls.main);
    _ = try func_map.put("shuf", shuf.main);
    _ = try func_map.put("sha1", sha1.main);
    _ = try func_map.put("sort", sort.main);
    _ = try func_map.put("pwd", pwd.main);

    // check basename of exe
    var buffer: [100]u8 = undefined;
    const allocator = &std.heap.FixedBufferAllocator.init(&buffer).allocator;
    var empty = "";
    var tes = try basename.basename(args[0], empty[0..], null, allocator);

    // check if basename is right
    var yeet = func_map.get(tes) orelse null;
    if (yeet) |applet| {
        return applet(args[0..]);
    }

    // otherwise check argv for applet name
    if (args.len < 2 or std.mem.eql(u8, args[1], "-h") or std.mem.eql(u8, args[1], "--help")) {
        return usage(args);
    }

    var applet_name = args[1];

    var ab = func_map.get(applet_name) orelse usage;

    return ab(args[1..]);
}

test "Test assertion: addition" {
    std.debug.assert(3 + 7 == 10);
}
