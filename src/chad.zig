const std = @import("std");
const stdout = &std.io.getStdOut().outStream().stream;

// CHAD
const frame = "CHAD";

pub fn chad_stride void {
    var frame: u8 = 0;
    //
    //while (true) : (frame += 1) {
     //    
    //}
    stdout.print("{}", .{frame});
}

pub fn main() anyerror!u8 {
    chad_stride();
    return 0;
}
