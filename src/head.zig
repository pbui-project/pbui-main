const std = @import("std");
const File = std.fs.File;
const stdout = &std.io.getStdOut().outStream().stream;

const BUFSIZ: u16 = 4096;

// Reads first n lines of file and
// prints to stdout
pub fn head(n: u32, path: []const u8) !void {
    // Check if user inputs illegal line number
    if (n <= 0) {
        try stdout.print("Error: illegal line count: {}\n", .{n});
        return;
    }

    // Open file for reading and put into buffered stream
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buffered_stream = std.io.BufferedInStream(std.fs.File.InStream.Error).init(&file.inStream().stream);

    // Init read buffer, used to store BUFSIZ input from readFull
    var buffer: [BUFSIZ]u8 = undefined;

    // Init linecount
    var line_count: u8 = 0;
    var fast: u32 = 0;
    var slow: u32 = 0;

    // Read first chunk of stream & loop
    var size = try buffered_stream.stream.readFull(&buffer);
    while (size > 0) : ({
        size = (try buffered_stream.stream.readFull(&buffer));
        fast = 0;
        slow = 0;
    }) {
        // search for \n over characters and dump lines when found
        while (fast < size) : (fast += 1) {
            if (buffer[fast] == '\n') {
                try stdout.print("{}\n", .{buffer[slow..fast]});
                slow = fast + 1;
                line_count += 1;
                if (line_count >= n) return;
            }
        }
        // print leftover
        try stdout.print("{}", .{buffer[slow..fast]});
    }
}

// Testing...  For now here is usage
// ./head FILE n
pub fn main(args: [][]u8) anyerror!u8 {
    const r: u8 = 1;

    // check len of args
    if (args.len != 3) {
        try stdout.print("usage: FILE n\n", .{});
        return r;
    }

    // must be a number
    const n = std.fmt.parseInt(u32, args[2], 10) catch |err| {
        try stdout.print("Error: second arg must be a number!\n", .{});
        return r;
    };

    // run command
    head(n, args[1]) catch |err| {
        try stdout.print("Error: {}\n", .{err});
        return r;
    };

    return 0;
}
