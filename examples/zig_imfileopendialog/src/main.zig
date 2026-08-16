const std = @import("std");
const app = @import("appimgui");
const ig = app.ig;
const ifa = app.ifa;

const fld = @import("imfileopendialog");

const MainWinWidth: i32 = 1024;
const MainWinHeight: i32 = 800;

//--------
// main()
//--------
pub fn gui_main(window: *app.Window) !void {
    //-------------
    // Global vars
    //-------------
    var showDemoWindow = true;

    _ = app.stf.setupFonts(null); // null: Setup default CJK fonts and Icon fonts

    //------------------------------
    // Create FileDialog object
    //------------------------------
    const cfd = fld.IGFD_Create();
    defer fld.IGFD_Destroy(cfd);

    setFileStyle(cfd.?);

    var sFilePathName: [2048]u8 = std.mem.zeroes([2048]u8);
    var sFileDirPath: [2048]u8 = std.mem.zeroes([2048]u8);
    var sFilter: [2048]u8 = std.mem.zeroes([2048]u8);
    var sDatas: [2048]u8 = std.mem.zeroes([2048]u8);

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
        if (showDemoWindow) {
            ig.ImGui_ShowDemoWindow(&showDemoWindow);
        }

        //--------------------------
        // Show ImFileDialog window
        //--------------------------
        {
            _ = ig.ImGui_Begin("ImGuiFileDialog: Dear Bindings in Zig  2025/07 " ++ ifa.ICON_FA_DOG, null, 0);
            defer ig.ImGui_End();

            if (ig.ImGui_ButtonEx("FileOpen", .{ .x = 100, .y = 50 })) {
                //themeGold();
                //------------------------------
                // Trigger FileOpenDialog
                //------------------------------
                var config = fld.IGFD_FileDialog_Config_Get();
                config.path = ".";
                config.flags = fld.ImGuiFileDialogFlags_Modal | fld.ImGuiFileDialogFlags_ShowDevicesButton | fld.ImGuiFileDialogFlags_CaseInsensitiveExtentionFiltering
                // | ImGuiFileDialogFlags_ConfirmOverwrite
                ; // ImGuiFileDialogFlags
                fld.IGFD_OpenDialog(cfd, "filedlg", // dialog key (make it possible to have different treatment reagrding the dialog key
                    ifa.ICON_FA_FILE ++ " Open a File", // dialog title
                    "all (*){.*},c files(*.c *.h){.c,.h}", // dialog filter syntax : simple => .h,.c,.pp, etc and collections : text1{filter0,filter1,filter2}, text2{filter0,filter1,filter2}, etc..
                    // NULL,                                 // dialog filter syntax : if it wants to select directory then set NULL
                    config); // the file dialog config
            }

            //------------------------------
            // Start display FileOpenDialog
            //------------------------------
            const ioptr = ig.ImGui_GetIO();
            const maxSize = fld.ImVec2{ .x = ioptr.*.DisplaySize.x * 0.8, .y = ioptr.*.DisplaySize.y * 0.8 };
            const minSize = fld.ImVec2{ .x = maxSize.x * 0.25, .y = maxSize.y * 0.25 };

            if (fld.IGFD_DisplayDialog(cfd, "filedlg", ig.ImGuiWindowFlags_NoCollapse, minSize, maxSize)) {
                defer fld.IGFD_CloseDialog(cfd);
                if (fld.IGFD_IsOk(cfd)) { // result ok
                    var cstr = fld.IGFD_GetFilePathName(cfd, fld.IGFD_ResultMode_AddIfNoFileExt);
                    copyToString(&sFilePathName, cstr);
                    cstr = fld.IGFD_GetCurrentPath(cfd);
                    copyToString(&sFileDirPath, cstr);
                    cstr = fld.IGFD_GetCurrentFilter(cfd);
                    copyToString(&sFilter, cstr);
                    // here convert from string because a string was passed as a userDatas, but it can be what you want
                    const cdatas = fld.IGFD_GetUserDatas(cfd);
                    if (null != cdatas) {
                        copyToString(&sDatas, @ptrCast(cdatas));
                    }
                    //struct IGFD_Selection csel = IGFD_GetSelection(cfd, IGFD_ResultMode_KeepInputFile); // multi selection
                    //printf("Selection :\n");
                    //for (int i = 0; i < (int)csel.count; i++) {
                    //  printf("(%i) FileName %s => path %s\n", i, csel.table[i].fileName, csel.table[i].filePathName);
                    //}
                    //// action
                    //fld.IGFD_Selection_DestroyContent(&csel);
                }
                //setTheme(0);
            }
            // End FileOpenDialog
            ig.ImGui_Text("Selected file = %s", &sFilePathName);
            ig.ImGui_Text("Dir           = %s", &sFileDirPath);
            ig.ImGui_Text("Filter        = %s", &sFilter);
            ig.ImGui_Text("Datas         = %s", &sDatas);
        }
        // Rendering
        window.render();
    } // while end
} // main end

