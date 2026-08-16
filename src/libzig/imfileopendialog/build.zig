const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imfileopendialog";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/filedialog.h"),
        .target = target,
        .optimize = optimize,
    });

    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/CImGuiFileDialog/libs/ImGuiFileDialog"));

    const mod = step.addModule(mod_name);
    mod.addIncludePath(b.path("../../libc/imgui/imgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/CImGuiFileDialog"));
    mod.addIncludePath(b.path("../../libc/CImGuiFileDialog/libs/ImGuiFileDialog"));
    mod.addIncludePath(b.path("../../libc/fonticon"));
    // macro
    mod.addCMacro("CIMGUI_API", "extern \"C\"  ");
    // for fileopendialog
    mod.addCMacro("CUSTOM_IMGUIFILEDIALOG_CONFIG", "\"customIconFont.h\"");
    mod.link_libcpp = true;
    mod.addCSourceFiles(.{
        .files = &.{
            "../../libc/CImGuiFileDialog/libs/ImGuiFileDialog/ImGuiFileDialog.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
