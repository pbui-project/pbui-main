const std = @import("std");
const opt = @import("opt.zig");

var ALPHA : bool = false;
var RECUR : bool = false;
var ALL   : bool = false;

const lsFlags = enum {
    All,
    Alpha,
    Recursive,
    Help,
};

var flags = [_]opt.Flag(lsFlags){
    .{
        .name = lsFlags.Help,
        .long = "help",
    },
    .{
        .name = lsFlags.All,
        .short = 'a',
    },
    .{
        .name = lsFlags.Recursive,
        .short = 'r',
    },
    .{
        .name = lsFlags.Alpha,
        .short = 'A',
        .long = "Alpha",
    },
};


fn show_file(path: []const u8) void {
    std.debug.warn("{}\n", .{path});
}

fn show_directory(path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var dents = std.ArrayList(std.fs.Dir.Entry).init(allocator);
    defer dents.deinit();

    if (std.fs.cwd().openDir(path, std.fs.Dir.OpenDirOptions{ .access_sub_paths = true, .iterate = true })) |d_opened| {
        var dir = d_opened;
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            try dents.append(entry);
        }
        if(ALL == true) std.debug.warn(".\n..\n", .{});
        for (dents.items) |entry| {
            if(ALL == true or entry.name[0] != '.') {
                if(entry.kind == std.fs.Dir.Entry.Kind.Directory){ 
                    std.debug.warn("{}/\n", .{entry.name});   
                }
                else {
                    std.debug.warn("{}\n", .{entry.name});
                }
            }
        }
        std.fs.Dir.close(&dir);
    } else |err| {
        if(err == error.NotDir) show_file(path);
        return;
    }

}

pub fn main(args: [][]u8) anyerror!u8 {
    var it = opt.FlagIterator(lsFlags).init(flags[0..], args);
    while(it.next_flag() catch { return 1; }) |flag| {
        switch (flag.name){
            lsFlags.Help => {
                std.debug.warn("Usgae: ls FLAGS DIRECTORIES\n", .{});
                return 1;
            },
            lsFlags.All => {
                ALL = true;
            },
            lsFlags.Recursive => {
                RECUR = true;
            },
            lsFlags.Alpha => {
                ALPHA = true;
            },
        }
    }

    var dirs = std.ArrayList([]u8).init(std.heap.page_allocator);
    while (it.next_arg()) |direntry| {
        try dirs.append(direntry);
    }


    if (dirs.items.len > 0) {
        for (dirs.items) |arg| {
            const result = show_directory(arg);
        }
    } else const result = show_directory(".");

    return 0;

}
