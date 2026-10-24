const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");
    const mod_name = "impl_wgpu";
    var mod: *std.Build.Module = undefined;

    //const gen_option = b.option(bool, "gen", "Generate I/O definition file from C header") orelse (target.result.os.tag == .emscripten);
    const gen_option = true;

    // <sysroot>/cache/ports/emdawnwebgpu/emdawnwebgpu_pkg/webgpu/include
    const webgpu_include: ?[]const u8 = if (emscripten_sysroot) |es|
        b.pathJoin(&.{ es, "cache/ports/emdawnwebgpu/emdawnwebgpu_pkg/webgpu/include" })
    else
        null;
    const webgpu_cpp_include: ?[]const u8 = if (emscripten_sysroot) |es|
        b.pathJoin(&.{ es, "cache/ports/emdawnwebgpu/emdawnwebgpu_pkg/webgpu_cpp/include" })
    else
        null;

    if (!gen_option) {
        mod = b.addModule(mod_name, .{
            .root_source_file = b.path("src/impl_wgpu.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
    } else {
        const translate_c = b.dependency("translate_c", .{});
        const t: Translator = .init(translate_c, .{
            .c_source_file = b.path("src/impl_wgpu.h"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        t.defineCMacro("IMGUI_DISABLE_SSE", "");
        t.defineCMacro("IMGUI_IMPL_WEBGPU_BACKEND_DAWN", "");
        t.addIncludePath(b.path("../../libc/imgui"));
        t.addIncludePath(b.path("../../libc/imgui/backends"));
        t.addIncludePath(b.path("../../libc/dcimgui"));
        t.addIncludePath(b.path("../../libc/dcimgui/backends"));
        t.addIncludePath(b.path("src"));
        if (webgpu_include) |wi| t.addSystemIncludePath(.{ .cwd_relative = wi });
        if (webgpu_cpp_include) |wi| t.addIncludePath(.{ .cwd_relative = wi });
        if (emscripten_sysroot) |es| t.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });

        mod = t.mod;
        b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
    }

    mod.link_libcpp = true;
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/backends"));
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui/backends"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/imgui/backends"));
    mod.addIncludePath(b.path("src"));
    switch (target.result.os.tag) {
        .windows => mod.addIncludePath(b.path("../../libc/glfw/glfw.bin.WIN64/include")),
        .linux => mod.addIncludePath(.{ .cwd_relative = "/usr/include" }),
        else => {},
    }
    if (webgpu_include) |wi| mod.addSystemIncludePath(.{ .cwd_relative = wi });
    if (webgpu_cpp_include) |wi| mod.addIncludePath(.{ .cwd_relative = wi });
    if (emscripten_sysroot) |es| mod.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });

    mod.addCMacro("ImDrawIdx", "unsigned int");
    mod.addCMacro("IMGUI_IMPL_WEBGPU_BACKEND_DAWN", "");
    switch (target.result.os.tag) {
        .windows => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\" __declspec(dllexport)"),
        .linux => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\"  "),
        else => {},
    }

    mod.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "../../libc/dcimgui/backends/dcimgui_impl_wgpu.cpp",
            "../../libc/imgui/backends/imgui_impl_wgpu.cpp",
            "src/wgpu_init.cpp",
        },
    });

    const lib = b.addLibrary(.{ .linkage = .static, .name = mod_name, .root_module = mod });
    b.installArtifact(lib);
}
