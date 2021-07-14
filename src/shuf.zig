const std = @import("std");
const opt = @import("opt.zig");
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const stdout = &std.io.getStdOut().writer();
const rand = std.rand.DefaultPrng; // fast unbiased random numbers
const time = std.time;

/// Returns shuffled arraylist of []u8's, caller owns memory
pub fn shuf(file: std.fs.File, seed: u64) !std.ArrayList([]u8) {
    var lines = std.ArrayList([]u8).init(std.heap.page_allocator);

    var line: []u8 = undefined;

    while (true) {
        // gross stuff pls pr and make this nice
        line = file.reader().readUntilDelimiterAlloc(std.heap.page_allocator, '\n', std.math.maxInt(u32)) catch break;

        try lines.append(line);
    }

    var prng = rand.init(seed);

    prng.random.shuffle([]u8, lines.items[0..]);

    return lines;
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
    var it = opt.FlagIterator(ShufFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            ShufFlags.Help => {
                warn("{s} [FILE_NAME]\n", .{args[0]});
                return 0;
            },
            ShufFlags.Version => {
                warn("TODO", .{});
                return 0;
            },
        }
    }

    var input = it.next_arg();

    var lines: std.ArrayList([]u8) = undefined;

    if (input) |name| {
        const file = std.fs.cwd().openFile(name[0..], std.fs.File.OpenFlags{ .read = true, .write = false }) catch |err| {
            try stdout.print("Error: cannot open file {s}\n", .{name});
            return 1;
        };
        lines = try shuf(file, @intCast(u64, time.milliTimestamp()));

        file.close();
    } else {
        // stdin
        lines = try shuf(std.io.getStdIn(), @intCast(u64, time.milliTimestamp()));
    }
    for (lines.items) |row| {
        warn("{s}\n", .{row});
        std.heap.page_allocator.free(row);
    }
    lines.deinit();
    return 0;
}

test "basic shuffle test" {
    const file = try std.fs.cwd().createFile("/tmp/testshuff", std.fs.File.CreateFlags{ .read = true });

    _ = try file.write(
        \\2
        \\1
        \\3
        \\4
        \\5
    );

    const expected = [5][1]u8{ [_]u8{'1'}, [_]u8{'2'}, [_]u8{'3'}, [_]u8{'4'}, [_]u8{'5'} };

    // seek back to start
    try file.seekTo(0);

    var result = try shuf(file, 0);
    file.close();

    var i: u8 = 0;
    while (i < result.items.len) : (i += 1) {
        std.debug.assert(std.mem.eql(u8, result.items[i], expected[i][0..]));
        std.heap.page_allocator.free(result.items[i]);
    }
    result.deinit();
}
