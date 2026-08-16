const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_name = "zig_sdl3_sdlgpu3";

    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = main_mod,
    });

    const imguinz = b.dependency("imguinz", .{});
    const dependencies = .{
        "dcimgui",
        "sdl3",
        "impl_sdl3",
        "impl_sdlgpu3",
        "loadimage_sdlgpu3",
        "setupfont",
        "fonticon",
        "utils",
        // "another_lib",
    };
    inline for (dependencies) |dep_name| {
        const dep = imguinz.builder.dependency(dep_name, .{
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport(dep_name, dep.module(dep_name));
    }

    // Load Icon
    exe.root_module.addWin32ResourceFile(.{ .file = b.path("src/res/res.rc") });

    //---------------
    //---------------
    // Libs
    //---------------
    const sdl_path = "../../src/libc/sdl/SDL3/x86_64-w64-mingw32";
    if (target.result.os.tag == .windows) {
        exe.root_module.linkSystemLibrary("gdi32", .{});
        exe.root_module.linkSystemLibrary("imm32", .{});
        exe.root_module.linkSystemLibrary("advapi32", .{});
        exe.root_module.linkSystemLibrary("comdlg32", .{});
        exe.root_module.linkSystemLibrary("dinput8", .{});
        exe.root_module.linkSystemLibrary("dxerr8", .{});
        exe.root_module.linkSystemLibrary("dxguid", .{});
        exe.root_module.linkSystemLibrary("gdi32", .{});
        exe.root_module.linkSystemLibrary("hid", .{});
        exe.root_module.linkSystemLibrary("kernel32", .{});
        exe.root_module.linkSystemLibrary("ole32", .{});
        exe.root_module.linkSystemLibrary("oleaut32", .{});
        exe.root_module.linkSystemLibrary("setupapi", .{});
        exe.root_module.linkSystemLibrary("shell32", .{});
        exe.root_module.linkSystemLibrary("user32", .{});
        exe.root_module.linkSystemLibrary("uuid", .{});
        exe.root_module.linkSystemLibrary("version", .{});
        exe.root_module.linkSystemLibrary("winmm", .{});
        exe.root_module.linkSystemLibrary("winspool", .{});
        exe.root_module.linkSystemLibrary("ws2_32", .{});
        exe.root_module.linkSystemLibrary("opengl32", .{});
        exe.root_module.linkSystemLibrary("shell32", .{});
        exe.root_module.linkSystemLibrary("user32", .{});
        // sdl3
        //exe.addLibraryPath(b.path(b.pathJoin(&.{sdl3_path, "lib-mingw-64"})));
        //exe.linkSystemLibrary("sdl3");      // For static link
        // Static link
        //exe.addObjectFile(b.path(b.pathJoin(&.{sdl3_path, "lib","SDL3.lib"})));
        // Dynamic link
        exe.root_module.addObjectFile(.{ .cwd_relative = b.pathJoin(&.{
            sdl_path,
            "lib",
            "libSDL3.dll.a",
        }) });
        //exe.linkSystemLibrary("sdl3dll"); // For dynamic link
        // System
    } else if (target.result.os.tag == .linux) {
        exe.root_module.linkSystemLibrary("sdl3", .{});
    }

    // root_module
    exe.root_module.link_libc = true;
    exe.root_module.link_libcpp = true;

    // Hide console window
    exe.subsystem = if (builtin.zig_version.minor >= 17) .windows else .windows;

    b.installArtifact(exe);

    const install_resources = b.addInstallDirectory(.{
        .source_dir = b.path("resources"), // base: assets folder
        .install_dir = .bin, // bin folder
        .install_subdir = "resources", // destination: bin/resources/
    });
    exe.step.dependOn(&install_resources.step);

    const resBin = [_][]const u8{"imgui.ini"};
    inline for (resBin) |file| {
        const res = b.addInstallFile(b.path(file), "bin/" ++ file);
        b.getInstallStep().dependOn(&res.step);
    }

    const fonticon_dir = "../../src/libc/fonticon/fa6/";
    const res_fonticon = [_][]const u8{
        "fa-solid-900.ttf",
        "LICENSE.txt",
    };
    inline for (res_fonticon) |file| {
        const res = b.addInstallFile(b.path(fonticon_dir ++ file), "bin/resources/fonticon/fa6/" ++ file);
        b.getInstallStep().dependOn(&res.step);
    }

    //// SDL3.dll
    //if (target.result.os.tag == .windows) {
    //    const sdl3dll = "SDL3.dll";
    //    const resSDL3Dll = b.addInstallFile(.{.cwd_relative = b.fmt("{s}/{s}/{s}", .{sdl_path, "bin", sdl3dll})}, "bin/" ++ sdl3dll);
    //    b.getInstallStep().dependOn(&resSDL3Dll.step);
    //}

    // save [Executable name].ini
    const sExeIni = b.fmt("{s}.ini", .{exe_name});
    const resExeIni = b.addInstallFile(b.path(sExeIni), b.pathJoin(&.{ "bin", sExeIni }));
    b.getInstallStep().dependOn(&resExeIni.step);

    // run
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (builtin.zig_version.minor >= 17) {
        run_cmd.addPassthruArgs();
    } else {
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
