const std = @import("std");
const File = &std.io.getStdOut().outStream().stream;
const stdout = &std.io.getStdOut().outStream().stream;

const BUFSIZ: u16 = 4096;

pub fn tail(n: u32, path: []const u8) !void {
    // check if user inputs illegal line number
    if (n <= 0) {
        try stdout.print("Error: illegal line count: {}\n", .{n});
        return;
    }

    // Open file for reading and put into buffered stream
    const file = try std.fs.File.openRead(path);
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

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    // check len of args
    if (args.len != 3) {
        try stdout.print("usage: ./head FILE n\n", .{});
        return;
    }

    // must be a number
    const n = std.fmt.parseInt(u32, args[2], 10) catch |err| {
        try stdout.print("Error: second arg must be a number!\n", .{});
        return;
    };

    // run command
    tail(n, args[1]) catch |err| {
        try stdout.print("Error: {}\n", .{err});
        return;
    };
}
