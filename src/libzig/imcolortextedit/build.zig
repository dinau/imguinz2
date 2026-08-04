const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_name = "imcolortextedit";

    // -------
    // module
    // -------
    const step = b.addTranslateC(.{
        .root_source_file = b.path("src/impl_imcte.h"),
        .target = target,
        .optimize = optimize,
    });

    step.defineCMacro("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    step.addIncludePath(b.path("./src"));
    step.addIncludePath(b.path("../../libc/dcimgui"));
    step.addIncludePath(b.path("../../libc/imgui"));
    step.addIncludePath(b.path("../../libc/cimCTE"));
    step.addIncludePath(b.path("../../libc/cimgui"));
    //
    const mod = step.addModule(mod_name);
    mod.addImport(mod_name, mod);
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
