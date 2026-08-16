const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "dcimgui";
    var mod: *std.Build.Module = undefined;

    const gen_option = b.option(bool, "gen", "Generate I/O definition file from C header") orelse false;

    // -------
    // module
    // -------
    if (!gen_option) {
        mod = b.addModule(mod_name, .{
            .root_source_file = b.path("src/impl_dcimgui.zig"),
            .target = target,
            .optimize = optimize,
        });
    } else {
        const step = b.addTranslateC(.{
            .root_source_file = b.path("src/impl_dcimgui.h"),
            .target = target,
            .optimize = optimize,
        });
        step.addIncludePath(b.path("../../libc/imgui"));
        step.addIncludePath(b.path("../../libc/dcimgui/imgui/backends"));
        step.addIncludePath(b.path("../../libc/dcimgui"));
        mod = step.addModule(mod_name);
    }
    mod.link_libcpp = true;
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui/backends"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("src"));
    if (emscripten_sysroot) |es| {
        mod.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    // macro
    mod.addCMacro("ImDrawIdx", "unsigned int");
    mod.addCMacro("IMGUI_ENABLE_WIN32_DEFAULT_IME_FUNCTIONS", "");
    switch (target.result.os.tag) {
        .windows => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\" __declspec(dllexport)"),
        .linux => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\"  "),
        else => {},
    }
    mod.addCMacro("CIMGUI_API", "extern \"C\"  ");
    mod.addCSourceFiles(.{
        .files = &.{
            // dcimgui
            "../../libc/dcimgui/dcimgui.cpp",
            "../../libc/dcimgui/dcimgui_internal.cpp",
            // ImGui
            "../../libc/imgui/imgui.cpp",
            "../../libc/imgui/imgui_demo.cpp",
            "../../libc/imgui/imgui_draw.cpp",
            "../../libc/imgui/imgui_tables.cpp",
            "../../libc/imgui/imgui_widgets.cpp",
        },
        .flags = &.{
            "-O2", // small binary
            // "-Os", // very small binary
        },
    });
    //---------
    // Linking
    //---------
    if (target.result.os.tag == .windows) {
        mod.linkSystemLibrary("gdi32", .{});
        mod.linkSystemLibrary("imm32", .{});
        mod.linkSystemLibrary("opengl32", .{});
        mod.linkSystemLibrary("user32", .{});
        mod.linkSystemLibrary("shell32", .{});
        mod.linkSystemLibrary("ws2_32", .{});
    } else if (target.result.os.tag == .linux) {
        mod.linkSystemLibrary("glfw3", .{});
        mod.linkSystemLibrary("GL", .{});
        mod.linkSystemLibrary("X11", .{});
    } else if (target.result.os.tag == .emscripten) {}

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
