const std = @import("std");
const builtin = @import("builtin");
const stdout = &std.io.getStdOut().outStream().stream;

const fstaterror = std.os.FStatError;

pub fn du(paths: [][]const u8, zero: bool) !void {
    const terminator: u8 = if (zero) '\x00' else '\n';
    // loop through paths and find size
    var i: usize = 0;
    var f: std.fs.File = undefined;
    var size: u64 = 0;
    while (i < paths.len) : (i += 1) {
        f = std.fs.cwd().openFile(paths[i], .{
            .read = true,
            .write = false,
        }) catch |err| {
            try stdout.print("Error opening file: {}! {}\n", .{ paths[i], err });
            return err;
        };

        size = grab_allocated_memory(f) catch |err| {
            try stdout.print("Error statting file: {}!\n", .{paths[i]});
            return err;
        };

        // assume 512 byte blocks unless environmental variable set

        try stdout.print("{}\t{}{c}", .{ size / 512 / 8, paths[i], terminator });
    }
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

// jdaboub

pub fn main() !void {
    // out of memory panic
    const args = std.process.argsAlloc(std.heap.page_allocator) catch |err| {
        try stdout.print("Out of memory: {}\n", .{err});
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    // check len of args
    if (args.len != 2) {
        try stdout.print("usage: ./du [file]...\n", .{});
        return;
    }

    // run command
    try du(args[1..], false);
}
