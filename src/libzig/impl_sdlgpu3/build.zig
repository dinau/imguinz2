const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "impl_sdlgpu3";

    const sdl_path = "../../libc/sdl/SDL3/x86_64-w64-mingw32";

    // -------
    // module
    // -------
        const translate_c = b.dependency("translate_c", .{});
        const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/impl_sdlgpu3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/imgui/backends"));

    switch (target.result.os.tag) {
        .windows => {
            t.addIncludePath(b.path(b.pathJoin(&.{ sdl_path, "include/SDL3" })));
            t.addIncludePath(b.path(b.pathJoin(&.{ sdl_path, "include" })));
        },
        .linux => t.addIncludePath(.{ .cwd_relative = "/usr/include/SDL3" }),
        else => {},
    }

    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
    switch (target.result.os.tag) {
        .windows => {
            mod.addIncludePath(b.path(b.pathJoin(&.{ sdl_path, "include/SDL3" })));
            mod.addIncludePath(b.path(b.pathJoin(&.{ sdl_path, "include" })));
        },
        .linux => mod.addIncludePath(.{ .cwd_relative = "/usr/include/SDL3" }),
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
        .root = b.path("."),
        .files = &.{
            "../../libc/dcimgui/backends/dcimgui_impl_sdlgpu3.cpp",
            "../../libc/imgui/backends/imgui_impl_sdlgpu3.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
