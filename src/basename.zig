const std = @import("std");
const opt = @import("opt.zig");
const stdout = &std.io.getStdOut().outStream().stream;
const warn = std.debug.warn;

pub fn basename(path: []const u8, terminator: u8, suffix: ?[]u8) !void {
    // basename calls basenameposix if not windows... more robust
    // to just use basename

    // GNU basename does this.  I wonder if it works the same way on Windows.
    if (path.len == 1 and path[0] == '/') {
        try stdout.print("/{c}", .{terminator});
        return;
    }
    const name = std.fs.path.basename(path);
    var stripped: [*]u8 = undefined;
    if (suffix) |suf| {
        if (std.mem.eql(u8, name[name.len - suf.len ..], suf)) {
            try stdout.print("{}{c}", .{ name[0 .. name.len - suf.len], terminator });
            return;
        }
    }
    try stdout.print("{}{c}", .{ name, terminator });
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

pub fn main() anyerror!u8 {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return 1;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    var multiple: bool = false;
    var eolchar: u8 = '\n';
    var suffix: ?[]u8 = null;
    // check len of args
    // if (args.len != 2) {
    //     try stdout.print("usage: ./basename FILENAME\n", .{});
    //     return;
    // }

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
                eolchar = '\x00';
            },
        }
    }

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
        try basename(first, eolchar, suffix);
        if (multiple) {
            while (it.next_arg()) |arg| {
                try basename(arg, eolchar, suffix);
            }
        }
    } else {
        warn("{}: missing operand.\n", .{args[0]});
        warn("Try '{} --help' for more information.\n", .{args[0]});
        return 1;
    }

    return 0;
}
