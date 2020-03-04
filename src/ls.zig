const std = @import("std");

fn show_file(path: []const u8) void {
    std.debug.warn("{}\n", .{path});
}

fn show_directory(path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var dents = std.ArrayList([]const u8).init(allocator);
    defer dents.deinit();

    if (std.fs.cwd().openDirList(path)) |d_opened| {
        var dir = d_opened;
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            try dents.append(entry.name);
        }
        for (dents.toSlice()) |entry| {
            std.debug.warn("{}\n", .{entry});
        }
        std.fs.Dir.close(&dir);
    } else |err| {
        if(err == error.NotDir) show_file(path);
        return;
    }

}

pub fn main() anyerror!u8 {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len > 1) {
        for (args) |arg, i| {
            if (i != 0) {
                const result = show_directory(arg);
            }
        }
    } else const result = show_directory(".");

    return 0;

}
