const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imguizoomableimage";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/impl_imguizoomableimage.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    t.addIncludePath(b.path("../../libc/cimgui_zoomable_image"));
    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
    mod.link_libcpp = true;
    mod.addIncludePath(b.path("../../libc/cimgui_zoomable_image"));
    mod.addIncludePath(b.path("../../libc/cimgui_zoomable_image/imgui_zoomable_image"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    // Macro
    mod.addCMacro("CIMGUI_API", "extern \"C\"  ");
    mod.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "../../libc/cimgui_zoomable_image/cimgui_zoomable_image.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
