const app = @import("appimgui");
const ig = app.ig;
const zmi = @import("imguizoomableimage");

// gui_main()
pub fn gui_main(win: *app.Window) void {

    win.eventLoadStandard(); // See ../../../src/libzig/appimgui/src/appImGui.zig

    var zoomState: zmi.ImGuiImageState = undefined;
    zmi.ImGuiImage_State_Init(&zoomState);

    // Load texture
    const imageName = "./resources/dinosaurs_paradise.jpg";
    var textureId: u32 = 0;
    var textureWidth: i32 = 0;
    var textureHeight: i32 = 0;

    _ = app.utils.LoadTextureFromFile(imageName, &textureId, &textureWidth, &textureHeight);

    const textureRef: zmi.ImTextureRef= .{ ._TexID = textureId };

    const pio = ig.ImGui_GetIO();

    // main loop GUI
    while (!win.shouldClose()) {
        zmi.ImGuiImage_State_Init(null);
        win.pollEvents();

        // Iconify sleep
        if (win.isIconified()) {
            continue;
        }

        // Start the Dear ImGui frame
        win.frame();

        // Show demo window
        ig.ImGui_ShowDemoWindow(null);

        // Show info window
        win.showInfoWindow(); // See:  ../../../src/libzig/appimgui/appImGui.zig

        // Zoomable Image Demo
        const viewport = ig.ImGui_GetMainViewport().?;
        const frameSize = viewport.*.Size;
        const imageWindowPos = ig.ImVec2{ .x = frameSize.x * 0.1, .y = frameSize.y * 0.1 };
        const imageWindowSize = ig.ImVec2{ .x = frameSize.x * 0.5, .y = frameSize.y * 0.5 };
        const controlsWindowPos = ig.ImVec2{ .x = frameSize.x * 0.7, .y = frameSize.y * 0.1 };

        ig.ImGui_SetNextWindowPos(imageWindowPos, ig.ImGuiCond_FirstUseEver);
        ig.ImGui_SetNextWindowSize(imageWindowSize, ig.ImGuiCond_FirstUseEver);

        zoomState.textureSize = .{ .x = @as(f32, @floatFromInt(textureWidth)), .y = @as(f32, @floatFromInt(textureHeight)) };

        _ = ig.ImGui_Begin("ImGui Zoomable Image demo in Zig " ++ app.ifa.ICON_FA_DOG, null, 0);
        const displaySize = ig.ImGui_GetContentRegionAvail();
        zmi.ImGuiImage_Zoomable(textureRef, @ptrCast(&displaySize), &zoomState);
        ig.ImGui_End();

        // Controls Window
        ig.ImGui_SetNextWindowPos(controlsWindowPos, ig.ImGuiCond_FirstUseEver);
        _ = ig.ImGui_Begin("Controls Window", null, 0);
        {
            _ = ig.ImGui_Checkbox("Enable Zoom/Pan", &zoomState.zoomPanEnabled);
            _ = ig.ImGui_Checkbox("Maintain Aspect Ratio", &zoomState.maintainAspectRatio);

            if (ig.ImGui_Button("Reset Zoom/Pan")) {
                zoomState.zoomLevel = 1.0;
                zoomState.panOffset = .{ .x = 0.0, .y = 0.0 };
            }

            ig.ImGui_Separator();
            ig.ImGui_Text("Texture Size: %d x %d", textureWidth, textureHeight);
            ig.ImGui_Text("Display Size: %.0f x %.0f", displaySize.x, displaySize.y);
            ig.ImGui_Text("Zoom Level: %.2f%%", zoomState.zoomLevel * 100.0);
            ig.ImGui_Text("Pan Offset: (%.2f, %.2f)", zoomState.panOffset.x * @as(f32, @floatFromInt(textureWidth)), zoomState.panOffset.y * @as(f32, @floatFromInt(textureHeight)));
            ig.ImGui_Text("Mouse Pos: (%.2f, %.2f)", zoomState.mousePosition.x, zoomState.mousePosition.y);

            ig.ImGui_Separator();
            ig.ImGui_Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / pio.*.Framerate, pio.*.Framerate);
        }
        ig.ImGui_End();

        // render
        win.render();
    } // end while loop
}

// main()
const MainWinWidth: i32 = 1024;
const MainWinHeight: i32 = 900;

pub fn main() !void {
    var window = try app.Window.createImGui(MainWinWidth, MainWinHeight, "ImGui window in Zig");
    defer window.destroyImGui();

    _ = app.stf.setupFonts(null); // null: Setup default CJK fonts and Icon fonts
    //_ = app.setTheme(.light); // Theme: dark, classic, light, microsoft

    // GUI main proc
    gui_main(&window);
}
