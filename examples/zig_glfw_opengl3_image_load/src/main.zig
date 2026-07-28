const std = @import("std");
const builtin = @import("builtin");
const app = @import("appimgui");
const ig = app.ig;
const glfw = app.glfw;
const ifa = app.ifa;
const utils = app.utils;

const TImgFormat = struct {
    kind: [:0]const u8,
    ext: [:0]const u8,
};
const enKind = enum { jpg, png, bmp, tga };
const ImgFormatTbl = [_]TImgFormat{ TImgFormat{ .kind = "JPEG 90%", .ext = ".jpg" }, TImgFormat{ .kind = "PNG     ", .ext = ".png" }, TImgFormat{ .kind = "BMP     ", .ext = ".bmp" }, TImgFormat{ .kind = "TGA     ", .ext = ".tga" } };

var cbItemIndex: usize = @intFromEnum(enKind.jpg);

// Constants
const SaveImageName = "ImageSaved";
const IMGUI_HAS_DOCK = false; // Docking feature

//------------
// gui_main()
//------------
pub fn gui_main(window: *app.Window) !void {
    //-------------
    // Global vars
    //-------------
    var showDemoWindow = true;
    var counter: i32 = 0;
    // Input text buffer
    var sTextInputBuf: [200:0]u8 = std.mem.zeroes([200:0]u8);

    //------------
    // Load image
    //------------
    //const ImageName = "himeji-400.jpg";
    const ImageName = "resources/fuji-cherry-480.jpg";
    var textureId: glfw.GLuint = undefined;
    var textureWidth: c_int = 0;
    var textureHeight: c_int = 0;
    _ = utils.LoadTextureFromFile(ImageName, &textureId, &textureWidth, &textureHeight);

    _ = app.stf.setupFonts(null); // null: Setup default CJK fonts and Icon fonts

    var zoomTextureID: glfw.GLuint = 0; //# Must be == 0 at first
    defer glfw.glDeleteTextures(1, &zoomTextureID);

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
        window.showInfoWindow();

        //------------------
        // Show main window
        //------------------
        {
            _ = ig.ImGui_Begin(ifa.ICON_FA_THUMBS_UP ++ " Dear ImGui", null, 0);
            defer ig.ImGui_End();

            _ = ig.ImGui_InputTextWithHint("InputText", "Input text here", &sTextInputBuf, sTextInputBuf.len, 0);
            ig.ImGui_Text("Input result:");
            ig.ImGui_SameLine();
            ig.ImGui_Text(&sTextInputBuf);

            ig.ImGui_Spacing();
            _ = ig.ImGui_Checkbox("Demo Window", &showDemoWindow);
            // Save button for capturing window image
            ig.ImGui_PushIDInt(0);
            ig.ImGui_PushStyleColorImVec4(ig.ImGuiCol_Button, utils.vec4(0.7, 0.7, 0.0, 1.0));
            ig.ImGui_PushStyleColorImVec4(ig.ImGuiCol_ButtonHovered, utils.vec4(0.8, 0.8, 0.0, 1.0));
            ig.ImGui_PushStyleColorImVec4(ig.ImGuiCol_ButtonActive, utils.vec4(0.9, 0.9, 0.0, 1.0));
            ig.ImGui_PushStyleColorImVec4(ig.ImGuiCol_Text, utils.vec4(0.0, 0.0, 0.0, 1.0));

            // Image save button
            const imageExt = ImgFormatTbl[cbItemIndex].ext;
            var svNameBuf: [2048]u8 = undefined;
            var svBuf: [2048]u8 = undefined;

            var slszName: [:0]u8 = undefined;
            if (builtin.zig_version.minor >= 17) {
                slszName = try std.fmt.bufPrintSentinel(&svNameBuf, "{s}_{}{s}", .{ SaveImageName, counter, imageExt }, 0);
            } else {
                slszName = try std.fmt.bufPrintZ(&svNameBuf, "{s}_{}{s}", .{ SaveImageName, counter, imageExt });
            }

            if (ig.ImGui_Button("Save Image")) {
                const wkSize = ig.ImGui_GetMainViewport().*.WorkSize;
                const sx: c_int = @intFromFloat(wkSize.x);
                const sy: c_int = @intFromFloat(wkSize.y);
                std.debug.print("[{s}]\n", .{slszName});
                utils.saveImage(slszName.ptr, 0, 0, sx, sy, 3, 90); // # --- Save Image ! TODO: Crash !
            }
            ig.ImGui_PopStyleColorEx(4);
            ig.ImGui_PopID();

            // Show tooltip help
            //
            var slszBuf: [:0]u8 = undefined;
            if (builtin.zig_version.minor >= 17) {
                slszBuf = try std.fmt.bufPrintSentinel(&svBuf, "Save to {s}", .{slszName}, 0);
            } else {
                slszBuf = try std.fmt.bufPrintZ(&svBuf, "Save to {s}", .{slszName});
            }

            const green = utils.vec4(0.0, 1.0, 0.0, 1.0);
            utils.setTooltipEx(slszBuf, ig.ImGuiHoveredFlags_DelayNone, green);
            counter += 1;

            ig.ImGui_SameLine();
            // ComboBox: Select save image format
            ig.ImGui_SetNextItemWidth(100);
            if (ig.ImGui_BeginCombo("##combo1", ImgFormatTbl[cbItemIndex].kind, 0)) {
                for (0..ImgFormatTbl.len) |n| {
                    var is_selected = (cbItemIndex == n);
                    if (ig.ImGui_SelectableBoolPtr(ImgFormatTbl[n].kind, &is_selected, 0)) {
                        if (is_selected) {
                            ig.ImGui_SetItemDefaultFocus();
                        }
                        cbItemIndex = n;
                    }
                }
                ig.ImGui_EndCombo();
            }
            const yellow = utils.vec4(1.0, 1.0, 0.0, 1.0);
            utils.setTooltipEx("Select image format", ig.ImGuiHoveredFlags_DelayNone, yellow);

            // Show icon fonts
            ig.ImGui_SeparatorText(ifa.ICON_FA_WRENCH ++ " Icon font test ");
            ig.ImGui_Text(ifa.ICON_FA_TRASH_CAN ++ " Trash");

            ig.ImGui_Spacing();
            ig.ImGui_Text(ifa.ICON_FA_MAGNIFYING_GLASS_PLUS ++ " " ++ ifa.ICON_FA_POWER_OFF ++ " " ++ ifa.ICON_FA_MICROPHONE ++ " " ++ ifa.ICON_FA_MICROCHIP ++ " " ++ ifa.ICON_FA_VOLUME_HIGH ++ " " ++ ifa.ICON_FA_SCISSORS ++ " " ++ ifa.ICON_FA_SCREWDRIVER_WRENCH ++ " " ++ ifa.ICON_FA_BLOG);
        } // end main window

        //------------------------
        // Show image load window
        //------------------------
        {
            _ = ig.ImGui_Begin("Image load test", null, 0);
            defer ig.ImGui_End();
            // Load image
            const size = utils.vec2(@floatFromInt(textureWidth), @floatFromInt(textureHeight));
            const imageBoxPosTop = ig.ImGui_GetCursorScreenPos(); // # Get absolute pos.

            ig.ImGui_Image(ig.ImTextureRef{ ._TexData = null, ._TexID = textureId }, size);
            const imageBoxPosEnd = ig.ImGui_GetCursorScreenPos(); // # Get absolute pos.
            if (ig.ImGui_IsItemHovered(ig.ImGuiHoveredFlags_DelayNone)) {
                utils.zoomGlass(&textureId, textureWidth, imageBoxPosTop, imageBoxPosEnd, false);
            }
        }
        // Rendering
        window.render();
    } // while end

} // gui_main end

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

    _ = app.setTheme(.classic); // Theme: dark, classic, light, microsoft

    //---------------
    // GUI main proc
    //---------------
    try gui_main(&window);
}
