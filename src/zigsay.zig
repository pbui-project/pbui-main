const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;
const stdin = &std.io.getStdIn().inStream().stream;

var global_allocator: *mem.Allocator = undefined;

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

fn read_stdin() ![]u8 {
    // open stdin in a buffered stream
    var buffered_stream = std.io.BufferedInStream(std.fs.File.InStream.Error).init(stdin);

    // initialize read and input buffer
    var read_buffer: [BUFSIZE]u8 = undefined;

    var input_buffer = try std.Buffer.init(std.testing.allocator, "");
    defer input_buffer.deinit();

    // read input into read_buffer, appending to input_buffer
    var size = try buffered_stream.stream.readFull(&read_buffer);
    while (size > 0) : (size = try buffered_stream.stream.readFull(&read_buffer)) {
        try input_buffer.append(read_buffer[0..size]);
    }

    return input_buffer.toOwnedSlice();
}

fn concat(words: [][]u8) ![]u8 {
    // initialize line buffer
    var result_buffer = try std.Buffer.init(std.testing.allocator, "");
    defer result_buffer.deinit();

    for (words) |word, i| {
        if (i != 0)
            try result_buffer.append(" ");
        try result_buffer.append(word);
    }

    return result_buffer.toOwnedSlice();
}

fn wrap(s: []u8) ![][]u8 {
    // initialize result list
    var result = std.ArrayList([]u8).init(std.testing.allocator);
    defer result.deinit();

    // initialize line buffer
    var line_buffer = try std.Buffer.init(std.testing.allocator, "");
    defer line_buffer.deinit();

    // initialize iterator and word and line start
    var iterator: usize = 0;
    var word_start: usize = 0;

    // push words into line buffer, and line buffer into result list
    while (iterator < s.len) : (iterator += 1) {
        if ((iterator + 1 == s.len and !std.fmt.isWhiteSpace(s[iterator])) or
            (iterator + 1 < s.len and std.fmt.isWhiteSpace(s[iterator + 1]))) {

            if (word_start != iterator + 1) { // end of word, not a leading whitespace
                if (line_buffer.len() > 0 and line_buffer.len() + (iterator - word_start + 2) > MAXLEN) {
                    // new line, since we cant fit more words
                    try result.append(line_buffer.toOwnedSlice());
                    try line_buffer.resize(0);
                }

                if (line_buffer.len() > 0)
                    try line_buffer.append(" ");

                try line_buffer.append(s[word_start..(iterator+1)]);

                // word appended is larger than MAXLEN characters, append parts now
                if (line_buffer.len() > MAXLEN) {
                    var line = line_buffer.toOwnedSlice();
                    var blk: usize = 0;
                    while (line.len - blk * MAXLEN >= MAXLEN) : (blk += 1)
                        try result.append(line[blk*MAXLEN..(blk+1)*MAXLEN]);

                    try line_buffer.resize(0); // fix ownedSlice()
                    try line_buffer.append(line[blk*MAXLEN..]);
                }
            }

            // start new word
            word_start = iterator + 2;
            iterator = iterator + 1;
        }
    }

    if (line_buffer.len() > 0) {
        try result.append(line_buffer.toOwnedSlice());
    }

    return result.toOwnedSlice();
}

fn print_repeat(symbol: u8, count: usize, full_line: bool) !void {
    if (full_line)
        try stdout.print(" ", .{});

    var i: usize = 0;
    while (i < count) : (i += 1)
        try stdout.print("{c}", .{symbol});

    if (full_line)
        try stdout.print(" \n", .{});
}

fn print_dialog_box(lines: [][]u8) !void {
    var max_len: usize = 0;

    for (lines) |line|
        max_len = if (line.len > max_len) line.len else max_len;

    try print_repeat('_', max_len + 2, true);

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

        try stdout.print("{c} {} ", .{start_char, line});
        if (line.len < max_len)
            try print_repeat(' ', max_len - line.len, false);
        try stdout.print("{c}\n", .{end_char});
    }

    try print_repeat('-', max_len + 2, true);
}

pub fn zigsay(input: []u8) !void {
    // necessary due to iguana drawing being too long
    @setEvalBranchQuota(1500);

    // wrap to create dialogue box
    var wrapped_input = try wrap(input);

    // print dialog box
    try print_dialog_box(wrapped_input);

    // print Ziguana's body
    try stdout.print(ZIGUANA, .{});
}

pub fn main(args: [][]u8) anyerror! u8{
    // usage information
    if (args.len > 1 and std.mem.eql(u8, args[1], "-h")) {
        std.debug.warn("usage: cowsay [INPUT or will read from stdin]\n", .{});
        return 0;
    }

    // read from stdin or merge arguments
    var input = if (args.len == 1) try read_stdin() else try concat(args[1..]);

    // call function
    zigsay(input) catch |err| {
        std.debug.warn("Error: {}\n", .{err});
        return 1;
    };

    return 0;
}

