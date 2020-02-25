// Return 0... wrapped in function in
// case other debugging stuff needed
pub fn return_true() anyerror!u8 {
    return 0;
}

pub fn main() anyerror!u8 {
    return return_true() catch |err| {
        return err;
    };
}
