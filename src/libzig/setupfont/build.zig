const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "setupfont";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/impl_setupfonts.h"),
        .target = target,
        .optimize = optimize,
    });

    const emscripten_sysroot = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");
    if (emscripten_sysroot) |es| {
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }

    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/fonticon"));

    const mod = step.addModule(mod_name);
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/fonticon"));
    if (emscripten_sysroot) |es| {
        mod.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ es, "cache/sysroot/include" }) });
    }
    mod.addCSourceFiles(.{
        .files = &.{
            "src/setupFonts.cpp",
        },
    });

    //const mod = b.addModule(mod_name, .{
    //    .root_source_file = b.path("src/setupFonts.zig"),
    //    .target = target,
    //    .optimize = optimize,
    //});

    // import modules
    //const modules = [_][]const u8{
    //    "dcimgui",
    //    "fonticon",
    //};
    //for (modules) |module| {
    //    if (mod.import_table.get(module) == null) {
    //        const mod_dep = b.dependency(module, .{});
    //        mod.addImport(module, mod_dep.module(module));
    //    }
    //}

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
