const std = @import("std");
const opt = @import("opt.zig");
const File = std.fs.File;
const stdout = &std.io.getStdOut().outStream();
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
    seekable.seekTo(printPos) catch |err| {
        try stdout.print("Error: cannot seek file: {}\n", .{err});
        return;
    };

    // print file from start pos
    var in_stream = std.fs.File.inStream(file);
    print_stream(&in_stream) catch |err| {
        try stdout.print("Error: cannot print file: {}\n", .{err});
        return;
    };
}

// for stdin reading
pub fn alt_tail(n: u32, file: std.fs.File, is_bytes: bool) !void {
    // check if user inputs illegal line number
    if (n <= 0) {
        try stdout.print("Error: illegal count: {}\n", .{n});
        return;
    }
    const allocator = std.heap.c_allocator;

    const lines = try allocator.alloc([]u8, n);

    // make sure stuff is actually there in array in comparison later
    var lineBuf: [BUFSIZ]u8 = undefined;

    var i: u32 = 0;

    var top: u32 = 0; // oldest row
    var first_time: bool = true;

    // add lines to buffer
    while (file.inStream().readUntilDelimiterOrEof(lineBuf[0..], '\n')) |segment| {
        if (segment == null) break;
        // dealloc if already exist
        if (!first_time) allocator.free(lines[i]);
        lines[i] = try allocator.alloc(u8, segment.?.len);
        std.mem.copy(u8, lines[i], segment.?);
        i += 1;
        top = i; // i love top
        if (i >= n) {
            i = 0;
            first_time = false;
        }
    } else |err| return err;

    var new_n: u32 = if (first_time) i else n;

    var x: u32 = top;
    if (!is_bytes) {
        i = 0;
        while ((i == 0 or x != top) and i <= new_n) : (x += 1) {
            // loop buffer location around
            if (x >= new_n) x = 0;
            try stdout.print("{}\n", .{lines[x]});
            i += 1;
        }
    } else {
        x -= 1; // go to bottom and work up

        // find starting point
        var bytes_ate: usize = 0;
        var start_pos: usize = 0;
        while (x != top + 1 or bytes_ate == 0) : (x -= 1) {
            bytes_ate += lines[x].len + 1;
            if (bytes_ate >= n) {
                start_pos = bytes_ate - n;
                break;
            }
            if (x <= 0) x = new_n;
        }

        // print till end
        while (x != top) : (x += 1) {
            if (x >= new_n) x = 0;
            if (!first_time and x > top) break;
            try stdout.print("{}\n", .{lines[x][start_pos..]});
            start_pos = 0;
        }
    }
}

// Prints stream from current pointer to end of file in BUFSIZ
// chunks.
pub fn print_stream(stream: *std.fs.File.InStream) anyerror!void {
    var buffer: [BUFSIZ]u8 = undefined;
    var size = try stream.readAll(&buffer);

    // loop until EOF hit
    while (size > 0) : (size = (try stream.readAll(&buffer))) {
        try stdout.print("{}", .{buffer[0..size]});
    }
}

pub fn find_adjusted_start(n: u32, file: std.fs.File, is_bytes: bool) anyerror!u64 {
    // Create streams for file access
    var seekable = std.fs.File.seekableStream(file);
    var in_stream = std.fs.File.inStream(file);

    // Find ending position of file
    var endPos: u64 = seekable.getEndPos() catch |err| {
        try stdout.print("Error: cannot find endpos of file: {}\n", .{err});
        return err;
    };

    // set to EOF to step backwards from
    seekable.seekTo(endPos) catch |err| {
        try stdout.print("Error: cannot seek file: {}\n", .{err});
        return err;
    };

    // step backwards until front of file or n new lines found
    var offset: u64 = 0;
    var amt_read: u32 = 0;
    var char: u8 = undefined;
    while (amt_read < (n + 1) and offset < endPos) {
        offset += 1;
        seekable.seekTo(endPos - offset) catch |err| {
            try stdout.print("Error: cannot seek: {}\n", .{err});
            return err;
        };

        char = in_stream.readByte() catch |err| {
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

pub fn main(args: [][]u8) anyerror!u8 {
    var opts: PrintOptions = PrintOptions.Full;
    var length: []u8 = undefined;

    var it = opt.FlagIterator(TailFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            TailFlags.Help => {
                warn("(help screen here)\n", .{});
                return 1;
            },
            TailFlags.Version => {
                warn("(version info here)\n", .{});
                return 1;
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

    if (files.items.len > 0) {
        for (files.items) |file_name| {
            const file = std.fs.cwd().openFile(file_name[0..], File.OpenFlags{ .read = true, .write = false }) catch |err| {
                try stdout.print("Error: cannot open file {}\n", .{file_name});
                return 1;
            };
            if (files.items.len >= 2) try stdout.print("==> {} <==\n", .{file_name});
            try tail(n, file, opts == PrintOptions.Bytes);
            file.close();
        }
    } else {
        const file = std.io.getStdIn();
        try alt_tail(n, file, opts == PrintOptions.Bytes);
    }
    return 0;
}
