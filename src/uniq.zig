const std = @import("std");
const opt = @import("opt.zig");
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const stdout = &std.io.getStdOut().writer();

/// Print uniq adjacent lines... no flags yet
pub fn uniq(file: std.fs.File, options: PrintOptions) !void {
    // read first line of input
    var old_line: []u8 = get_line(std.heap.page_allocator, file) catch |err| {
        if (err == error.EndOfStream) {
            return;
        }
        return err;
    };
    var line: []u8 = undefined;
    var matched: u32 = 0;
    // Read until EOF
    while (true) {
        // read input & break if end of file
        line = get_line(std.heap.page_allocator, file) catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };
        // if not equal check if should print
        if (!std.mem.eql(u8, old_line, line)) {
            switch (options) {
                .Duplicate => if (matched > 0) warn("{s}\n", .{old_line}),
                .Unique => if (matched == 0) warn("{s}\n", .{old_line}),
                .Count => warn("{:>4} {s}\n", .{ matched + 1, old_line }),
                else => warn("{s}\n", .{old_line}),
            }
            matched = 0;
        } else {
            // Save matched till last line of match & then try to print
            matched += 1;
        }
        // free memory for lines we no longer need
        std.heap.page_allocator.free(old_line);
        old_line = line;
    }

    switch (options) {
        .Duplicate => if (matched > 0) warn("{s}\n", .{old_line}),
        .Unique => if (matched == 0) warn("{s}\n", .{old_line}),
        .Count => warn("{:>4} {s}\n", .{ matched + 1, old_line }),
        else => warn("{s}\n", .{old_line}),
    }
    std.heap.page_allocator.free(old_line);
}

/// Get a single line of file -- needs to be freed bor
pub fn get_line(allocator: *Allocator, file: std.fs.File) ![]u8 {
    var char: u8 = undefined;
    var stream = std.fs.File.reader(file);
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

const UniqFlags = enum {
    Help,
    Version,
    OnlyUnique,
    OnlyDuplicate,
    OnlyCount,
};

var flags = [_]opt.Flag(UniqFlags){
    .{
        .name = UniqFlags.Help,
        .long = "help",
    },
    .{
        .name = UniqFlags.Version,
        .long = "version",
    },
    .{
        .name = UniqFlags.OnlyUnique,
        .short = 'u',
    },
    .{
        .name = UniqFlags.OnlyDuplicate,
        .short = 'd',
    },
    .{
        .name = UniqFlags.OnlyCount,
        .short = 'c',
    },
};

const PrintOptions = enum {
    Unique,
    Duplicate,
    Count,
    Default,
};

pub fn main(args: [][]u8) anyerror!u8 {
    var options: PrintOptions = PrintOptions.Default;

    var it = opt.FlagIterator(UniqFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            UniqFlags.Help => {
                warn("{s} [-c | -d | -u ] [FILE_NAME]\n", .{args[0]});
                return 0;
            },
            UniqFlags.Version => {
                warn("TODO", .{});
                return 0;
            },
            UniqFlags.OnlyUnique => {
                options = PrintOptions.Unique;
            },
            UniqFlags.OnlyDuplicate => {
                options = PrintOptions.Duplicate;
            },
            UniqFlags.OnlyCount => {
                options = PrintOptions.Count;
            },
        }
    }

    var input = it.next_arg();

    if (input) |name| {
        const file = std.fs.cwd().openFile(name[0..], std.fs.File.OpenFlags{ .read = true, .write = false }) catch |err| {
            try stdout.print("Error: cannot open file {s}\n", .{name});
            return 1;
        };
        try uniq(file, options);
        file.close();
    } else {
        // stdin
        try uniq(std.io.getStdIn(), options);
    }
    return 0;
}
