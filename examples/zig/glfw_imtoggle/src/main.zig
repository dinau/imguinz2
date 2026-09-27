const app = @import("appimgui");
const ig = app.ig;
const ifa = app.ifa;

const tgl = @import("imtoggle");

//-----------
// gui_main()
//-----------
pub fn gui_main(window: *app.Window) void {
    _ = app.stf.setupFonts(null); // null: Setup default CJK fonts and Icon fonts

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

        //-----------------------
        // Show ImToggle window
        //-----------------------
        {
            const green = ig.ImVec4{ .x = 0.16, .y = 0.66, .z = 0.45, .w = 1.0 };
            const green_hover = ig.ImVec4{ .x = 0.0, .y = 1.0, .z = 0.57, .w = 1.0 };
            const green_shadow = ig.ImVec4{ .x = 0.0, .y = 1.0, .z = 0.0, .w = 0.4 };
            var value_index: usize = 0;
            const sz: tgl.ImVec2 = .{ .x = 0.0, .y = 0.0 };
            const sThemeClassic = "Theme: Classic";
            const sThemeLight = "Theme: Light";
            const st = struct {
                var values = [8]bool{ true, true, true, true, true, true, true, true };
                var sTheme: []const u8 = sThemeClassic[0..];
            };
            _ = ig.ImGui_Begin("ImToggle: Dear Bindings in Zig  2025/07 " ++ ifa.ICON_FA_KIWI_BIRD, null, 0);
            defer ig.ImGui_End();

            if (tgl.Toggle("##toggle1", &st.values[value_index], sz)) {
                if (st.values[value_index]) {
                    st.sTheme = sThemeClassic[0..];
                    ig.ImGui_StyleColorsClassic(null);
                } else {
                    st.sTheme = sThemeLight[0..];
                    ig.ImGui_StyleColorsLight(null);
                }
            }
            ig.ImGui_SameLine();
            ig.ImGui_Text("%s", st.sTheme.ptr);
            ig.ImGui_Separator();
            value_index += 1;

            //----------------
            // Default Toggle
            //----------------
            _ = tgl.Toggle("Default Toggle", &st.values[value_index], sz);
            ig.ImGui_SameLine();
            value_index += 1;

            //-----------------
            // Animated Toggle
            //-----------------
            _ = tgl.ToggleAnim("Animated Toggle", &st.values[value_index], tgl.ImGuiToggleFlags_Animated, 1.0, sz);
            value_index += 1;

            //---------------
            // Bordered Knob
            //---------------
            // This toggle draws a simple border around it's frame and knob
            _ = tgl.ToggleAnim("Bordered Knob", &st.values[value_index], tgl.ImGuiToggleFlags_Bordered, 1.0, sz);
            ig.ImGui_SameLine();
            value_index += 1;

            //---------------
            // Shadowed Knob
            //---------------
            ig.ImGui_PushStyleColorImVec4(ig.ImGuiCol_BorderShadow, green_shadow);
            _ = tgl.ToggleAnim("Shadowed Knob", &st.values[value_index], tgl.ImGuiToggleFlags_Shadowed, 1.0, sz);
            value_index += 1;
            //
            //--------------------------
            // Bordered + Shadowed Knob
            //--------------------------
            _ = tgl.ToggleAnim("Bordered + Shadowed Knob", &st.values[value_index], tgl.ImGuiToggleFlags_Bordered | tgl.ImGuiToggleFlags_Shadowed, 1.0, sz);
            value_index += 1;
            ig.ImGui_PopStyleColor();

            //--------------
            // Green Toggle
            //--------------
            // This toggle uses stack-pushed style colors to change the way it displays
            ig.ImGui_PushStyleColorImVec4(ig.ImGuiCol_Button, green);
            ig.ImGui_PushStyleColorImVec4(ig.ImGuiCol_ButtonHovered, green_hover);
            _ = tgl.Toggle("Green Toggle", &st.values[value_index], sz);
            ig.ImGui_SameLine();
            ig.ImGui_PopStyleColorEx(2);
            value_index += 1;

            //-------------------------
            // Toggle with A11y Labels
            //-------------------------
            _ = tgl.ToggleFlag("Toggle with A11y Labels", &st.values[value_index], tgl.ImGuiToggleFlags_A11y, sz);
            value_index += 1;
        }

        //------------------
        // Show info window
        //------------------
        window.showInfoWindow(); // See:  ../../src/libzig/appimgui/appImGui.zig

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

    _ = window.setTheme(.classic); // Theme: dark, classic, light, microsoft

    //---------------
    // GUI main proc
    //---------------
    gui_main(&window);
}
