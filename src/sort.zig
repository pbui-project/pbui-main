const std = @import("std");
const opt = @import("opt.zig");
const comparator = @import("ls.zig").compare_words;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const stdout = &std.io.getStdOut().outStream();

/// memory belongs to caller
pub fn sort(allocator: *Allocator, file: std.fs.File, options: PrintOptions) !std.ArrayList([]u8) {
    var lines = std.ArrayList([]u8).init(allocator);

    while (true) {
        var line: []u8 = get_line(allocator, file) catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };
        try lines.append(line);
    }

    std.sort.sort([]const u8, lines.items[0..], {}, comparator);

    if (options == PrintOptions.Reverse) {
        var i: u32 = 0;
        while (i < lines.items.len / 2) : (i += 1) {
            var temp = lines.items[i];
            lines.items[i] = lines.items[lines.items.len - i - 1];
            lines.items[lines.items.len - i - 1] = temp;
        }
    }

    return lines;
}

/// Get a single line of file -- needs to be freed bor
pub fn get_line(allocator: *Allocator, file: std.fs.File) ![]u8 {
    var char: u8 = undefined;
    var stream = std.fs.File.inStream(file);
    var i: u64 = 0;

    char = try stream.readByte(); // err if no stream
    var buffer: []u8 = try allocator.alloc(u8, 0);

    while (char != -1) : (char = stream.readByte() catch {
        return buffer;
    }) {
        if (char == '\n') break;
        buffer = try allocator.realloc(buffer, i + 1);
        buffer[i] = char;
        i += 1;
    }
    return buffer;
}

const SortFlags = enum {
    Help,
    Version,
    Reverse,
};

var flags = [_]opt.Flag(SortFlags){
    .{
        .name = SortFlags.Help,
        .long = "help",
    },
    .{
        .name = SortFlags.Version,
        .long = "version",
    },
    .{
        .name = SortFlags.Reverse,
        .short = 'r',
    },
};

const PrintOptions = enum {
    Reverse,
    Default,
};

pub fn main(args: [][]u8) anyerror!u8 {
    var options: PrintOptions = PrintOptions.Default;

    var it = opt.FlagIterator(SortFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            SortFlags.Help => {
                warn("{} [-r] [FILE_NAME]\n", .{args[0]});
                return 0;
            },
            SortFlags.Version => {
                warn("TODO", .{});
                return 0;
            },
            SortFlags.Reverse => {
                options = PrintOptions.Reverse;
            },
        }
    }

    var input = it.next_arg();
    var lines: std.ArrayList([]u8) = undefined;
    if (input) |name| {
        const file = std.fs.cwd().openFile(name[0..], std.fs.File.OpenFlags{ .read = true, .write = false }) catch |err| {
            try stdout.print("Error: cannot open file {}\n", .{name});
            return 1;
        };
        lines = try sort(std.heap.page_allocator, file, options);
        file.close();
    } else {
        // stdin
        lines = try sort(std.heap.page_allocator, std.io.getStdIn(), options);
    }
    for (lines.items) |line| {
        warn("{}\n", .{line});
        std.heap.page_allocator.free(line);
    }
    lines.deinit();
    return 0;
}

test "basic sort test" {
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

    var result = try sort(std.heap.page_allocator, file, PrintOptions.Default);
    file.close();

    var i: u8 = 0;
    while (i < result.items.len) : (i += 1) {
        std.debug.assert(std.mem.eql(u8, result.items[i], expected[i][0..]));
        std.heap.page_allocator.free(result.items[i]);
    }
    result.deinit();
}
