const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "impl_opengl3";
    var mod: *std.Build.Module = undefined;

    //const gen_option = b.option(bool, "gen", "Generate I/O definition file from C header") orelse (target.result.os.tag == .emscripten);
    const gen_option = true;

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
        const translate_c = b.dependency("translate_c", .{});
        const t: Translator = .init(translate_c, .{
            .c_source_file = b.path("src/impl_opengl3.h"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });

        t.defineCMacro("IMGUI_DISABLE_SSE", "");

        t.addIncludePath(b.path("../../libc/imgui"));
        t.addIncludePath(b.path("../../libc/imgui/backends"));
        t.addIncludePath(b.path("../../libc/dcimgui"));
        t.addIncludePath(b.path("../../libc/dcimgui/backends"));
        if (emscripten_sysroot) |es| {
            t.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
        }

        switch (target.result.os.tag) {
            .emscripten => t.defineCMacro("IMGUI_IMPL_OPENGL_ES3", ""),
            else => {},
        }

        mod = t.mod;
        b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
    }
    switch (target.result.os.tag) {
        .windows => mod.addIncludePath(b.path("../../libc/glfw/glfw.bin.WIN64/include")),
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
        .root = b.path("."),
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
