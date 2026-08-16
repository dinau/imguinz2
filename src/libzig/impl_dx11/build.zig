const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "impl_dx11";

    var mod: *std.Build.Module = undefined;
    const gen_option = b.option(bool, "gen", "Generate I/O definition file from C header") orelse false;

    // -------
    // module
    // -------
    if (!gen_option) {
        mod = b.addModule(mod_name, .{
            .root_source_file = b.path("src/impl_dx11.zig"),
            .target = target,
            .optimize = optimize,
        });
    } else { // Generate original_temp_zig in zig-out
        const step = b.addTranslateC(.{
            .root_source_file = b.path("src/impl_dx11.h"),
            .target = target,
            .optimize = optimize,
        });
        step.defineCMacro("__INTRIN_H_", null);
        step.addIncludePath(b.path("../../libc/dcimgui"));
        step.addIncludePath(b.path("../../libc/dcimgui/backends"));
        step.addIncludePath(b.path("../../libc/imgui"));
        step.addIncludePath(b.path("../../libc/imgui/backends"));

        mod = step.addModule(mod_name);
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
        .files = &.{
            "../../libc/dcimgui/backends/dcimgui_impl_dx11.cpp",
            "../../libc/imgui/backends/imgui_impl_dx11.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
