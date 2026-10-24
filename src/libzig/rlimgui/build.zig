const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "rlimgui";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/impl_rlimgui.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    t.addIncludePath(b.path("../../libc/rlimgui"));
    t.addIncludePath(b.path("../../libc/raylib/windows/include"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.defineCMacro("NO_FONT_AWESOME", "");

    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");

    mod.addIncludePath(b.path("../../libc/rlimgui"));
    mod.addIncludePath(b.path("../../libc/raylib/windows/include"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addCMacro("ImDrawIdx", "unsigned int"); // [[[[[[ Very important definition ]]]]]]
    mod.addCMacro("NO_FONT_AWESOME", "");
    mod.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "../../libc/rlimgui/rlImGui.cpp",
        },
        .flags = &[_][]const u8{
            "-std=c++17",
            "-fno-sanitize=undefined",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
