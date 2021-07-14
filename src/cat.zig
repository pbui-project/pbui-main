const opt = @import("opt.zig");
const warn = std.debug.warn;
const std = @import("std");
const stdout = &std.io.getStdOut().writer();

const BUFSIZ: u16 = 4096;

pub fn cat(file: std.fs.File) !void {
    // print file from start pos
    var in_stream = std.fs.File.reader(file);
    print_stream(&in_stream) catch |err| {
        try stdout.print("Error: cannot print file: {}\n", .{err});
        return;
    };
}

// TODO add this to a library (used in tail also)
// Prints stream from current pointer to end of file in BUFSIZ
// chunks.
pub fn print_stream(stream: *std.fs.File.Reader) anyerror!void {
    var buffer: [BUFSIZ]u8 = undefined;
    var size = try stream.readAll(&buffer);

    // loop until EOF hit
    while (size > 0) : (size = (try stream.readAll(&buffer))) {
        try stdout.print("{s}", .{buffer[0..size]});
    }
}

const CatFlags = enum {
    Help,
    Version,
};

var flags = [_]opt.Flag(CatFlags){
    .{
        .name = CatFlags.Help,
        .long = "help",
    },
    .{
        .name = CatFlags.Version,
        .long = "version",
    },
};

pub fn main(args: [][]u8) anyerror!u8 {
    var it = opt.FlagIterator(CatFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            CatFlags.Help => {
                warn("cat FILE_NAME ..\n", .{});
                return 1;
            },
            CatFlags.Version => {
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
                try stdout.print("Error: cannot open file {s}\n", .{file_name});
                return 1;
            };
            // run command
            cat(file) catch |err| {
                try stdout.print("Error: {}\n", .{err});
                return 1;
            };
            file.close();
        }
    } else {
        try stdout.print("cat FILE_NAME ..\n", .{});
        return 1;
    }
    return 0;
}
