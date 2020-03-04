const std = @import("std");
const File = std.fs.file;
const stdout = &std.io.getStdOut().outStream().stream;

const BUFSIZ: u16 = 4096;

pub fn wc (path: []const u8) !void {
    // Open file for reading and put into buffered stream    
const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buffered_stream = std.io.BufferedInStream(std.fs.File.InStream.Error).init(&file.inStream().stream);

    // Init read buffer, used to store BUFSIZ input from readFull
    var buffer: [BUFSIZ]u8 = undefined;
    
    var line_count: u64 = 0;
    var character_count: u64 = 0;
    var byte_count: u8 = 0;

    var fast: u32 = 0;
    var slow: u32 = 0;

    // Read stream & loops
    var size = try buffered_stream.stream.readFull(&buffer);
    while (size > 0) : ({
        size = (try buffered_stream.stream.readFull(&buffer));
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
        try stdout.print("  {} {} {}", .{line_count, character_count, path});
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
    if (args.len < 2) {
        try stdout.print("usage: ./wc [FILE] \n", .{});
        return;
    }

    // call function
    wc(args[1]) catch |err| {
        try stdout.print("Error: {}\n", .{err});
        return;
    };
   
}
