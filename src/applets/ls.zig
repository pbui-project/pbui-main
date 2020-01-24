const std = @import("std");

var FirstShown: bool = true;

pub fn alpha_compare(s1: []const u8, s2: []const u8) bool {}

fn show_file(path: []const u8) void {
    std.debug.warn("{}", .{path});
    FirstShown = false;
}

fn show_directory(path: []const u8) !void {
    var entries: [*][]const u8 = undefined;
    var first: bool = false;
    var entryCounter = 0;
    var tempString: []const u8 = undefined;

    std.debug.warn("{}\n", .{entries[0]});

    const dir = try std.fs.cwd().openDirList(path);
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        tempString = entry;
        if (first == false) {
            entries[0] = tempString;
            first = true;
        } else {
            entries[entryCounter] = entry.name;
        }
        entryCounter += 1;
    }
}

fn list_path(path: []const u8) void {
    var stat_struct: std.os.Stat = undefined;
    var stat_ptr = &stat_struct;

    const stat_string = path[0..:0];

    var temp: usize = std.os.linux.stat(stat_string, stat_ptr);

    if (stat_ptr.mode == 16877) { // Directory
        var nothing = show_directory(path);
    } else if (stat_ptr.mode == 33188) { // File
        show_file(path);
    }
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len > 1) {
        for (args) |arg, i| {
            if (i != 0) list_path(arg);
        }
    } else list_path(".");

    std.debug.warn("\n", .{});
}