//-----------------
//--- setFileStyle
//-----------------
fn setFileStyle(cfd: *fld.ImGuiFileDialog) void {
    //const clGreen      = fld.ImVec4{.x = 0,    .y = 1,             .z = 0,   .w = 1};
    const clMDseagreen = fld.ImVec4{ .x = 60.0 / 255.0, .y = 179.0 / 255.0, .z = 113.0 / 255.0, .w = 1 };

    const clYellow = fld.ImVec4{ .x = 1, .y = 1, .z = 0, .w = 1 };
    const clOrange = fld.ImVec4{ .x = 1, .y = 165.0 / 255.0, .z = 0, .w = 1 };

    const clWhite2 = fld.ImVec4{ .x = 0.98, .y = 0.98, .z = 1, .w = 1 };
    const clWhite = fld.ImVec4{ .x = 1, .y = 0, .z = 1, .w = 1 };

    //const  clPurple  = fld.ImVec4{.x = 1,  .y =  51.0/255.0,    .z = 1, .w = 1};
    //const  clPurple2 = fld.ImVec4{.x = 1,  .y = 161.0/255.0,    .z = 1, .w = 1};

    const clCyan = fld.ImVec4{ .x = 0, .y = 1, .z = 1, .w = 1 };
    const clSkyblue = fld.ImVec4{ .x = 135.0 / 255.0, .y = 206.0 / 255.0, .z = 235.0 / 255.0, .w = 1 };
    const clIndigo = fld.ImVec4{ .x = 75.0 / 255.0, .y = 0, .z = 130.0 / 255.0, .w = 1 };
    const clMoccasin = fld.ImVec4{ .x = 1, .y = 228.0 / 255.0, .z = 181.0 / 255.0, .w = 1 };
    //const  clRosybrown = fld.ImVec4{.x = 188.0/255.0, .y = 143.0/255.0, .z =  143.0/255.0,.w = 1};

    //const clSteelblue = ig.ImVec4{.x = 70.0/255.0,   .y = 130.0/255.0, .z = 180.0/255.0, .w = 1};

    const pFont = @as(*fld.ImFont, @ptrCast(ig.ImGui_GetDefaultFont()));
    const byExt = fld.IGFD_FileStyleByExtention;

    fld.IGFD_SetFileStyle(cfd, byExt, ".bat", clCyan, ifa.ICON_FA_PERSON_RUNNING, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".pdb", clYellow, ifa.ICON_FA_FILE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".exe", clCyan, ifa.ICON_FA_PLANE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".EXE", clCyan, ifa.ICON_FA_PLANE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".nim", clSkyblue, ifa.ICON_FA_N, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".nelua", clSkyblue, ifa.ICON_FA_FILE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".lua", clIndigo, ifa.ICON_FA_FILE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".zig", clSkyblue, ifa.ICON_FA_FILE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".c", clMDseagreen, ifa.ICON_FA_FILE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".cpp", clMDseagreen, ifa.ICON_FA_FILE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".h", clYellow, ifa.ICON_FA_FILE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".d", clWhite2, ifa.ICON_FA_FILE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".txt", clWhite2, ifa.ICON_FA_FILE_LINES, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".TXT", clWhite2, ifa.ICON_FA_FILE_LINES, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".ini", clWhite2, ifa.ICON_FA_BAHAI, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".md", clMoccasin, ifa.ICON_FA_PEN_TO_SQUARE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".html", clMoccasin, ifa.ICON_FA_GLOBE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".gitignore", clWhite2, ifa.ICON_FA_BAHAI, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".gitmodules", clWhite2, ifa.ICON_FA_BAHAI, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".o", clWhite2, ifa.ICON_FA_SEEDLING, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".a", clWhite2, ifa.ICON_FA_BAHAI, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".rc", clWhite2, ifa.ICON_FA_BAHAI, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".res", clWhite2, ifa.ICON_FA_BAHAI, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".ico", clWhite, ifa.ICON_FA_IMAGE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".png", clWhite, ifa.ICON_FA_IMAGE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".jpg", clWhite, ifa.ICON_FA_IMAGE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".mp3", clWhite, ifa.ICON_FA_MUSIC, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".MP3", clWhite, ifa.ICON_FA_MUSIC, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".mp4", clWhite, ifa.ICON_FA_FILM, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".MP4", clWhite, ifa.ICON_FA_FILM, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".zip", clWhite, ifa.ICON_FA_FILE_ZIPPER, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".cmake", clYellow, ifa.ICON_FA_GEARS, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".mak", clWhite, ifa.ICON_FA_GEARS, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".mk", clWhite, ifa.ICON_FA_GEARS, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".dll", clWhite, ifa.ICON_FA_SNOWFLAKE, pFont);
    fld.IGFD_SetFileStyle(cfd, byExt, ".sys", clWhite, ifa.ICON_FA_SNOWMAN, pFont);
    //-- For folder
    fld.IGFD_SetFileStyle(cfd, fld.IGFD_FileStyleByTypeDir, null, clOrange, ifa.ICON_FA_FOLDER, pFont);
    //-- Regex TODO
    //--fld.IGFD_SetFileStyle(cfd, byExt , "(.+[.].+)",   clWhite2,     ICON_FA_FILE,           pFont)
}

//-----------------
//--- copyToString
//-----------------
fn copyToString(sBuff: []u8, cstr: [*:0]const u8) void {
    const len = std.mem.len(cstr);
    std.mem.copyForwards(u8, sBuff[0..len], cstr[0..len]);
    sBuff[len] = 0;
}

pub fn main() !void {
    var window = try app.Window.createImGui(
        MainWinWidth,
        MainWinHeight,
        "Dear ImGui window in Zig",
        .{},
    );
    defer window.destroyImGui();

    //_ = window.setTheme(light); // Theme: dark, classic, light, microsoft

    //---------------
    // GUI main proc
    //---------------
    try gui_main(&window);
}
