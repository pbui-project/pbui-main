const std = @import("std");
const warn = std.debug.warn;
const opt = @import("opt.zig");
const stdout = &std.io.getStdOut().outStream();

pub fn dirname(paths: std.ArrayList([]u8), zero: bool) !void {
    // dirname calls dirnameposix if not windows... more robust
    // to just use Dirname
    const terminator: u8 = if (zero) '\x00' else '\n';

    // loop through paths and call dirname
    var name: ?[]const u8 = null;
    for (paths.items) |path| {
        name = std.fs.path.dirname(path) orelse ".";

        try stdout.print("{}{c}", .{ name, terminator });
    }
}

const DirnameFlags = enum {
    Zero,
    Help,
    Version,
};

var flags = [_]opt.Flag(DirnameFlags){
    .{
        .name = DirnameFlags.Help,
        .long = "help",
    },
    .{
        .name = DirnameFlags.Version,
        .long = "version",
    },
    .{
        .name = DirnameFlags.Zero,
        .short = 'z',
        .long = "zero",
    },
};

pub fn main(args: [][]u8) anyerror!u8 {
    var zero: bool = false;

    var it = opt.FlagIterator(DirnameFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 0;
    }) |flag| {
        switch (flag.name) {
            DirnameFlags.Help => {
                warn("dirname FILE_NAME\n", .{});
                return 0;
            },
            DirnameFlags.Version => {
                warn("(version info here)\n", .{});
                return 0;
            },
            DirnameFlags.Zero => {
                zero = true;
            },
        }
    }

    var files = std.ArrayList([]u8).init(std.heap.page_allocator);
    while (it.next_arg()) |file_name| {
        try files.append(file_name);
    }

    if (files.items.len > 0) {
        try dirname(files, zero);
        return 0;
    }
    warn("dirname FILE_NAME\n", .{});
    return 1;
}
