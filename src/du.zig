const std = @import("std");
const builtin = @import("builtin");
const opt = @import("opt.zig");
const warn = std.debug.warn;
const stdout = &std.io.getStdOut().outStream().stream;
const Allocator = std.mem.Allocator;

const fstaterror = std.os.FStatError;

pub fn du(paths: std.ArrayList([]const u8), depth: u8, sz: SizeOptions) anyerror!u64 {
    const terminator = '\n';
    const divisor: u32 = switch (sz) {
        .Bytes => 512,
        .Kilo => 1024,
        .Mega => 1048576,
        .Giga => 1073741824,
    };
    // loop through paths and find size
    var i: usize = 0;
    var f: std.fs.File = undefined;
    var size: u64 = 0;
    var total_size: u64 = 0;
    if (paths.len > 0) {
        for (paths.toSliceConst()) |file_name| {
            if (std.fs.cwd().openDirList(file_name)) |dir| {
                var iter = dir.iterate();

                var files = std.ArrayList([]const u8).init(std.heap.page_allocator);
                while (try iter.next()) |item| {
                    var new_name = try concat_files(std.heap.page_allocator, file_name, item.name);
                    try files.append(new_name);
                }
                //try stdout.print("calling du\n", .{});
                size = try du(files, depth + 1, sz);
                try stdout.print("{}\t{}{c}", .{ size / divisor / 8, file_name, terminator });
                total_size += size;
                var opened = dir;
                std.fs.Dir.close(&opened);
            } else |erro| {
                //try stdout.print("not folder: {}\n", .{file_name});
                f = std.fs.cwd().openFile(file_name, .{
                    .read = true,
                    .write = false,
                }) catch |err| {
                    try stdout.print("Error opening file: {}! {}\n", .{ file_name, err });
                    return err;
                };
                size = grab_allocated_memory(f) catch |err| {
                    try stdout.print("Error statting file: {}!\n", .{file_name});
                    return err;
                };
                f.close();
                // assume 512 byte blocks unless environmental variable set
                if (depth == 0) try stdout.print("{}\t{}{c}", .{ size / divisor / 8, file_name, terminator });
                total_size += size;
            }
        }
    }
    return total_size;
}

fn concat_files(allocator: *Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len + 1);
    std.mem.copy(u8, result, a);
    std.mem.copy(u8, result[a.len..], "/");
    std.mem.copy(u8, result[a.len + 1 ..], b);
    return result;
}

pub fn grab_allocated_memory(file: std.fs.File) !u64 {
    if (builtin.os == .windows) {
        var io_status_block: windows.IO_STATUS_BLOCK = undefined;
        var info: windows.FILE_ALL_INFORMATION = undefined;
        const rc = windows.ntdll.NtQueryInformationFile(file.handle, &io_status_block, &info, @sizeOf(windows.FILE_ALL_INFORMATION), .FileAllInformation);
        switch (rc) {
            .SUCCESS => {},
            .BUFFER_OVERFLOW => {},
            .INVALID_PARAMETER => unreachable,
            .ACCESS_DENIED => return error.AccessDenied,
            else => return windows.unexpectedStatus(rc),
        }
        return @bitCast(u64, info.StandardInformation.AllocationSize);
    }

    const st = try std.os.fstat(file.handle);
    return @bitCast(u64, st.blocks * st.blksize);
}

const DuFlags = enum {
    Help,
    Version,
    Kilobyte,
    Megabyte,
    Gigabyte,
};

var flags = [_]opt.Flag(DuFlags){
    .{
        .name = DuFlags.Help,
        .long = "help",
    },
    .{
        .name = DuFlags.Version,
        .long = "version",
    },
    .{
        .name = DuFlags.Kilobyte,
        .short = 'k',
    },
    .{
        .name = DuFlags.Megabyte,
        .short = 'm',
    },
    .{
        .name = DuFlags.Gigabyte,
        .short = 'g',
    },
};

const SizeOptions = enum {
    Bytes,
    Kilo,
    Mega,
    Giga,
};

pub fn main(args: [][]u8) anyerror!u8 {
    var user_size: SizeOptions = SizeOptions.Bytes;
    var human_readable: bool = false;

    var it = opt.FlagIterator(DuFlags).init(flags[0..], args);
    while (it.next_flag() catch {
        return 1;
    }) |flag| {
        switch (flag.name) {
            DuFlags.Help => {
                warn("(help screen here)\n", .{});
                return 1;
            },
            DuFlags.Version => {
                warn("(version info here)\n", .{});
                return 1;
            },
            DuFlags.Kilobyte => {
                user_size = SizeOptions.Kilo;
            },
            DuFlags.Megabyte => {
                user_size = SizeOptions.Mega;
            },
            DuFlags.Gigabyte => {
                user_size = SizeOptions.Giga;
            },
        }
    }

    var files = std.ArrayList([]const u8).init(std.heap.page_allocator);
    while (it.next_arg()) |file_name| {
        try files.append(file_name[0..]);
    }

    // run command
    var total = try du(files, 0, user_size);
    return 0;
}
