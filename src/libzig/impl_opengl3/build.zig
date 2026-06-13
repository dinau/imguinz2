const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "impl_opengl3";
    var mod: *std.Build.Module = undefined;

    const gen_option = b.option(bool, "gen", "Generate I/O definition file from C header") orelse false;

    // -------
    // module
    // -------
    if (!gen_option) {
        mod = b.addModule(mod_name, .{
            .root_source_file = b.path("src/impl_opengl3.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
    } else {
        const step = b.addTranslateC(.{
            .root_source_file = b.path("src/impl_opengl3.h"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });

        step.defineCMacro("IMGUI_DISABLE_SSE", "");

        step.addIncludePath(b.path("../../libc/imgui"));
        step.addIncludePath(b.path("../../libc/imgui/backends"));
        step.addIncludePath(b.path("../../libc/dcimgui"));
        step.addIncludePath(b.path("../../libc/dcimgui/backends"));

        mod = step.addModule(mod_name);
    }
    switch (builtin.target.os.tag) {
        .windows => mod.addIncludePath(b.path("../../libc/glfw/glfw-3.4.bin.WIN64/include")),
        .linux => mod.addIncludePath(.{ .cwd_relative = "/usr/include" }),
        else => {},
    }
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/backends"));
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui/backends"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/imgui/backends"));
    mod.addCMacro("ImDrawIdx", "unsigned int");
    switch (builtin.target.os.tag) {
        .windows => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\" __declspec(dllexport)"),
        .linux => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\"  "),
        else => {},
    }
    mod.addCSourceFiles(.{
        .files = &.{
            "../../libc/dcimgui/backends/dcimgui_impl_opengl3.cpp",
            "../../libc/imgui/backends/imgui_impl_opengl3.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
