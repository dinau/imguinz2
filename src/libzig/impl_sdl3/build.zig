const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "impl_sdl3";

    const sdl_path = "../../libc/sdl/SDL3/x86_64-w64-mingw32";
    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("../../libc/dcimgui/backends/dcimgui_impl_sdl3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/dcimgui/backends"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path(b.pathJoin(&.{ sdl_path, "include/SDL3" })));
    step.addIncludePath(b.path(b.pathJoin(&.{ sdl_path, "include" })));

    const mod = step.addModule(mod_name);
    switch (target.result.os.tag) {
        .windows => mod.addIncludePath(b.path(b.pathJoin(&.{ sdl_path, "include" }))),
        .linux => mod.addIncludePath(.{ .cwd_relative = "/usr/include" }),
        else => {},
    }
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
            "../../libc/imgui/backends/imgui_impl_sdl3.cpp",
            "../../libc/dcimgui/backends/dcimgui_impl_sdl3.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
