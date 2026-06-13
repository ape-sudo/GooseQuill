const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const gq_mod = b.addModule("GooseQuill", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{
            .name = "GooseQuill",
            .module = gq_mod,
        }},
    });

    const exe = b.addExecutable(.{
        .name = "GooseQuill",
        .root_module = root_module,
    });

    b.installArtifact(exe);
}
