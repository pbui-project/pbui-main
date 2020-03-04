const std = @import("std");
const opt = @import("opt.zig");
const File = &std.io.getStdOut().outStream().stream;
const stdout = &std.io.getStdOut().outStream().stream;
const warn = std.debug.warn;
const BUFSIZ: u16 = 4096;

pub fn tail(n: u32, file: std.fs.File, is_bytes: bool) !void {
    // check if user inputs illegal line number
    if (n <= 0) {
        try stdout.print("Error: illegal count: {}\n", .{n});
        return;
    }

    var printPos = find_adjusted_start(n, file, is_bytes) catch |err| {
        try stdout.print("Error: {}\n", .{err});
        return;
    };

    // seek to start pos
    var seekable = std.fs.File.seekableStream(file);
    seekable.stream.seekTo(printPos) catch |err| {
        try stdout.print("Error: cannot seek file: {}\n", .{err});
        return;
    };

    // print file from start pos
    var in_stream = std.fs.File.inStream(file);
    print_stream(&in_stream.stream) catch |err| {
        try stdout.print("Error: cannot print file: {}\n", .{err});
        return;
    };
}

pub fn alt_tail(n: u32, file: std.fs.File, is_bytes: bool) !void {
    // check if user inputs illegal line number
    if (n <= 0) {
        try stdout.print("Error: illegal count: {}\n", .{n});
        return;
    }
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    const lines = try allocator.alloc([]u8, n);

    var lineBuf: [BUFSIZ]u8 = undefined;

    var i: u32 = 0;

    while (file.inStream().stream.readUntilDelimiterOrEof(lineBuf[0..], '\n')) |segment| {
        if (segment == null) break;

        std.mem.copy(?[]u8, lines[i][0..], segment[0..]);
        i += 1;
        if (i >= n) i = 0;
        for (lines) |row| {
            try stdout.print("{}\n", .{row});
        }
        try stdout.print("\n\n\n", .{});
    } else |err| return err;

    for (lines) |row| {
        try stdout.print("{}\n", .{row});
    }
}

// Prints stream from current pointer to end of file in BUFSIZ
// chunks.
pub fn print_stream(stream: *std.fs.File.InStream.Stream) anyerror!void {
    var buffer: [BUFSIZ]u8 = undefined;
    var size = try stream.readFull(&buffer);

    // loop until EOF hit
    while (size > 0) : (size = (try stream.readFull(&buffer))) {
        try stdout.print("{}", .{buffer[0..size]});
    }
}

pub fn find_adjusted_start(n: u32, file: std.fs.File, is_bytes: bool) anyerror!u64 {
    // Create streams for file access
    var seekable = std.fs.File.seekableStream(file);
    var in_stream = std.fs.File.inStream(file);

    // Find ending position of file
    var endPos: u64 = seekable.stream.getEndPos() catch |err| {
        try stdout.print("Error: cannot find endpos of file: {}\n", .{err});
        return err;
    };

    // set to EOF to step backwards from
    seekable.stream.seekTo(endPos) catch |err| {
        try stdout.print("Error: cannot seek file: {}\n", .{err});
        return err;
    };

    // step backwards until front of file or n new lines found
    var offset: u64 = 0;
    var amt_read: u32 = 0;
    var char: u8 = undefined;
    while (amt_read < (n + 1) and offset < endPos) {
        offset += 1;
        seekable.stream.seekTo(endPos - offset) catch |err| {
            try stdout.print("Error: cannot seek: {}\n", .{err});
            return err;
        };

        char = in_stream.stream.readByte() catch |err| {
            try stdout.print("Error: cannot read byte: {}\n", .{err});
            return err;
        };
        if (char == '\n' and !is_bytes) {
            amt_read += 1;
        } else if (is_bytes) {
            amt_read += 1;
        }
    }

    // adjust offset if consumed \n
    if (offset < endPos) offset -= 1;

    return endPos - offset;
}

pub fn str_to_n(str: []u8) anyerror!u32 {
    return std.fmt.parseInt(u32, str, 10) catch |err| {
        return 0;
    };
}

const TailFlags = enum {
    Lines,
    Bytes,
    Help,
    Version,
};

var flags = [_]opt.Flag(TailFlags){
    .{
        .name = TailFlags.Help,
        .long = "help",
    },
    .{
        .name = TailFlags.Version,
        .long = "version",
    },
    .{
        .name = TailFlags.Bytes,
        .short = 'c',
        .kind = opt.ArgTypeTag.String,
        .mandatory = true,
    },
    .{
        .name = TailFlags.Lines,
        .short = 'n',
        .kind = opt.ArgTypeTag.String,
        .mandatory = true,
    },
};

const PrintOptions = enum {
    Full,
    Lines,
    Bytes,
};

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    var opts: PrintOptions = PrintOptions.Full;

    var length: []u8 = undefined;

    var it = opt.FlagIterator(TailFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return;
    }) |flag| {
        switch (flag.name) {
            TailFlags.Help => {
                warn("(help screen here)\n", .{});
                return;
            },
            TailFlags.Version => {
                warn("(version info here)\n", .{});
                return;
            },
            TailFlags.Bytes => {
                opts = PrintOptions.Bytes;
                length = flag.value.String.?;
            },
            TailFlags.Lines => {
                opts = PrintOptions.Lines;
                length = flag.value.String.?;
            },
        }
    }

    var n: u32 = 10;
    if (opts != PrintOptions.Full) n = try str_to_n(length[0..]);

    var files = std.ArrayList([]u8).init(std.heap.page_allocator);
    while (it.next_arg()) |file_name| {
        try files.append(file_name);
    }

    if (files.len > 0) {
        for (files.toSliceConst()) |file_name| {
            const file = std.fs.File.openRead(file_name[0..]) catch |err| {
                try stdout.print("Error: cannot open file {}\n", .{file_name});
                return;
            };
            if (files.len >= 2) try stdout.print("==> {} <==\n", .{file_name});
            try tail(n, file, opts == PrintOptions.Bytes);
        }
    } else {
        const file = std.io.getStdIn();
        try alt_tail(n, file, opts == PrintOptions.Bytes);
        file.close();
    }
}
