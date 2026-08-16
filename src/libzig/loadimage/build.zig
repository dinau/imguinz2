const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "loadimage";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/loadImage.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    if (emscripten_sysroot) |es| {
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    const mod = step.addModule(mod_name);
    mod.addIncludePath(b.path("../../libc/stb"));
    if (emscripten_sysroot) |es| {
        mod.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    switch (target.result.os.tag) {
        .windows => mod.addIncludePath(b.path("../../libc/glfw/glfw-3.4.bin.WIN64/include")),
        .linux => mod.addIncludePath(.{ .cwd_relative = "/usr/include" }),
        else => {},
    }
    mod.addCSourceFiles(.{
        .files = &.{
            "src/loadImage.c",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
