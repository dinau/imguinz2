const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "implot3d";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/impl_implot3d.h"),
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
    step.addIncludePath(b.path("../../libc/cimplot3d"));
    if (emscripten_sysroot) |es| {
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }

    const mod = step.addModule(mod_name);
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/cimgui"));
    mod.addIncludePath(b.path("../../libc/cimplot3d"));
    mod.addIncludePath(b.path("../../libc/cimplot3d/implot3d"));
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
            // ImPlot3d
            "../../libc/cimplot3d/implot3d/implot3d.cpp",
            "../../libc/cimplot3d/implot3d/implot3d_demo.cpp",
            "../../libc/cimplot3d/implot3d/implot3d_items.cpp",
            "../../libc/cimplot3d/implot3d/implot3d_meshes.cpp",
            // CImPlot3d
            "../../libc/cimplot3d/cimplot3d.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
