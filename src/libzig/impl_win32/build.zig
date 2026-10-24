const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "impl_win32";

    var mod: *std.Build.Module = undefined;
    //const gen_option = b.option(bool, "gen", "Generate I/O definition file from C header") orelse false;
    const gen_option = true;

    // -------
    // module
    // -------
    if (!gen_option) {
        mod = b.addModule(mod_name, .{
            .root_source_file = b.path("src/impl_win32.zig"),
            .target = target,
            .optimize = optimize,
        });
    } else { // Generate original_temp_zig in zig-out
        const translate_c = b.dependency("translate_c", .{});
        const t: Translator = .init(translate_c, .{
            .c_source_file = b.path("src/impl_win32.h"),
            .target = target,
            .optimize = optimize,
        });
        t.defineCMacro("__INTRIN_H_", null);
        t.addIncludePath(b.path("../../libc/dcimgui"));
        t.addIncludePath(b.path("../../libc/dcimgui/backends"));
        t.addIncludePath(b.path("../../libc/imgui"));
        t.addIncludePath(b.path("../../libc/imgui/backends"));

        mod = t.mod;
        b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
    }
    mod.link_libcpp = true;
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/backends"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/imgui/backends"));
    mod.addCMacro("ImDrawIdx", "unsigned int");
    switch (target.result.os.tag) {
        .windows => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\" __declspec(dllexport)"),
        .linux => mod.addCMacro("IMGUI_IMPL_API", "extern \"C\"  "),
        else => {},
    }
    mod.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "../../libc/dcimgui/backends/dcimgui_impl_win32.cpp",
            "../../libc/imgui/backends/imgui_impl_win32.cpp",
        },
    });

    if (target.result.os.tag == .windows) {
        mod.linkSystemLibrary("d3d11", .{});
        mod.linkSystemLibrary("dxgi", .{});
        mod.linkSystemLibrary("user32", .{});
        mod.linkSystemLibrary("gdi32", .{});
        mod.linkSystemLibrary("imm32", .{});
        mod.linkSystemLibrary("dxguid", .{});
        mod.linkSystemLibrary("dwmapi", .{});
        mod.linkSystemLibrary("d3dcompiler_47", .{});
    }

    //    LIBS = -ld3d11 -ldxgi -luser32 -lgdi32 -limm32 -ldxguid -ldwmapi -ld3dcompiler_47
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
