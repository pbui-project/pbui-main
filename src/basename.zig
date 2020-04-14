const std = @import("std");
const opt = @import("opt.zig");
const Allocator = std.mem.Allocator;
const stdout = &std.io.getStdOut().outStream();
const warn = std.debug.warn;

pub fn basename(path: []const u8, terminator: []const u8, suffix: ?[]u8, allocator: *Allocator) ![]u8 {
    if (path.len == 1 and path[0] == '/') {
        return try concat(allocator, "/", terminator);
    }
    const name = std.fs.path.basename(path);

    var stripped: [*]u8 = undefined;
    if (suffix) |suf| {
        if (std.mem.eql(u8, name[name.len - suf.len ..], suf)) {
            return try concat(allocator, name[0 .. name.len - suf.len], terminator);
        }
    }
    return concat(allocator, name, terminator);
}

fn concat(allocator: *Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len);
    std.mem.copy(u8, result, a);
    std.mem.copy(u8, result[a.len..], b);
    return result;
}

const BasenameFlags = enum {
    Multiple,
    Suffix,
    Zero,
    Help,
    Version,
};

var flags = [_]opt.Flag(BasenameFlags){
    .{
        .name = BasenameFlags.Help,
        .long = "help",
    },
    .{
        .name = BasenameFlags.Version,
        .long = "version",
    },
    .{
        .name = BasenameFlags.Multiple,
        .short = 'a',
        .long = "multiple",
    },
    .{
        .name = BasenameFlags.Suffix,
        .short = 's',
        .long = "suffix",
        .mandatory = true,
        .kind = opt.ArgTypeTag.String,
    },
    .{
        .name = BasenameFlags.Zero,
        .short = 'z',
        .long = "zero",
    },
};

pub fn main(args: [][]u8) anyerror!u8 {
    var multiple: bool = false;
    var eolchar: []const u8 = "\n";
    var suffix: ?[]u8 = null;

    var it = opt.FlagIterator(BasenameFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 0;
    }) |flag| {
        switch (flag.name) {
            BasenameFlags.Help => {
                warn("(help screen here)\n", .{});
                return 0;
            },
            BasenameFlags.Version => {
                warn("(version info here)\n", .{});
                return 0;
            },
            BasenameFlags.Multiple => {
                multiple = true;
            },
            BasenameFlags.Suffix => {
                multiple = true;
                suffix = flag.value.String.?;
            },
            BasenameFlags.Zero => {
                eolchar = "";
            },
        }
    }

    var buffer: [100]u8 = undefined;
    const allocator = &std.heap.FixedBufferAllocator.init(&buffer).allocator;

    const first_maybe = it.next_arg();
    if (first_maybe) |first| {
        if (!multiple and suffix == null) {
            suffix = it.next_arg();
            if (it.next_arg()) |arg| {
                warn("{}: extra operand '{}'\n", .{ args[0], arg });
                warn("Try '{} --help' for more information.\n", .{args[0]});
                return 1;
            }
        }
        try stdout.print("{}", .{basename(first, eolchar, suffix, allocator)});
        if (multiple) {
            while (it.next_arg()) |arg| {
                try stdout.print("{}", .{basename(arg, eolchar, suffix, allocator)});
            }
        }
    } else {
        warn("{}: missing operand.\n", .{args[0]});
        warn("Try '{} --help' for more information.\n", .{args[0]});
        return 1;
    }

    return 0;
}
