const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imtoggle";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/toggle.h"),
        .target = target,
        .optimize = optimize,
    });
    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/cimgui_toggle"));

    const mod = step.addModule(mod_name);
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/cimgui_toggle/imgui_toggle"));
    mod.addCSourceFiles(.{
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
