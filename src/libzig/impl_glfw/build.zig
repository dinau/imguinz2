const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "impl_glfw";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/impl_glfw.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    step.defineCMacro("IMGUI_DISABLE_SSE","");

    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/dcimgui/backends"));
    const mod = step.addModule(mod_name);
    mod.addImport(mod_name, mod);

    switch (builtin.target.os.tag) {
        .windows => mod.addIncludePath(b.path("../../libc/glfw/glfw-3.4.bin.WIN64/include")),
        .linux => mod.addIncludePath(.{ .cwd_relative = "/usr/include" }),
        else => {},
    }

    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/imgui/backends"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/backends"));
    // macro
    mod.addCMacro("ImDrawIdx", "unsigned int");

    switch (builtin.target.os.tag) {
        .windows => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\" __declspec(dllexport)"),
        .linux => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\"  "),
        else => {},
    }
    mod.addCSourceFiles(.{
        .files = &.{
            "../../libc/dcimgui/backends/dcimgui_impl_glfw.cpp",
            "../../libc/imgui/backends/imgui_impl_glfw.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
