const std = @import("std");
const File = std.fs.file;
const stdout = &std.io.getStdOut().outStream();

const BUFSIZ: u16 = 4096;

pub fn wc(path: []const u8) !void {
    // Open file for reading and put into buffered stream
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // Init read buffer, used to store BUFSIZ input from readFull
    var buffer: [BUFSIZ]u8 = undefined;

    var line_count: u64 = 0;
    var character_count: u64 = 0;
    var byte_count: u8 = 0;

    var fast: u32 = 0;
    var slow: u32 = 0;

    // Read stream & loops
    var size = try file.readAll(&buffer);
    while (size > 0) : ({
        size = (try file.readAll(&buffer));
        fast = 0;
        slow = 0;
    }) {
        // search for \n
        while (fast < size) : (fast += 1) {
            // increments line count
            if (buffer[fast] == '\n') {
                slow = fast + 1;
                line_count += 1;
            }

            // increments characters
            character_count += 1;
        }
        try stdout.print("  {} {} {}", .{ line_count, character_count, path });
    }
}

pub fn main(args: [][]u8) anyerror!u8 {
    // check len of args
    if (args.len < 2) {
        try stdout.print("usage: ./wc [FILE] \n", .{});
        return 1;
    }

    // call function
    wc(args[1]) catch |err| {
        try stdout.print("Error: {}\n", .{err});
        return 1;
    };

    return 0;
}
