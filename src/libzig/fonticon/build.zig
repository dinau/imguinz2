const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    _ = b.option([]const u8, "emscripten_sysroot", "Path to <emsdk>/upstream/emscripten");
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "fonticon";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("../../libc/fonticon/IconsFontAwesome6.h"),
        .target = target,
        .optimize = optimize,
    });
    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
