const std = @import("std");
const opt = @import("opt.zig");

var ALPHA: bool = false;
var RECUR: bool = false;
var ALL: bool = false;
var TABS: usize = 0;

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

fn printTabs(tabn: usize) void {
    var n: usize = tabn;
    while (n > 0) {
        std.debug.warn("  ", .{});
        n = n - 1;
    }
}

pub fn compare_words(word1: []const u8, word2: []const u8) bool {
    var maxlen: usize = 0;
    var w: bool = false;
    var index: usize = 0;
    if (word1.len > word2.len) {
        maxlen = word2.len;
    } else {
        maxlen = word1.len;
        w = true;
    }

    while (maxlen > 0) {
        var val1: usize = word1[index];
        var val2: usize = word2[index];

        if (val1 > 96 and val1 < 123) {
            val1 = val1 - 32;
        }
        if (val2 > 96 and val2 < 123) {
            val2 = val2 - 32;
        }

        if (val1 < val2) {
            return true;
        }
        if (val1 > val2) {
            return false;
        }

        index = index + 1;
        maxlen = maxlen - 1;
    }

    return w;
}

pub fn alpha_ArrayList(oldList_: std.ArrayList(std.fs.Dir.Entry)) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var newList = std.ArrayList(std.fs.Dir.Entry).init(allocator);
    var oldList = oldList_;
    defer newList.deinit();

    var nextpos: usize = 0;
    var nextword: []const u8 = "";

    while (oldList.items.len > 0) {
        nextword = oldList.items[0].name;
        var word: usize = oldList.items.len - 1;

        while (word > 0) {
            if (compare_words(nextword, oldList.items[word].name) == false) {
                nextword = oldList.items[word].name;
                nextpos = word;
            }
            word = word - 1;
        }
        const ret = newList.append(oldList.swapRemove(nextpos));
        nextpos = 0;
    }

    for (newList.items) |entry| {
        if (ALL == true or entry.name[0] != '.') {
            if (entry.kind == std.fs.Dir.Entry.Kind.Directory) {
                printTabs(TABS);
                std.debug.warn("{}/\n", .{entry.name});
                if (RECUR) {
                    TABS = TABS + 1;
                    const ret = show_directory(entry.name);
                    TABS = TABS - 1;
                }
            } else {
                printTabs(TABS);
                std.debug.warn("{}\n", .{entry.name});
            }
        }
    }

    return;
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

        if (ALL == true) std.debug.warn(".\n..\n", .{});
        if (ALPHA == true) {
            const ret = alpha_ArrayList(dents);
        } else {
            for (dents.items) |entry| {
                if (ALL == true or entry.name[0] != '.') {
                    if (entry.kind == std.fs.Dir.Entry.Kind.Directory) {
                        printTabs(TABS);
                        std.debug.warn("{}/\n", .{entry.name});
                        if (RECUR) {
                            TABS = TABS + 1;
                            const ret = show_directory(entry.name);
                            TABS = TABS - 1;
                        }
                    } else {
                        printTabs(TABS);
                        std.debug.warn("{}\n", .{entry.name});
                    }
                }
            }
        }
        std.fs.Dir.close(&dir);
    } else |err| {
        if (err == error.NotDir) show_file(path);
        return;
    }
}

pub fn main(args: [][]u8) anyerror!u8 {
    var it = opt.FlagIterator(lsFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
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
    } else {
        const result = show_directory(".");
    }

    return 0;
}
