#include <stdio.h>
#include <string.h>
#include <GLFW/glfw3.h>
#include "appimgui.h"

COpts copts = {.docking = true, .viewport = false, .title_bar_icon_name = "./resources/z.png"};
int main(void) {
  Window* win = createImGui_c(1024, 900, "Dear ImGui window", &copts);
  if (win == NULL) {
    fprintf(stderr, "Failed to create Dear ImGui window\n");
    return 1;
  }

  ImVec4 clearColor = {.x = 0.25f, .y = 0.55f, .z = 0.90f, .w = 1.00f};
  char sBuf[200];
  memset(sBuf, '\0', sizeof(sBuf));

  setupFonts(NULL); // NULL: Setup default CJK fonts and Icon fonts
  setTheme_c(THEME_DARK);

  while (!shouldClose_c(win)) {
    pollEvents_c(win);

    if (isIconified_c(win)) {
      continue;
    }

    frame_c(win);
    ImGui_ShowDemoWindow(NULL);
    showInfoWindow_c(win);

    // show a simple window that we created ourselves.
    {
      static float fval = 0.0f;
      static int counter = 0;
      ImGui_Begin(ICON_FA_THUMBS_UP" " "ImGui: Dear_Bindings", NULL, 0);
      ImGui_Text(ICON_FA_COMMENT" " "GLFW v"); ImGui_SameLine();
      ImGui_Text("%s", glfwGetVersionString());
      ImGui_Text(ICON_FA_COMMENT" " "OpenGL v"); ImGui_SameLine();
      ImGui_Text("%s", (char *)glGetString(GL_VERSION));
      ImGui_InputTextWithHint("InputText","Input text here", sBuf, sizeof(sBuf), 0);
      ImGui_Text("Input result:"); ImGui_SameLine(); ImGui_Text("%s", sBuf);

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
      ImGui_End();
    }

    render_c(win);
  }

  destroyImGui_c(win);
  return 0;
}
