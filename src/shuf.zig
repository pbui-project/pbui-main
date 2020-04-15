const std = @import("std");
const opt = @import("opt.zig");
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const stdout = &std.io.getStdOut().outStream();
const rand = std.rand.DefaultPrng; // fast unbiased random numbers
const time = std.time;

pub fn shuf(file: std.fs.File, options: PrintOptions) !void {
    var lines = std.ArrayList([]u8).init(std.heap.page_allocator);
    defer lines.deinit();

    var line: []u8 = undefined;

    while (true) {
        // gross stuff pls pr and make this nice
        line = file.inStream().readUntilDelimiterAlloc(std.heap.page_allocator, '\n', std.math.maxInt(u32)) catch break;

        try lines.append(line);
    }

    var prng = rand.init(time.milliTimestamp());

    prng.random.shuffle([]u8, lines.items[0..]);

    for (lines.items) |row| {
        warn("{}\n", .{row});
        std.heap.page_allocator.free(row);
    }
}

const ShufFlags = enum {
    Help,
    Version,
};

var flags = [_]opt.Flag(ShufFlags){
    .{
        .name = ShufFlags.Help,
        .long = "help",
    },
    .{
        .name = ShufFlags.Version,
        .long = "version",
    },
};

const PrintOptions = enum {
    Default,
};

pub fn main(args: [][]u8) anyerror!u8 {
    var options: PrintOptions = PrintOptions.Default;

    var it = opt.FlagIterator(ShufFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            ShufFlags.Help => {
                warn("{} [FILE_NAME]\n", .{args[0]});
                return 0;
            },
            ShufFlags.Version => {
                warn("TODO", .{});
                return 0;
            },
        }
    }

    var input = it.next_arg();

    if (input) |name| {
        const file = std.fs.cwd().openFile(name[0..], std.fs.File.OpenFlags{ .read = true, .write = false }) catch |err| {
            try stdout.print("Error: cannot open file {}\n", .{name});
            return 1;
        };
        try shuf(file, options);
        file.close();
    } else {
        // stdin
        try shuf(std.io.getStdIn(), options);
    }
    return 0;
}
