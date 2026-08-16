const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "imknobs";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("../../libc/cimgui-knobs/cimgui-knobs.h"),
        .target = target,
        .optimize = optimize,
    });

    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libzig/cimgui"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/cimknobs"));
    if (emscripten_sysroot) |es| {
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    const mod = step.addModule(mod_name);
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libzig/cimgui"));
    mod.addIncludePath(b.path("../../libc/cimgui-knobs"));
    mod.addIncludePath(b.path("../../libc/cimgui-knobs//libs/imgui-knobs"));
    if (emscripten_sysroot) |es| {
        mod.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    mod.addCSourceFiles(.{
        .files = &.{
            "../../libc/cimgui-knobs/cimgui-knobs.cpp",
            "../../libc/cimgui-knobs/libs/imgui-knobs/imgui-knobs.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
