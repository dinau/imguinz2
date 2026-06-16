const std = @import("std");
const builtin = @import("builtin");

pub const ig = @import("dcimgui");
pub const sdl = @import("sdl3");
pub const impl_sdl3 = @import("impl_sdl3");
pub const impl_opengl3 = @import("impl_opengl3");
pub const stf = @import("setupfont");
pub const ifa = @import("fonticon");

const IMGUI_HAS_DOCK = false; // true: Can't compile at this time.

const MainWinWidth: i32 = 1024;
const MainWinHeight: i32 = 800;

//--------
// main()
//--------
pub fn main() !void {

    // Setup SDL
    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_GAMEPAD)) {
        std.debug.print("Error: {s}\n", .{sdl.SDL_GetError()});
        return error.SDL_init;
    }
    defer sdl.SDL_Quit();

    //-------------------------
    // Decide GL+GLSL versions
    //-------------------------
    const glsl_version = "#version 130";
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_FLAGS, 0);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 3);

    //_ = sdl.SDL_SetHint(sdl.SDL_HINT_IME_SHOW_UI, "1");

    // Create window with graphics context
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_STENCIL_SIZE, 8);
    const window_flags = (sdl.SDL_WINDOW_OPENGL | sdl.SDL_WINDOW_RESIZABLE | sdl.SDL_WINDOW_HIDDEN);
    const window = sdl.SDL_CreateWindow("Dear ImGui SDL3+OpenGL3 example", MainWinWidth, MainWinHeight, window_flags);
    if (window == null) {
        std.debug.print("Error: SDL_CreateWindow(): {s}\n", .{sdl.SDL_GetError()});
        return error.SDL_CreatWindow;
    }
    defer sdl.SDL_DestroyWindow(window);

    _ = sdl.SDL_SetWindowPosition(window, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED);
    const gl_context = sdl.SDL_GL_CreateContext(window);
    defer _ = sdl.SDL_GL_DestroyContext(gl_context);

    _ = sdl.SDL_GL_MakeCurrent(window, gl_context);
    _ = sdl.SDL_GL_SetSwapInterval(1); // Enable vsync
    _ = sdl.SDL_ShowWindow(window);

    // Setup Dear ImGui context
    if (ig.ImGui_CreateContext(null) == null) {
        return error.ImGuiCreateContextFailure;
    }
    defer ig.ImGui_DestroyContext(null);

    const pio = ig.ImGui_GetIO();
    pio.*.ConfigFlags |= ig.ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
    pio.*.ConfigFlags |= ig.ImGuiConfigFlags_NavEnableGamepad; // Enable Gamepad Controls
    // Setup doncking feature --- can't compile well at this moment.
    if (IMGUI_HAS_DOCK) {
        pio.*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable; // Enable Docking
        pio.*.ConfigFlags |= ig.ImGuiConfigFlags_ViewportsEnable; // Enable Multi-Viewport / Platform Windows
    }

    // Setup Dear ImGui style
    ig.ImGui_StyleColorsDark(null);
    // ig.ImGui_StyleColorsLight(null);
    // ig.ImGui_StyleColorsClassic(null);

    // Setup Platform/Renderer backends
    _ = impl_sdl3.cImGui_ImplSDL3_InitForOpenGL(@ptrCast(window), gl_context);
    defer impl_sdl3.cImGui_ImplSDL3_Shutdown();
    _ = impl_opengl3.cImGui_ImplOpenGL3_InitEx(glsl_version);
    defer impl_opengl3.cImGui_ImplOpenGL3_Shutdown();

    //-------------
    // Global vars
    //-------------
    var showDemoWindow = true;
    var showAnotherWindow = false;
    var fval: f32 = 0.0;
    var counter: i32 = 0;
    // Back ground color
    var clearColor = [_]f32{ 0.25, 0.55, 0.9, 1.0 };
    // Input text buffer
    var sTextInputBuf: [200:0]u8 = std.mem.zeroes([200:0]u8);
    var showWindowDelay: i32 = 2; // TODO: Avoid flickering of window at startup

    _ = stf.setupFonts();

    var done = false;
    while (!done) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            _ = impl_sdl3.cImGui_ImplSDL3_ProcessEvent(@ptrCast(&event));
            if (event.type == sdl.SDL_EVENT_QUIT)
                done = true;
            if ((event.type == sdl.SDL_EVENT_WINDOW_CLOSE_REQUESTED) and (event.window.windowID == sdl.SDL_GetWindowID(window)))
                done = true;
        }

        // Iconify sleep
        if (0 != (sdl.SDL_GetWindowFlags(window) & sdl.SDL_WINDOW_MINIMIZED)) {
            sdl.SDL_Delay(10);
            continue;
        }

        // Start the Dear ImGui frame
        impl_opengl3.cImGui_ImplOpenGL3_NewFrame();
        impl_sdl3.cImGui_ImplSDL3_NewFrame();
        ig.ImGui_NewFrame();

        //------------------
        // Show demo window
        //------------------
        if (showDemoWindow) {
            ig.ImGui_ShowDemoWindow(&showDemoWindow);
        }

        //------------------
        // Show main window
        //------------------
        {
            _ = ig.ImGui_Begin(ifa.ICON_FA_THUMBS_UP ++ " ImGui: Dear Bindings", null, 0);
            defer ig.ImGui_End();
            ig.ImGui_Text(ifa.ICON_FA_COMMENT ++ " SDL3 v");
            ig.ImGui_SameLine();
            ig.ImGui_Text("[%d],[%s]", sdl.SDL_GetVersion(), sdl.SDL_GetRevision());
            ig.ImGui_Text(ifa.ICON_FA_COMMENT ++ " OpenGL v");
            ig.ImGui_SameLine();
            ig.ImGui_Text(impl_opengl3.glGetString(impl_opengl3.GL_VERSION));
            ig.ImGui_Text(ifa.ICON_FA_CIRCLE_INFO ++ " Dear ImGui v");
            ig.ImGui_SameLine();
            ig.ImGui_Text(ig.ImGui_GetVersion());
            ig.ImGui_Text(ifa.ICON_FA_CIRCLE_INFO ++ " Zig v");
            ig.ImGui_SameLine();
            ig.ImGui_Text(builtin.zig_version_string);

            ig.ImGui_Spacing();
            _ = ig.ImGui_InputTextWithHint("InputText", "Input text here", &sTextInputBuf, sTextInputBuf.len, 0);
            ig.ImGui_Text("Input result:");
            ig.ImGui_SameLine();
            ig.ImGui_Text(&sTextInputBuf);

            ig.ImGui_Spacing();
            _ = ig.ImGui_Checkbox("Demo Window", &showDemoWindow);
            _ = ig.ImGui_Checkbox("Another Window", &showAnotherWindow);

            _ = ig.ImGui_SliderFloat("Float", &fval, 0.0, 1.0);
            _ = ig.ImGui_ColorEdit3("Background color", &clearColor, 0);

            if (ig.ImGui_Button("Button")) counter += 1;
            ig.ImGui_SameLine();
            ig.ImGui_Text("Counter = %d", counter);
            ig.ImGui_Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / pio.*.Framerate, pio.*.Framerate);
            // Show icon fonts
            ig.ImGui_SeparatorText(ifa.ICON_FA_WRENCH ++ " Icon font test ");
            ig.ImGui_Text(ifa.ICON_FA_TRASH_CAN ++ " Trash");

            ig.ImGui_Spacing();
            ig.ImGui_Text(ifa.ICON_FA_MAGNIFYING_GLASS_PLUS ++ " " ++ ifa.ICON_FA_POWER_OFF ++ " " ++ ifa.ICON_FA_MICROPHONE ++ " " ++ ifa.ICON_FA_MICROCHIP ++ " " ++ ifa.ICON_FA_VOLUME_HIGH ++ " " ++ ifa.ICON_FA_SCISSORS ++ " " ++ ifa.ICON_FA_SCREWDRIVER_WRENCH ++ " " ++ ifa.ICON_FA_BLOG);
        } // end main window

        //---------------------
        // Show another window
        //---------------------
        if (showAnotherWindow) {
            _ = ig.ImGui_Begin("Another Window", &showAnotherWindow, 0);
            defer ig.ImGui_End();
            ig.ImGui_Text("Hello from another window!");
            if (ig.ImGui_Button("Close Me")) showAnotherWindow = false;
        }

        //-----------
        // End procs
        //-----------
        // Rendering
        ig.ImGui_Render();
        impl_opengl3.glViewport(0, 0, @intFromFloat(pio.*.DisplaySize.x), @intFromFloat(pio.*.DisplaySize.y));
        impl_opengl3.glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
        impl_opengl3.glClear(impl_opengl3.GL_COLOR_BUFFER_BIT);
        impl_opengl3.cImGui_ImplOpenGL3_RenderDrawData(@ptrCast(ig.ImGui_GetDrawData()));
        _ = sdl.SDL_GL_SwapWindow(window);

        if (showWindowDelay >= 0) {
            showWindowDelay -= 1;
        }
        if (showWindowDelay == 0) { // Visible main window here at start up
            _ = sdl.SDL_ShowWindow(window);
        }
    } // while end
} // main end
