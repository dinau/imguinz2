#include <stdio.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL_opengl.h>
#include <SDL3/SDL_mouse.h>

#include "dcimgui.h"
#include "dcimgui_impl_sdl3.h"
#include "dcimgui_impl_opengl3.h"


#include "setupFonts.h"


const int MainWinWidth = 1024;
const int MainWinHeight = 800;

// Main code
int main(int argc, char *argv[]) {
  (void)argc; (void) argv;
  // Setup SDL
  if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD)) {
    printf("Error: SDL_Init(): %s\n", SDL_GetError());
    return -1;
  }

  const char* glsl_version = "#version 130";
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);

  //SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");

  // Create window with graphics context
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
  SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
  SDL_WindowFlags window_flags = (SDL_WindowFlags)(SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN);
  SDL_Window* window = SDL_CreateWindow("Dear ImGui SDL3+OpenGL3 example", MainWinWidth, MainWinHeight, window_flags);
  if (window == NULL) {
    printf("Error: SDL_CreateWindow(): %s\n", SDL_GetError());
    return -1;
  }

  SDL_SetWindowPosition(window, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);
  SDL_GLContext gl_context = SDL_GL_CreateContext(window);
  SDL_GL_MakeCurrent(window, gl_context);
  SDL_GL_SetSwapInterval(1);  // Enable vsync

  // Setup Dear ImGui context
  // IMGUI_CHECKVERSION();
  ImGui_CreateContext(NULL);
  ImGuiIO* io = ImGui_GetIO(); (void)io;
  io->ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
  io->ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

  // Setup Dear ImGui style
  // ImGui_StyleColorsDark(NULL);
  // ImGui_StyleColorsLight(NULL);
  ImGui_StyleColorsClassic(NULL);

  // Setup Platform/Renderer backends
  cImGui_ImplSDL3_InitForOpenGL(window, gl_context);
  cImGui_ImplOpenGL3_InitEx(glsl_version);

  // Our state
  bool showDemoWindow = true;
  bool showAnotherWindow = false;
  ImVec4 clearColor = {.x = 0.45f, .y = 0.55f, .z = 0.60f, .w = 1.00f};
  char sBuf[200];
  for (int i = 0; i<sizeof(sBuf); i++) {
    sBuf[i] = '\0';
  }

  setupFonts(NULL); // NULL: Setup default CJK fonts and Icon fonts

  int showWindowDelay = 2;

  // Main loop
  bool done = false;
  while (!done) {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      cImGui_ImplSDL3_ProcessEvent(&event);
      if (event.type == SDL_EVENT_QUIT)
        done = true;
      if (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED && event.window.windowID == SDL_GetWindowID(window))
        done = true;
    }

    // Start the Dear ImGui frame
    cImGui_ImplOpenGL3_NewFrame();
    cImGui_ImplSDL3_NewFrame();
    ImGui_NewFrame();

    if (showDemoWindow) {
      ImGui_ShowDemoWindow(&showDemoWindow);
    }
    //
    // show a simple window that we created ourselves.
    {
      static float fval = 0.0f;
      static int counter = 0;
      {
        ImGui_Begin(ICON_FA_THUMBS_UP" " "ImGui: Dear_Bindings", NULL, 0);
          ImGui_Text(ICON_FA_COMMENT" " "SDL3 v"); ImGui_SameLine();
          ImGui_Text("[%d],[%s]", SDL_GetVersion(),SDL_GetRevision());
          //
          ImGui_Text(ICON_FA_COMMENT" " "OpenGL v"); ImGui_SameLine();
          ImGui_Text("%s", (char *)glGetString(GL_VERSION));
          ImGui_InputTextWithHint("InputText","Input text here",sBuf,sizeof(sBuf),0);
          ImGui_Text("Input result:"); ImGui_SameLine(); ImGui_Text("%s", sBuf);
          ImGui_Checkbox("Demo window", &showDemoWindow);
          ImGui_Checkbox("Another window", &showAnotherWindow);

          ImGui_SliderFloatEx("Float", &fval, 0.0f, 1.0f, "%.3f", 0);
          ImGui_ColorEdit3("Background color", (float *)&clearColor, 0);

          if (ImGui_Button("Button")) counter++;
          ImGui_SameLine();
          ImGui_Text("counter = %d", counter);
          ImGui_Text("Application average %.3f ms/frame (%.1f FPS)",
              1000.0f / ImGui_GetIO()->Framerate, ImGui_GetIO()->Framerate);
          //
          ImGui_SeparatorText(ICON_FA_WRENCH" Icon font test ");
          ImGui_Text(ICON_FA_TRASH_CAN  " Trash");
          ImGui_Text(ICON_FA_MAGNIFYING_GLASS_PLUS
              " " ICON_FA_POWER_OFF
              " " ICON_FA_MICROPHONE
              " " ICON_FA_MICROCHIP
              " " ICON_FA_VOLUME_HIGH
              " " ICON_FA_SCISSORS
              " " ICON_FA_SCREWDRIVER_WRENCH
              " " ICON_FA_BLOG);
      }
      ImGui_End();
    }

    if (showAnotherWindow) {
      ImGui_Begin("Another Window", &showAnotherWindow, 0);   // Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
        ImGui_Text("Hello from another window!");
        if (ImGui_Button("Close Me"))
          showAnotherWindow = false;
      ImGui_End();
    }
    // Rendering
    ImGui_Render();
    glViewport(0, 0, (int)io->DisplaySize.x, (int)io->DisplaySize.y);
    glClearColor(clearColor.x * clearColor.w, clearColor.y * clearColor.w, clearColor.z * clearColor.w, clearColor.w);
    glClear(GL_COLOR_BUFFER_BIT);
    cImGui_ImplOpenGL3_RenderDrawData(ImGui_GetDrawData());
    SDL_GL_SwapWindow(window);


    if(showWindowDelay >= 0) showWindowDelay -= 1;
    if(showWindowDelay == 0) SDL_ShowWindow(window); // Visible main window here at start up
                                                     //
  } // while end

  // Cleanup
  cImGui_ImplOpenGL3_Shutdown();
  cImGui_ImplSDL3_Shutdown();
  ImGui_DestroyContext(NULL);

  SDL_GL_DeleteContext(gl_context);
  SDL_DestroyWindow(window);
  SDL_Quit();

  return 0;
}
