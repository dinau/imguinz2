const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imtoggle";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/toggle.h"),
        .target = target,
        .optimize = optimize,
    });
    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/cimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/cimgui_toggle"));

    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");

    mod.addIncludePath(b.path("../../libc/dcimgui/imgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/cimgui_toggle/imgui_toggle"));
    mod.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "../../libc/cimgui_toggle/imgui_toggle/imgui_toggle.cpp",
            "../../libc/cimgui_toggle/imgui_toggle/imgui_toggle_presets.cpp",
            "../../libc/cimgui_toggle/imgui_toggle/imgui_toggle_renderer.cpp",
            "../../libc/cimgui_toggle/imgui_toggle/imgui_toggle_palette.cpp",
            // CImGui-Toggle
            "../../libc/cimgui_toggle/cimgui_toggle.cpp",
            "../../libc/cimgui_toggle/cimgui_offset_rect.cpp",
            "../../libc/cimgui_toggle/cimgui_toggle_presets.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
