const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod_name = "impl_glfw";
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");
    const contrib_glfw3_include: ?[]const u8 = if (emscripten_sysroot) |es|
        b.pathJoin(&.{ es, "cache/ports/contrib.glfw3/external" })
    else
        null;
    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/impl_glfw.h"),
        .target = target,
        .optimize = optimize,
    });
    if (emscripten_sysroot) |es| {
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    if (contrib_glfw3_include) |cgi| {
        step.addIncludePath(.{ .cwd_relative = cgi });
    }
    step.defineCMacro("IMGUI_DISABLE_SSE", "");
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/dcimgui/backends"));

    const mod = step.addModule(mod_name);
    switch (target.result.os.tag) {
        .windows => mod.addIncludePath(b.path("../../libc/glfw/glfw-3.4.bin.WIN64/include")),
        .linux => mod.addIncludePath(.{ .cwd_relative = "/usr/include" }),
        .emscripten => {
            if (contrib_glfw3_include) |cgi| mod.addSystemIncludePath(.{ .cwd_relative = cgi });
        },
        else => {},
    }
    mod.link_libcpp = true;
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/imgui/backends"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/backends"));
    if (emscripten_sysroot) |es| {
        mod.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    // macro
    mod.addCMacro("ImDrawIdx", "unsigned int");
    switch (target.result.os.tag) {
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
