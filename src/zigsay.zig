const std = @import("std");
const opt = @import("opt.zig");
const stdout = &std.io.getStdOut().writer();
const stdin = &std.io.getStdIn().reader();

const VERSION = "0.0.1";

const BUFSIZE: usize = 4096;
const MAXLEN: usize = 39;

const ZIGUANA =
    \\     .    \             .            .
    \\ .         \   _.--._       /|
    \\        .    .'()..()`.    / /
    \\            ( `-.__.-' )  ( (    .
    \\   .         \        /    \ \
    \\       .      \      /      ) )        .
    \\            .' -.__.- `.-.-'_.'
    \\ .        .'  /-____-\  `.-'       .
    \\          \  /-.____.-\  /-.
    \\           \ \`-.__.-'/ /\|\|           .
    \\          .'  `.    .'  `.
    \\          |/\/\|    |/\/\|
    \\jro
;

const ZigsayFlags = enum {
    Help,
    Version,
};

var flags = [_]opt.Flag(ZigsayFlags){
    .{
        .name = ZigsayFlags.Help,
        .long = "help",
        .short = 'h',
    },
    .{
        .name = ZigsayFlags.Version,
        .long = "version",
        .short = 'v',
    },
};

fn read_stdin(allocator: *std.mem.Allocator) ![]u8 {
    // initialize read and input buffer
    var read_buffer: [BUFSIZE]u8 = undefined;

    var input_buffer = std.ArrayList(u8).init(allocator);
    defer input_buffer.deinit();

    // read input into read_buffer, appending to input_buffer
    var size = try stdin.readAll(&read_buffer);
    while (size > 0) : (size = try stdin.readAll(&read_buffer)) {
        try input_buffer.insertSlice(input_buffer.items.len, read_buffer[0..size]);
    }

    return input_buffer.toOwnedSlice();
}

fn concat(words: [][]u8, allocator: *std.mem.Allocator) ![]u8 {
    // initialize line buffer
    var result_buffer = std.ArrayList(u8).init(allocator);
    defer result_buffer.deinit();

    for (words) |word, i| {
        if (i != 0)
            try result_buffer.append(' ');
        try result_buffer.insertSlice(result_buffer.items.len, word);
    }

    return result_buffer.toOwnedSlice();
}

fn wrap(s: []u8, allocator: *std.mem.Allocator) ![][]u8 {
    // initialize result list
    var result = std.ArrayList([]u8).init(allocator);
    defer result.deinit();

    // initialize line buffer
    var line_buffer = std.ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    // initialize iterator and word and line start
    var iterator: usize = 0;
    var word_start: usize = 0;

    // push words into line buffer, and line buffer into result list
    while (iterator < s.len) : (iterator += 1) {
        if ((iterator + 1 == s.len and !std.ascii.isSpace(s[iterator])) or
            (iterator + 1 < s.len and std.ascii.isSpace(s[iterator + 1])))
        {
            if (word_start != iterator + 1) { // end of word, not a leading whitespace
                if (line_buffer.items.len > 0 and line_buffer.items.len + (iterator - word_start + 2) > MAXLEN) {
                    // new line, since we cant fit more words
                    try result.append(line_buffer.toOwnedSlice());
                    try line_buffer.resize(0);
                }

                if (line_buffer.items.len > 0)
                    try line_buffer.append(' ');

                try line_buffer.insertSlice(line_buffer.items.len, s[word_start..(iterator + 1)]);

                // word appended is larger than MAXLEN characters, append parts now
                if (line_buffer.items.len > MAXLEN) {
                    var line = line_buffer.toOwnedSlice();
                    var blk: usize = 0;
                    while (line.len - blk * MAXLEN >= MAXLEN) : (blk += 1)
                        try result.append(line[blk * MAXLEN .. (blk + 1) * MAXLEN]);

                    try line_buffer.resize(0); // fix ownedSlice()
                    try line_buffer.insertSlice(line_buffer.items.len, line[blk * MAXLEN ..]);
                }
            }

            // start new word
            word_start = iterator + 2;
            iterator = iterator + 1;
        }
    }

    if (line_buffer.items.len > 0) {
        try result.append(line_buffer.toOwnedSlice());
    }

    return result.toOwnedSlice();
}

fn print_repeat(symbol: u8, count: usize, full_line: bool, allocator: *std.mem.Allocator) !void {
    if (full_line)
        try stdout.print(" ", .{});

    var i: usize = 0;
    while (i < count) : (i += 1)
        try stdout.print("{c}", .{symbol});

    if (full_line)
        try stdout.print(" \n", .{});
}

fn print_dialog_box(lines: [][]u8, allocator: *std.mem.Allocator) !void {
    var max_len: usize = 0;

    for (lines) |line|
        max_len = if (line.len > max_len) line.len else max_len;

    try print_repeat('_', max_len + 2, true, allocator);

    for (lines) |line, i| {
        var start_char: u8 = '|';
        var end_char: u8 = '|';

        if (lines.len == 1) {
            start_char = '<';
            end_char = '>';
        } else if (i == 0) {
            start_char = '/';
            end_char = '\\';
        } else if (i + 1 == lines.len) {
            start_char = '\\';
            end_char = '/';
        }

        try stdout.print("{c} {s} ", .{ start_char, line });
        if (line.len < max_len)
            try print_repeat(' ', max_len - line.len, false, allocator);
        try stdout.print("{c}\n", .{end_char});
    }

    try print_repeat('-', max_len + 2, true, allocator);
}

pub fn zigsay(input: []u8, allocator: *std.mem.Allocator) !void {
    // necessary due to Ziguana drawing being too long
    @setEvalBranchQuota(1500);

    // wrap to create dialogue box
    var wrapped_input = try wrap(input, allocator);

    // print dialog box
    try print_dialog_box(wrapped_input, allocator);

    // print Ziguana's body
    try stdout.print(ZIGUANA, .{});
}

pub fn main(args: [][]u8) anyerror!u8 {
    // parse arguments
    var it = opt.FlagIterator(ZigsayFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 0;
    }) |flag| {
        switch (flag.name) {
            ZigsayFlags.Help => {
                std.debug.warn("usage: cowsay [INPUT or will read from stdin]\n", .{});
                return 0;
            },
            ZigsayFlags.Version => {
                std.debug.warn("version: {s}\n", .{VERSION});
                return 0;
            },
        }
    }

    // create allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    // read from stdin or merge arguments
    var input = if (args.len == 1) try read_stdin(allocator) else try concat(args[1..], allocator);

    // call function
    zigsay(input, allocator) catch |err| {
        std.debug.warn("Error: {}\n", .{err});
        return 1;
    };

    return 0;
}
