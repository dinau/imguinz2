const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imguizmo";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/impl_guizmo.h"),
        .target = target,
        .optimize = optimize,
    });

    t.addIncludePath(b.path("src"));
    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/cimguizmo"));
    t.addIncludePath(b.path("../../libc/cimgui"));

    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
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
        .root = b.path("."),
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
