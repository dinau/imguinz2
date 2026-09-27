const app = @import("appimgui");
const ig = app.ig;

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
        .{
            .docking = true,
            .title_bar_icon_name = "./resources/z.png",
        },
    );
    defer window.destroyImGui();

    _ = window.setTheme(.dark); // Theme: dark, classic, light, microsoft

    //---------------
    // GUI main proc
    //---------------
    gui_main(&window);
}
