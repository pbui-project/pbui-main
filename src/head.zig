const std  = @import("std");
const File = std.fs.File;


const BUFSIZ: u16 = 256;

// Reads first n lines of file and
// prints to stdout
pub fn head(n: u32, path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const stream = &file.inStream().stream;

    var buffer: [BUFSIZ]u8 = undefined;
    var i: u8 = 0;

    while (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        std.debug.warn("{}\n", .{line});
        i += 1;
        if (i >= n) break;
    }


}

// Testing...  For now here is usage
// ./head FILE n
pub fn main() anyerror!void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    const n = try std.fmt.parseInt(u32, args[2], 10);

    try head(n, args[1]);

}