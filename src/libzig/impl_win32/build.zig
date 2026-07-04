const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "impl_win32";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/impl_win32.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    step.defineCMacro("__INTRIN_H_",null);
    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/dcimgui/backends"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/imgui/backends"));

    const mod = step.addModule(mod_name);
    mod.addImport(mod_name, mod);

    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui/backends"));
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
            "../../libc/dcimgui/backends/dcimgui_impl_win32.cpp",
            "../../libc/imgui/backends/imgui_impl_win32.cpp",
        },
    });

    mod.linkSystemLibrary("d3d11", .{});
    mod.linkSystemLibrary("dxgi", .{});
    mod.linkSystemLibrary("user32", .{});
    mod.linkSystemLibrary("gdi32", .{});
    mod.linkSystemLibrary("imm32", .{});
    mod.linkSystemLibrary("dxguid", .{});
    mod.linkSystemLibrary("dwmapi", .{});
    mod.linkSystemLibrary("d3dcompiler_47", .{});
//    LIBS = -ld3d11 -ldxgi -luser32 -lgdi32 -limm32 -ldxguid -ldwmapi -ld3dcompiler_47
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
