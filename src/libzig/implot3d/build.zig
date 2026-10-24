const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "implot3d";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/impl_implot3d.h"),
        .target = target,
        .optimize = optimize,
    });

    t.defineCMacro("IMGUI_DISABLE_SSE", "");

    t.addIncludePath(b.path("./src"));
    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/cimgui"));
    t.addIncludePath(b.path("../../libc/cimplot"));
    t.addIncludePath(b.path("../../libc/cimplot3d"));
    if (emscripten_sysroot) |es| {
        t.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }

    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
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
        .root = b.path("."),
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
