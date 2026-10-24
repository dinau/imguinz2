const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imcolortextedit";

    // -------
    // module
    // -------
    const translate_c = b.dependency("translate_c", .{});
    const t: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/impl_imcte.h"),
        .target = target,
        .optimize = optimize,
    });

    t.addIncludePath(b.path("./src"));
    t.addIncludePath(b.path("../../libc/dcimgui"));
    t.addIncludePath(b.path("../../libc/imgui"));
    t.addIncludePath(b.path("../../libc/cimCTE"));
    t.addIncludePath(b.path("../../libc/cimgui"));
    //
    const mod = t.mod;
    b.modules.put(b.allocator, b.dupe(mod_name), mod) catch @panic("OOM");
    mod.addIncludePath(b.path("../../libc/dcimgui/imgui"));
    mod.addIncludePath(b.path("../../libc/dcimgui"));
    mod.addIncludePath(b.path("../../libc/imgui"));
    mod.addIncludePath(b.path("../../libc/cimgui"));
    // Macro
    mod.addCMacro("CIMGUI_API", "extern \"C\"  ");
    //
    mod.addIncludePath(b.path("../../libc/cimCTE"));
    mod.addIncludePath(b.path("../../libc/cimCTE/ImGuiColorTextEdit"));
    mod.addIncludePath(b.path("../../libc/cimCTE/ImGuiColorTextEdit/example"));
    mod.addIncludePath(b.path("../../libc/cimCTE/ImGuiColorTextEdit/extras"));
    mod.addIncludePath(b.path("../../libc/cimCTE/ImGuiColorTextEdit/vendor/regex/include"));
    mod.addIncludePath(b.path("./src"));
    mod.addCSourceFiles(.{
        .root = b.path("."),
        .files = &.{
            "../../libc/cimCTE/cimCTE.cpp",
            //  "../../libc/cimCTE/ImGuiColorTextEdit/ImGuiDebugPanel.cpp",
            //  "../../libc/cimCTE/ImGuiColorTextEdit/LanguageDefinitions.cpp",
            "../../libc/cimCTE/ImGuiColorTextEdit/TextEditor.cpp",
            "../../libc/cimCTE/ImGuiColorTextEdit/TextDiff.cpp",
            "../../libc/cimCTE/ImGuiColorTextEdit/extras/TrieAutoComplete.cpp",
            "../../libc/cimCTE/ImGuiColorTextEdit/example/dejavu.cpp",
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = mod_name,
        .root_module = mod,
    });
    b.installArtifact(lib);
}
