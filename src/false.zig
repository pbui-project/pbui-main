const assert = @import("std").debug.assert;
// Return 1... wrapped in function in
// case other debugging stuff needed
pub fn return_false() anyerror!u8 {
    return 1;
}

pub fn main(args: [][]u8) anyerror!u8 {
    return return_false() catch |err| {
        return err;
    };
}

test "this really should work" {
    assert((try return_false()) == 1);
}
