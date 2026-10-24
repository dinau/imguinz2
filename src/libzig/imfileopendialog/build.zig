const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imfileopendialog";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/filedialog.h"),
        .target = target,
        .optimize = optimize,
    });

    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/CImGuiFileDialog/libs/ImGuiFileDialog"));

    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
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
        .root = b.path("."),
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
