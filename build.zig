const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("test-sometoml", "source/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    exe.addPackagePath("toml", "sometoml/toml.zig");

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    var argv = std.ArrayList([]const u8).init(b.allocator);
    try argv.append("toml-test.exe");
    try argv.append("zig-out/bin/test-sometoml.exe");
    if (b.args) |args| try argv.appendSlice(args);
    const toml_test = b.addSystemCommand(argv.items);
    toml_test.step.dependOn(b.getInstallStep());

    b.step("run", "Run the app").dependOn(&run_cmd.step);
    b.step("test", "Test using BurntSushi/toml-test").dependOn(&toml_test.step);
}
