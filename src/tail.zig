const std = @import("std");
const opt = @import("opt.zig");
const File = &std.io.getStdOut().outStream().stream;
const stdout = &std.io.getStdOut().outStream().stream;
const warn = std.debug.warn;
const BUFSIZ: u16 = 4096;

pub fn tail(n: u32, path: []const u8) !void {
    // check if user inputs illegal line number
    if (n <= 0) {
        try stdout.print("Error: illegal line count: {}\n", .{n});
        return;
    }

    // Open file for reading and put into buffered stream
    const file = std.fs.File.openRead(path) catch |err| {
        try stdout.print("Error: cannot open file {}\n", .{path});
        return;
    };
    defer file.close();

    // get the right start position
    var printPos = find_adjusted_start(n, file) catch |err| {
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

pub fn find_adjusted_start(n: u32, file: std.fs.File) anyerror!u64 {
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
    var new_lines: u32 = 0;
    var char: u8 = undefined;
    while (new_lines < (n + 1) and offset < endPos) {
        offset += 1;
        seekable.stream.seekTo(endPos - offset) catch |err| {
            try stdout.print("Error: cannot seek: {}\n", .{err});
            return err;
        };

        char = in_stream.stream.readByte() catch |err| {
            try stdout.print("Error: cannot read byte: {}\n", .{err});
            return err;
        };
        if (char == '\n') new_lines += 1;
    }

    // adjust offset if consumed \n
    if (offset < endPos) offset -= 1;

    return endPos - offset;
}

pub fn str_to_n(str: ?[]u8) anyerror!u32 {
    return 10;
    //   return std.mem.readInt()
}

const TailFlags = enum {
    Lines,
    Bytes,
    Forever,
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
        .name = TailFlags.Forever,
        .short = 'f',
    },
    .{
        .name = TailFlags.Bytes,
        .short = 'c',
        .kind = opt.ArgTypeTag.String,
    },
    .{
        .name = TailFlags.Lines,
        .short = 'n',
    },
};

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    var forever: bool = false;
    var bytes: bool = false;
    var length: ?[]u8 = null;

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
            TailFlags.Forever => {
                forever = true;
            },
            TailFlags.Bytes => {
                bytes = true;
                length = flag.value.String.?;
            },
            TailFlags.Lines => {
                length = flag.value.String.?;
            },
        }
    }

    var n = try str_to_n(length);

    // TODO Go in stdin read mode try stdout.print("{}", .{it.argv.len});
    while (true) {
        // has to be a const i guess so can't have a nice loop.
        const file_name = it.next_arg() orelse break;
        const f_name: []const u8 = file_name;
        try tail(n, f_name);
    }

    // run command
    //tail(n, args[1]) catch |err| {
    //   try stdout.print("Error: {}\n", .{err});
    //   return;
    //};
}
