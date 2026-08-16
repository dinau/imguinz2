const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "impl_opengl3";
    var mod: *std.Build.Module = undefined;

    const gen_option = b.option(bool, "gen", "Generate I/O definition file from C header") orelse (target.result.os.tag == .emscripten);

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
        if (emscripten_sysroot) |es| {
            step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
        }

        switch (target.result.os.tag) {
            .emscripten => step.defineCMacro("IMGUI_IMPL_OPENGL_ES3", ""),
            else => {},
        }

        mod = step.addModule(mod_name);
    }
    switch (target.result.os.tag) {
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
    if (emscripten_sysroot) |es| {
        mod.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    mod.addCMacro("ImDrawIdx", "unsigned int");
    switch (target.result.os.tag) {
        .windows => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\" __declspec(dllexport)"),
        .linux => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\"  "),
        .emscripten => mod.addCMacro("IMGUI_IMPL_OPENGL_ES3", ""),
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
