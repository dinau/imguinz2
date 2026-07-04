const std = @import("std");
const app = @import("appimgui");
const ig = app.ig;
const glfw = app.glfw;
const ifa = app.ifa;
const utils = app.utils;
const ift = @import("./iconFontsTblDef.zig");

const MainWinWidth: i32 = 1200;
const MainWinHeight: i32 = 800;

//-----------
// gui_main()
//-----------
pub fn gui_main(window: *app.Window) !void {
    _ = app.stf.setupFonts(null); // null: Setup default CJK fonts and Icon fonts

    const pio = ig.ImGui_GetIO();

    var item_current: usize = 0;
    var showIconFontsViewerWindow = true;
    var wsZoom:f32 = 45;

    var listBoxTextureID: glfw.GLuint = 0; //# Must be == 0 at first
    defer glfw.glDeleteTextures(1, &listBoxTextureID);
    //---------------
    // main loop GUI
    //---------------
    while (!window.shouldClose ()) {
        window.pollEvents ();

        // Iconify sleep
        if( window.isIconified()){
            continue;
        }

        // Start the Dear ImGui frame
        window.frame();

        //------------------
        // Show demo window
        //------------------
        ig.ImGui_ShowDemoWindow(null);
        window.showInfoWindow();

        //-----------------------------
        // Show IconFontsViewer window
        //------------------------------
        if (showIconFontsViewerWindow) {
            _ = ig.ImGui_Begin("Icon Font Viewer", &showIconFontsViewerWindow, 0);
            defer ig.ImGui_End();
            ig.ImGui_SeparatorText(ifa.ICON_FA_FONT_AWESOME ++ " Icon font view: " ++ " icons");

            const listBoxWidth = 340; //# The value must be 2^n
            ig.ImGui_Text("No.[%4d]", item_current);
            ig.ImGui_SameLine();
            var sBuf: [100:0]u8 = std.mem.zeroes([100:0]u8);
            _ = try std.fmt.bufPrint(&sBuf, "{s}", .{ift.iconFontsTbl[item_current]});
            if (ig.ImGui_Button(ifa.ICON_FA_COPY ++ " Copy to")) {
                var it = std.mem.tokenizeAny(u8, &sBuf, " ");
                _ = it.next().?;
                ig.ImGui_SetClipboardText(it.next().?.ptr);
            }
            utils.setTooltip("Clipboard", ig.ImGuiHoveredFlags_DelayNone); //# Show tooltip help
            //# Show ListBox header
            ig.ImGui_SetNextItemWidth(listBoxWidth);
            _ = ig.ImGui_InputText("##ipttxt1", sBuf[0..], sBuf.len, ig.ImGuiTextFlags_None);

            //# Show ListBox main
            ig.ImGui_NewLine();
            const listBoxPosTop =  ig.ImGui_GetCursorScreenPos(); //# Get absolute pos.
            ig.ImGui_SetNextItemWidth(listBoxWidth);
            _ = ig.ImGui_ListBox("##listbox1", @ptrCast(&item_current), &ift.iconFontsTbl, ift.iconFontsTbl.len, 34);
            // TODO
            const listBoxPosEnd = ig.ImGui_GetCursorScreenPos(); // # Get absolute pos.
            // # Show magnifying glass (Zooming in Toolchip)
            if (ig.ImGui_IsItemHovered(ig.ImGuiHoveredFlags_DelayNone)) {
                if ((pio.*.MousePos.x - listBoxPosTop.x) < 50) {
                    utils.zoomGlass(&listBoxTextureID, listBoxWidth, listBoxPosTop, listBoxPosEnd, true);
                }
            }
        }

        //---------------------
        // Show icons in Table
        //---------------------
        {
            _ = ig.ImGui_Begin("Icon Font Viewer2", null, 0);
            defer ig.ImGui_End();

            ig.ImGui_Text("%s", " Zoom x");
            ig.ImGui_SameLine();
            _ = ig.ImGui_SliderFloat("##Zoom1", &wsZoom, 30, 90);
            ig.ImGui_Separator();

            _ = ig.ImGui_BeginChild("child2", .{.x = 0, .y = 0}, 0, 0);
            defer ig.ImGui_EndChild();

            const flags = ig.ImGuiTableFlags_RowBg | ig.ImGuiTableFlags_BordersOuter | ig.ImGuiTableFlags_BordersV | ig.ImGuiTableFlags_Resizable | ig.ImGuiTableFlags_Reorderable | ig.ImGuiTableFlags_Hideable;
            const text_base_height = ig.ImGui_GetTextLineHeightWithSpacing();
            const outer_size = utils.vec2(0.0, text_base_height * 8);
            const col = 10;
            {
                _ = ig.ImGui_BeginTableEx("table_scrolly", col, flags, outer_size, 0);
                defer ig.ImGui_EndTable();
                for (0..(ift.iconFontsTbl2.len / col)) |row| {
                    ig.ImGui_TableNextRow();
                    for (0..col) |column| {
                        const ix = (row * col) + column;
                        _ = ig.ImGui_TableSetColumnIndex(@intCast(column));
                        //ig.ImGui_SetWindowFontScale(wsZoom);
                        ig.ImGui_PushFontFloat(null, wsZoom);
                        //---- select 1: Text
                        ig.ImGui_Text("%s", ift.iconFontsTbl2[ix][0]);
                        //---- select 2: Button
                        //if (ig.ImGui_Button(ift.iconFontsTbl2[ix][0], DefaultButtonSize)){
                        //  item_current = ix;
                        //}
                        ig.ImGui_PopFont();
                        const iconFontLabel = std.mem.span(ift.iconFontsTbl2[ix][1]);
                        utils.setTooltipEx(iconFontLabel, ig.ImGuiHoveredFlags_DelayNone, utils.vec4(0.0, 1.0, 0.0, 1.0));
                        //ig.ImGui_SetWindowFontScale(wsNormal);
                        //
                        ig.ImGui_PushIDInt(@intCast(ix));
                        defer ig.ImGui_PopID();
                        if (ig.ImGui_BeginPopupContextItemEx("Contex Menu", 1)) {
                            defer ig.ImGui_EndPopup();
                            if (ig.ImGui_MenuItem("Copy to clip board")) {
                                item_current = ix;
                                ig.ImGui_SetClipboardText(iconFontLabel);
                            }
                        }
                    } // end for col
                } // end for row
            } // end block igBeginTable
        } // end igBegin

        { // -- Text filter window
            _ = ig.ImGui_Begin("Icon Font filter", null, 0);
            defer ig.ImGui_End();
            ig.ImGui_Text("(Copy)");
            if (ig.ImGui_IsItemHovered(ig.ImGuiHoveredFlags_DelayNone)) {
            }
            //filterAry = {}
            utils.setTooltip("Copied first line to clipboard !", ig.ImGuiHoveredFlags_DelayNone); //-- Show tooltip help
            ig.ImGui_SameLine();
            const st = struct {
                var filter: ig.ImGuiTextFilter = undefined;
            };
            ig.ImGuiTextFilter_Clear(&st.filter);
            _ = ig.ImGuiTextFilter_Draw(&st.filter, "Filter", 0.0);
            const tbl = ift.iconFontsTbl;
            for (tbl, 0..) |pstr, i| {
                if (ig.ImGuiTextFilter_PassFilter(&st.filter, pstr, null)) {
                    ig.ImGui_Text("[%04d]  %s", i, pstr);
                }
            }
        }
        //--------
        // render
        //--------
        window.render();
    } // end main while loop
}

//--------
// main()
//--------
pub fn main() !void {
    var window = try app.Window.createImGui(MainWinWidth, MainWinHeight, "ImGui window in Zig lang.");
    defer window.destroyImGui();

    //_ = app.setTheme(light); // Theme: dark, classic, light, microsoft

    //---------------
    // GUI main proc
    //---------------
    try gui_main(&window);
}
