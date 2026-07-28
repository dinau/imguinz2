const std = @import("std");
const builtin = @import("builtin");
const app = @import("appimgui");
const ig = app.ig;
const ifa = app.ifa;
const is_devel_api = builtin.zig_version.minor >= 16;
const io = if (is_devel_api) std.Io.Threaded.global_single_threaded.io() else undefined;

const cte = @import("imcolortextedit");

fn point2px(point: f32) f32 {
    return (point * 96) / 72;
}

//-----------
// gui_main()
//-----------
pub fn gui_main(window: *app.Window) !void {
    _ = app.stf.setupFonts(null); // null: Setup default CJK fonts and Icon fonts

    //-- This is a programing font. https://github.com/yuru7/NOTONOTO
    const fontFullPath = "resources/fonts/NOTONOTO-Regular.ttf";
    const fileName = "resources/main.cpp";

    const allocator = std.heap.page_allocator;

    const file = if (is_devel_api) blk: {
        break :blk try std.Io.Dir.cwd().openFile(io, fileName, .{});
    } else blk: {
        break :blk try std.fs.cwd().openFile(fileName, .{});
    };
    defer {
        if (is_devel_api) {
            file.close(io);
        } else {
            file.close();
        }
    }

    const stat = if (is_devel_api) blk: {
        break :blk try file.stat(io);
    } else blk: {
        break :blk try file.stat();
    };

    const file_size = stat.size;

    const sBuffer = try allocator.alloc(u8, file_size);
    defer allocator.free(sBuffer);

    if (is_devel_api) {
        _ = try file.readStreaming(io, &.{sBuffer});
    } else {
        _ = try file.readAll(sBuffer);
    }

    const editor = cte.TextEditor_TextEditor();
    cte.TextEditor_SetLanguageDefinition(editor, cte.Cpp);
    cte.TextEditor_SetText(editor, sBuffer.ptr);

    cte.TextEditor_SetPalette(editor, cte.Dark); // Dark, Light, etc
    var mLine: c_int = undefined;
    var mColumn: c_int = undefined;
    var fQuit = false;

    const pio = ig.ImGui_GetIO();
    //-- Setup programing fonts
    const textPoint = 14.5;
    const textFont = ig.ImFontAtlas_AddFontFromFileTTF(pio.*.Fonts, fontFullPath, point2px(textPoint), null, null);

    //---------------
    // main loop GUI
    //---------------
    while (!window.shouldClose()) {
        window.pollEvents();

        // Iconify sleep
        if (window.isIconified()) {
            continue;
        }

        // Start the Dear ImGui frame
        window.frame();

        //------------------
        // Show demo window
        //------------------
        ig.ImGui_ShowDemoWindow(null);

        //------------------
        // Show info window
        //------------------
        window.showInfoWindow(); // See:  ../../src/libzig/appimgui/appImGui.zig

        //---------------------------------
        //--- Show ImGuiColorTextEdit demo
        //---------------------------------
        {
            _ = ig.ImGui_Begin("ImGui_ColorTextedit Dear ImGui: Dear bindings " ++ ifa.ICON_FA_DOG, null, ig.ImGuiWindowFlags_HorizontalScrollbar | ig.ImGuiWindowFlags_MenuBar);
            defer ig.ImGui_End();
            cte.TextEditor_GetCursorPosition(editor, &mLine, &mColumn);

            ig.ImGui_SetWindowSize(.{ .x = 800, .y = 600 }, ig.ImGuiCond_FirstUseEver);
            if (ig.ImGui_BeginMenuBar()) {
                defer ig.ImGui_EndMenuBar();
                //-------------
                //-- Menu File
                //-------------
                if (ig.ImGui_BeginMenu("File")) {
                    defer ig.ImGui_EndMenu();
                    if (ig.ImGui_MenuItemBoolPtr("Save", "Ctrl-S", null, true)) {
                        copyCstrToString(sBuffer, cte.TextEditor_GetText(editor));
                        //--writeFile("main.cpp", strText)
                        //print"saved"
                    }
                    if (ig.ImGui_MenuItemEx("Quit", "Alt-F4", false, true)) {
                        fQuit = true;
                        //print"quit";
                    }
                }
                //-------------
                //-- Menu Edit
                //-------------
                if (ig.ImGui_BeginMenu("Edit")) {
                    defer ig.ImGui_EndMenu();
                    var ro = cte.TextEditor_IsReadOnlyEnabled(editor);
                    if (ig.ImGui_MenuItemBoolPtr("Read-only mode", null, &ro, true)) {
                        cte.TextEditor_SetReadOnlyEnabled(editor, ro);
                    }
                    ig.ImGui_Separator();
                    //
                    if (ig.ImGui_MenuItemBoolPtr("Undo", "ALT-Backspace", null, !ro and cte.TextEditor_CanUndo(editor))) {
                        cte.TextEditor_Undo(editor, 1);
                    }
                    if (ig.ImGui_MenuItemBoolPtr("Redo", "Ctrl-Y", null, !ro and cte.TextEditor_CanRedo(editor))) {
                        cte.TextEditor_Redo(editor, 1);
                    }
                    ig.ImGui_Separator();
                    //
                    if (ig.ImGui_MenuItemBoolPtr("Copy", "Ctrl-C", null, cte.TextEditor_AnyCursorHasSelection(editor))) {
                        cte.TextEditor_Copy(editor);
                    }
                    if (ig.ImGui_MenuItemBoolPtr("Cut", "Ctrl-X", null, !ro and cte.TextEditor_AnyCursorHasSelection(editor))) {
                        cte.TextEditor_Cut(editor);
                    }
                    if (ig.ImGui_MenuItemBoolPtr("Paste", "Ctrl-V", null, !ro and ig.ImGui_GetClipboardText() != null)) {
                        cte.TextEditor_Paste(editor);
                    }
                    ig.ImGui_Separator();
                    if (ig.ImGui_MenuItemEx("Select all", "Ctrl-A", false, true)) {
                        cte.TextEditor_SelectAll(editor);
                    }
                }
                //-------------
                //-- Menu Theme
                //-------------
                if (ig.ImGui_BeginMenu("Theme")) {
                    defer ig.ImGui_EndMenu();
                    if (ig.ImGui_MenuItemEx("Dark palette", null, false, true)) {
                        cte.TextEditor_SetPalette(editor, cte.Dark);
                    }
                    if (ig.ImGui_MenuItemEx("Light palette", null, false, true)) {
                        cte.TextEditor_SetPalette(editor, cte.Light);
                    }
                    if (ig.ImGui_MenuItemEx("Mariana palette", null, false, true)) {
                        cte.TextEditor_SetPalette(editor, cte.Mariana);
                    }
                    if (ig.ImGui_MenuItemEx("Retro blue palette", "Ctrl-B", false, true)) {
                        cte.TextEditor_SetPalette(editor, cte.RetroBlue);
                    }
                }
            } //-- menubar end

            const langNames = [_][*c]const u8{ "None", "Cpp", "C", "Cs", "Python", "Lua", "Json", "Sql", "AngelScript", "Glsl", "Hlsl" };
            var str1: [10]u8 = undefined;
            copyStringToCstr(&str1, "Ins");
            if (cte.TextEditor_IsOverwriteEnabled(editor)) {
                copyStringToCstr(&str1, "Ovr");
            }
            var str2: [10]u8 = undefined;
            str2[0] = ' ';
            str2[1] = 0;
            if (cte.TextEditor_CanUndo(editor)) {
                copyStringToCstr(&str2, "*");
            }
            ig.ImGui_Text("%6d/%-6d %6d lines  | %s | %s | %s | %s", mLine + 1, mColumn + 1, cte.TextEditor_GetLineCount(editor), &str1, &str2, langNames[cte.TextEditor_GetLanguageDefinition(editor)], fileName);

            ig.ImGui_PushFont(textFont);
            _ = cte.TextEditor_Render(editor, "texteditor", false, .{ .x = 0, .y = 0 }, false);
            ig.ImGui_PopFont();
        } // end igBegin
        //--------
        // render
        //--------
        window.render();
    } // end while loop
}

//--------
// main()
//--------
const MainWinWidth: i32 = 1024;
const MainWinHeight: i32 = 900;

pub fn main() !void {
    var window = try app.Window.createImGui(
        MainWinWidth,
        MainWinHeight,
        "Dear ImGui window in Zig",
        .{},
    );
    defer window.destroyImGui();

    _ = app.setTheme(.dark); // Theme: dark, classic, light, microsoft

    //---------------
    // GUI main proc
    //---------------
    try gui_main(&window);
}

//---------------------
//--- copyCstrToString
//---------------------
fn copyCstrToString(sBuff: []u8, cstr: [*:0]const u8) void {
    const len = std.mem.len(cstr);
    std.mem.copyForwards(u8, sBuff[0..len], cstr[0..len]);
    sBuff[len] = 0;
}
//---------------------
//--- copyStringToCstr
//---------------------
fn copyStringToCstr(sBuff: []u8, str: []const u8) void {
    const len = @min(sBuff.len, str.len);
    std.mem.copyForwards(u8, sBuff[0..len], str[0..len]);
    if (len < sBuff.len) {
        sBuff[len] = 0;
    }
}
