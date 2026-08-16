const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "implot";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/impl_implot.h"),
        .target = target,
        .optimize = optimize,
    });

    step.defineCMacro("IMGUI_DISABLE_SSE", "");
    step.defineCMacro("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");

    step.addIncludePath(b.path("./src"));
    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/cimgui"));
    step.addIncludePath(b.path("../../libc/cimplot"));
    if (emscripten_sysroot) |es| {
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }

    const mod = step.addModule(mod_name);
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/cimgui"));
    mod.addIncludePath(b.path("../../libc/cimplot"));
    mod.addIncludePath(b.path("../../libc/cimplot/implot"));
    mod.addIncludePath(b.path("./src"));
    if (emscripten_sysroot) |es| {
        mod.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    // Macro
    mod.addCMacro("CIMGUI_API", "extern \"C\"  ");
    mod.addCMacro("ImDrawIdx", "unsigned int");
    //
    mod.addCSourceFiles(.{
        .files = &.{
            "../../libc/cimplot/cimplot.cpp",
            "../../libc/cimplot/implot/implot.cpp",
            "../../libc/cimplot/implot/implot_demo.cpp",
            "../../libc/cimplot/implot/implot_items.cpp",
        },
        .flags = &.{
            "-O2",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
