const std = @import("std");
const File = std.fs.File;
const stdout = &std.io.getStdOut().writer();
const opt = @import("opt.zig");
const warn = std.debug.warn;

const BUFSIZ: u16 = 4096;

// Reads first n lines of file and
// prints to stdout
pub fn head(n: u32, file: std.fs.File, is_stdin: bool, is_bytes: bool) !void {
    // Check if user inputs illegal line number
    if (n <= 0) {
        try stdout.print("Error: illegal line count: {}\n", .{n});
        return;
    }

    // Init read buffer, used to store BUFSIZ input from readFull
    var buffer: [BUFSIZ]u8 = undefined;

    // Init linecount
    var line_count: u8 = 0;
    var fast: u32 = 0;
    var slow: u32 = 0;
    var bytes_read: usize = 0;

    // Read first chunk of stream & loop
    var size = try file.readAll(&buffer);
    while (size > 0) : ({
        size = (try file.readAll(&buffer));
        fast = 0;
        slow = 0;
    }) {
        // if is_bytes check size
        if (is_bytes) {
            if (size + bytes_read > n) {
                var left = n - bytes_read;
                try stdout.print("{s}", .{buffer[0..left]});
                bytes_read += size;
            } else {
                bytes_read += size;
                try stdout.print("{s}", .{buffer[0..size]});
            }
            continue;
        }
        // search for \n over characters and dump lines when found
        while (fast < size) : (fast += 1) {
            if (buffer[fast] == '\n') {
                try stdout.print("{s}\n", .{buffer[slow..fast]});
                slow = fast + 1;
                line_count += 1;
                if (line_count >= n) return;
            }
        }
        // print leftover
        try stdout.print("{s}", .{buffer[slow..fast]});
    }
}

const HeadFlags = enum {
    Lines,
    Bytes,
    Help,
    Version,
};

var flags = [_]opt.Flag(HeadFlags){
    .{
        .name = HeadFlags.Help,
        .long = "help",
    },
    .{
        .name = HeadFlags.Version,
        .long = "version",
    },
    .{
        .name = HeadFlags.Bytes,
        .short = 'c',
        .kind = opt.ArgTypeTag.String,
        .mandatory = true,
    },
    .{
        .name = HeadFlags.Lines,
        .short = 'n',
        .kind = opt.ArgTypeTag.String,
        .mandatory = true,
    },
};

const PrintOptions = enum {
    Full,
    Lines,
    Bytes,
};

// Testing...  For now here is usage
// ./head FILE n
pub fn main(args: [][]u8) anyerror!u8 {
    const r: u8 = 1;

    var opts: PrintOptions = PrintOptions.Full;
    var length: []u8 = undefined;

    var it = opt.FlagIterator(HeadFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            HeadFlags.Help => {
                warn("(help screen here)\n", .{});
                return 1;
            },
            HeadFlags.Version => {
                warn("(version info here)\n", .{});
                return 1;
            },
            HeadFlags.Bytes => {
                opts = PrintOptions.Bytes;
                length = flag.value.String.?;
            },
            HeadFlags.Lines => {
                opts = PrintOptions.Lines;
                length = flag.value.String.?;
            },
        }
    }

    var n: u32 = 10;
    if (opts != PrintOptions.Full)
        n = std.fmt.parseInt(u32, length[0..], 10) catch |err| {
            try stdout.print("Error: second arg must be a number!\n", .{});
            return r;
        };

    var files = std.ArrayList([]u8).init(std.heap.page_allocator);
    while (it.next_arg()) |file_name| {
        try files.append(file_name);
    }

    if (files.items.len > 0) {
        for (files.items) |file_name| {
            const file = std.fs.cwd().openFile(file_name[0..], File.OpenFlags{
                .read = true,
                .write = false,
            }) catch |err| {
                try stdout.print("Error: cannot open file {s}\n", .{file_name});
                return 1;
            };
            if (files.items.len >= 2) try stdout.print("==> {s} <==\n", .{file_name});
            // run command
            head(n, file, false, opts == PrintOptions.Bytes) catch |err| {
                try stdout.print("Error: {}\n", .{err});
                return 1;
            };
            file.close();
        }
    } else {
        head(n, std.io.getStdIn(), true, opts == PrintOptions.Bytes) catch |err| {
            try stdout.print("Error: {}\n", .{err});
            return 1;
        };
    }

    return 0;
}
