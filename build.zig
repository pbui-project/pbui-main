const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("pbui", "src/main.zig");
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Execute PBUI");

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    var shuf_tests = b.addTest("src/shuf.zig");
    shuf_tests.setBuildMode(mode);

    var basename_tests = b.addTest("src/basename.zig");
    basename_tests.setBuildMode(mode);

    var du_tests = b.addTest("src/du.zig");
    du_tests.setBuildMode(mode);

    var false_tests = b.addTest("src/false.zig");
    false_tests.setBuildMode(mode);

    var mkdir_tests = b.addTest("src/mkdir.zig");
    mkdir_tests.setBuildMode(mode);

    var rm_tests = b.addTest("src/rm.zig");
    rm_tests.setBuildMode(mode);

    var sha1_tests = b.addTest("src/sha1.zig");
    sha1_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
    test_step.dependOn(&shuf_tests.step);
    test_step.dependOn(&basename_tests.step);
    test_step.dependOn(&false_tests.step);
    test_step.dependOn(&mkdir_tests.step);
    test_step.dependOn(&rm_tests.step);
    test_step.dependOn(&sha1_tests.step);
}
