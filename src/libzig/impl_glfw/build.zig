const std = @import("std");
const Translator = @import("translate_c").Translator;

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
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/impl_glfw.h"),
        .target = target,
        .optimize = optimize,
    });
    if (emscripten_sysroot) |es| {
        t.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    if (contrib_glfw3_include) |cgi| {
        t.addIncludePath(.{ .cwd_relative = cgi });
    }
    t.defineCMacro("IMGUI_DISABLE_SSE", "");
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/dcimgui/backends"));

    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");

    switch (target.result.os.tag) {
        .windows => mod.addIncludePath(b.path("../../libc/glfw/glfw.bin.WIN64/include")),
        .linux => mod.addIncludePath(.{ .cwd_relative = "/usr/include" }),
        //.emscripten => {
        //    if (contrib_glfw3_include) |cgi| mod.addSystemIncludePath(.{ .cwd_relative = cgi });
        //},
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
        .root = b.path("."),
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
