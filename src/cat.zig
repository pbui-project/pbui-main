const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

const BUFSIZ: u16 = 4096;

pub fn cat(path: []const u8) !void {
    // Open file for reading and put into buffered stream
    const file = try std.fs.File.openRead(path);
    defer file.close();

    // print file from start pos
    var in_stream = std.fs.File.inStream(file);
    print_stream(&in_stream.stream) catch |err| {
        try stdout.print("Error: cannot print file: {}\n", .{err});
        return;
    };
}

// TODO add this to a library (used in tail also)
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

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    // check len of args
    if (args.len != 2) {
        try stdout.print("usage: {} FILE\n", .{args[0]});
        return;
    }

    // run command
    cat(args[1]) catch |err| {
        try stdout.print("Error: {}\n", .{err});
        return;
    };
}
