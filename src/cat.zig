const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

const BUFSIZ: u16 = 4096;

pub fn cat(file: std.fs.File) !void {
    // print file from start pos
    var in_stream = std.fs.File.inStream(file);
    print_stream(&in_stream.stream) catch |err| {
        try stdout.print("Error: cannot print file: {}\n", .{err});
        return;
    };
}

// TODO add this to a library (used in tail also)
// Prints stream from current pointer to end of file in BUFSIZ
// chunks.
pub fn print_stream(stream: *std.fs.File.InStream.Stream) anyerror!void {
    var buffer: [BUFSIZ]u8 = undefined;
    var size = try stream.readFull(&buffer);

    // loop until EOF hit
    while (size > 0) : (size = (try stream.readFull(&buffer))) {
        try stdout.print("{}", .{buffer[0..size]});
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
                warn("(help screen here)\n", .{});
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

    if (files.len > 0) {
        for (files.toSliceConst()) |file_name| {
            const file = std.fs.File.openRead(file_name[0..]) catch |err| {
                try stdout.print("Error: cannot open file {}\n", .{file_name});
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
        cat(std.io.getStdIn()) catch |err| {
            try stdout.print("Error: {}\n", .{err});
            return 1;
        };
    }

    return 0;
}
