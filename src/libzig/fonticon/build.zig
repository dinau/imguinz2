const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    _ = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "fonticon";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("../../libc/fonticon/IconsFontAwesome6.h"),
        .target = target,
        .optimize = optimize,
    });
    const mod = step.addModule(mod_name);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
