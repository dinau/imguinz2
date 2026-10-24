const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imnodes";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/impl_imnodes.h"),
        .target = target,
        .optimize = optimize,
    });
    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/cimgui"));
    t.addIncludePath(b.path("../../libc/cimnodes"));
    t.addIncludePath(b.path("../../libc/cimnodes/imnodes"));
    t.addIncludePath(b.path("src"));

    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
    // Macro
    mod.addCMacro("CIMGUI_API", "extern \"C\"  ");
    mod.addCMacro("IMNODES_NAMESPACE", "imnodes"); // for imnodes
    //
    mod.addIncludePath(b.path("src"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/cimgui"));
    mod.addIncludePath(b.path("../../libc/cimnodes/cimnodes"));
    mod.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "../../libc/cimnodes/cimnodes.cpp",
            "../../libc/cimnodes/imnodes/imnodes.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
