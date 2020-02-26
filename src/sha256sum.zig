const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

pub fn sha256(name: []const u8) !void {
    // encoding function
    return;
}

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    // For now, do not handle case where arguments are from stdin
    if (args.len < 2) {
        try stdout.print("sha256sum: missing operands \n", .{});
        return;
    }

    // return sha256sum of each argument given
    for (args) |arg, i| {
        if(i != 0){
            
        }
    }
    
}
