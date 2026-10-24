const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");

    const mod_name = "imknobs";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("../../libc/cimgui-knobs/cimgui-knobs.h"),
        .target = target,
        .optimize = optimize,
    });

    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libzig/cimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/cimknobs"));
    if (emscripten_sysroot) |es| {
        t.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libzig/cimgui"));
    mod.addIncludePath(b.path("../../libc/cimgui-knobs"));
    mod.addIncludePath(b.path("../../libc/cimgui-knobs//libs/imgui-knobs"));
    if (emscripten_sysroot) |es| {
        mod.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    mod.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "../../libc/cimgui-knobs/cimgui-knobs.cpp",
            "../../libc/cimgui-knobs/libs/imgui-knobs/imgui-knobs.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
