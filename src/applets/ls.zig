const std = @import("std");

var FirstShown: bool = true;

pub fn alpha_compare(s1: []const u8, s2: []const u8) bool {
    var i: usize = 0;
    if (s1.len >= s2.len) {
        for (s2) |letter, letter2| {
            if (letter < s1[letter2]) {
                return false;
            } else if (letter > s1[letter2]) {
                return true;
            }
        }
    } else {
        for (s1) |letter, letter2| {
            if (letter < s2[letter2]) {
                return true;
            } else if (letter > s2[letter2]) {
                return false;
            }
        }
    }

    return false;
}

fn show_file(path: []const u8) void {
    std.debug.warn("{}", .{path});
    FirstShown = false;
}

fn show_directory(path: []const u8) !void {
    var entries: [4096][]const u8 = undefined;
    var first: bool = false;
    var entryCounter: usize = 0;
    var tempString: []const u8 = "";
    var tempString2: []const u8 = "";
    var i: usize = 0;

    const dir = try std.fs.cwd().openDirList(path);
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        tempString = entry.name;
        if (first == false) {
            entries[0] = tempString;
            first = true;
        } else {
            while (i < entryCounter) : (i += 1) {
                if (alpha_compare(tempString, entries[i])) {
                    tempString2 = tempString;
                    tempString = entries[i];
                    entries[i] = tempString2;
                }
            }
            entries[i] = tempString;
        }
        entryCounter += 1;
        i = 0;
    }
    while (i < entryCounter) : (i += 1) {
        std.debug.warn("{}\n", .{entries[i]});
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
}
