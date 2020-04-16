const std = @import("std");
const Sha1 = std.crypto.Sha1;
const opt = @import("opt.zig");
const Allocator = std.mem.Allocator;
const stdout = &std.io.getStdOut().outStream();
const warn = std.debug.warn;
const BUFSIZ = 4096;

pub fn sha1(allocator: *Allocator, file: std.fs.File) ![40]u8 {
    var h = Sha1.init();
    var hash: [20]u8 = undefined;
    var real_out: [40]u8 = undefined;

    var file_buffer = std.ArrayList(u8).init(allocator);
    defer file_buffer.deinit();

    var read_buffer: [BUFSIZ]u8 = undefined;

    var size = try file.readAll(&read_buffer);
    while (size > 0) : (size = try file.readAll(&read_buffer)) {
        try file_buffer.insertSlice(file_buffer.items.len, read_buffer[0..size]);
    }
    h.reset();
    h.update(file_buffer.items[0..]);
    h.final(hash[0..]);
    var i: u8 = 0;
    while (i < 20) : (i += 1) {
        if (hash[i] <= 15) {
            _ = try std.fmt.bufPrint(real_out[i * 2 ..], "0{x}", .{hash[i]});
        } else {
            _ = try std.fmt.bufPrint(real_out[i * 2 ..], "{x}", .{hash[i]});
        }
    }

    return real_out;
}

const Sha1Flags = enum {
    Help,
    Version,
};

var flags = [_]opt.Flag(Sha1Flags){
    .{
        .name = Sha1Flags.Help,
        .long = "help",
    },
    .{
        .name = Sha1Flags.Version,
        .long = "version",
    },
};

pub fn main(args: [][]u8) anyerror!u8 {
    var it = opt.FlagIterator(Sha1Flags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            Sha1Flags.Help => {
                warn("sha1 [FILE_NAME ..]\n", .{});
                return 1;
            },
            Sha1Flags.Version => {
                warn("(version info here)\n", .{});
                return 1;
            },
        }
    }

    var files = std.ArrayList([]u8).init(std.heap.page_allocator);
    while (it.next_arg()) |file_name| {
        try files.append(file_name);
    }

    if (files.items.len > 0) {
        for (files.items) |file_name| {
            const file = std.fs.cwd().openFile(file_name[0..], std.fs.File.OpenFlags{ .read = true, .write = false }) catch |err| {
                try stdout.print("Error: cannot open file {}\n", .{file_name});
                return 1;
            };
            // run command
            var result = sha1(std.heap.page_allocator, file) catch |err| {
                try stdout.print("Error: {}\n", .{err});
                return 1;
            };
            try stdout.print("{}\n", .{result});
            file.close();
        }
    } else {
        var result = sha1(std.heap.page_allocator, std.io.getStdIn()) catch |err| {
            try stdout.print("Error: {}\n", .{err});
            return 1;
        };
        try stdout.print("{}\n", .{result});
    }
    return 0;
}

test "hash on license" {
    var file = try std.fs.cwd().openFile("LICENSE", std.fs.File.OpenFlags{ .read = true });
    var result = try sha1(std.heap.page_allocator, file);

    std.debug.assert(std.mem.eql(u8, result[0..], "2b5c4a97ba0ed7175825ab99052952111ddcd1db"));
}
