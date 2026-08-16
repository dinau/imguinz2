const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imguizmo";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/impl_guizmo.h"),
        .target = target,
        .optimize = optimize,
    });

    step.defineCMacro("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    step.addIncludePath(b.path("src"));
    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/cimguizmo"));
    step.addIncludePath(b.path("../../libc/cimgui"));

    const mod = step.addModule(mod_name);
    // Macro
    mod.addCMacro("CIMGUI_API", "extern \"C\"  ");
    mod.addCMacro("imguizmo_NAMESPACE", "imguizmo"); // for imguizmo
    //
    mod.addIncludePath(b.path("src"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/cimgui"));
    mod.addIncludePath(b.path("../../libc/cimguizmo/imguizmo"));
    mod.addCSourceFiles(.{
        .files = &.{
            "../../libc/cimguizmo/cimguizmo.cpp",
            "../../libc/cimguizmo/ImGuizmo/src/GraphEditor.cpp",
            "../../libc/cimguizmo/ImGuizmo/src/ImCurveEdit.cpp",
            "../../libc/cimguizmo/ImGuizmo/src/ImGradient.cpp",
            "../../libc/cimguizmo/ImGuizmo/src/ImGuizmo.cpp",
            "../../libc/cimguizmo/ImGuizmo/src/ImSequencer.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
