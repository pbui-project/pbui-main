// Return 1... wrapped in function in
// case other debugging stuff needed
pub fn return_false() anyerror!u8 {
    return 1;
}

pub fn main() !anyerror!u8 {
    return return_false() catch |err| {
        return err;
    };
}
