const std = @import("std");

fn show_file(path: []const u8) void {
    std.debug.warn("{}", .{path});
}

fn show_directory(path: []const u8) !void {
    var bytes: [1024]u8 = undefined;
    const allocator = &std.heap.FixedBufferAllocator.init(bytes[0..]).allocator;

    var dents = std.ArrayList([]const u8).init(allocator);
    defer dents.deinit();

    //To be used for Alpha sorting
    //var alphaDents = std.ArrayList([]const u8).init(allocator);
    //defer alphaDents.deinit();

    const dir = try std.fs.cwd().openDirList(path);
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        try dents.append(entry.name);
    }

    for (dents.toSlice()) |entry| {
        std.debug.warn("{}\n", .{entry});
    }
}

fn list_path(path: []const u8) void {
    var stat_struct: std.os.Stat = undefined;
    const stat_ptr = &stat_struct;

    const stat_string = path[0..:0];

    const statResult: usize = std.os.linux.stat(stat_string, stat_ptr);

    if (statResult < 0) {
        std.debug.warn("ls: stat system call fail", .{});
        std.process.exit(1);
    }

    if (stat_ptr.mode == 16877) { // Directory
        const nothing = show_directory(path);
    } else if (stat_ptr.mode == 33188) { // File
        show_file(path);
    }
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len > 1) {
        for (args) |arg, i| {
            if (i != 0) {
                list_path(arg);
            }
        }
    } else list_path(".");
}
