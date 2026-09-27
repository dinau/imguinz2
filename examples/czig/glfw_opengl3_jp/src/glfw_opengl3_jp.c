#include <stdio.h>
#include <string.h>
#include <GLFW/glfw3.h>

#include "appimgui.h"
#include "setupFonts.h"
#include "loadicon.h"

COpts copts = {.docking = true, .viewport = false, .title_bar_icon_name = "./resources/z.png"};

int main(void) {
  Window* win = createImGui_c(1024, 900, "Dear ImGui window", &copts);
  if (win == NULL) {
    fprintf(stderr, "Failed to create Dear ImGui window\n");
    return 1;
  }
  bool showDemoWindow = true;
  bool showAnotherWindow = false;
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
    if (showDemoWindow) ImGui_ShowDemoWindow(&showDemoWindow);
    // show a simple window that we created ourselves.
    {
      static float fval = 0.0f;
      static int counter = 0;
      {
        ImGui_Begin(ICON_FA_THUMBS_UP" " "ImGui: Dear_Bindings", NULL, 0);
        ImGui_Text(ICON_FA_COMMENT" " "GLFW v"); ImGui_SameLine();
        ImGui_Text("%s", glfwGetVersionString());
        ImGui_Text(ICON_FA_COMMENT" " "OpenGL v"); ImGui_SameLine();
        ImGui_Text("%s", (char *)glGetString(GL_VERSION));
        ImGui_InputTextWithHint("テキスト入力", "ここへ入力", sBuf, sizeof(sBuf), 0);
        ImGui_Text("入力結果:"); ImGui_SameLine(); ImGui_Text("%s", sBuf);
        ImGui_Checkbox("デモ・ウインドウ", &showDemoWindow);
        ImGui_Checkbox("その他のウインドウ", &showAnotherWindow);

        ImGui_SliderFloatEx("浮動小数", &fval, 0.0f, 1.0f, "%.3f", 0);
        ImGui_ColorEdit3("背景色 変更", (float *)&clearColor, 0);

        if (ImGui_Button("Button")) counter++;
        ImGui_SameLine();
        ImGui_Text("カウンタ = %d", counter);
        ImGui_Text("画面更新レート %.3f ms/frame (%.1f FPS)",
            1000.0f / ImGui_GetIO()->Framerate, ImGui_GetIO()->Framerate);
        //
        ImGui_SeparatorText(ICON_FA_WRENCH" アイコン・フォント・テスト ");
        ImGui_Text(ICON_FA_TRASH_CAN  " ゴミ箱");
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
      ImGui_Begin("Another Window", &showAnotherWindow, 0);
      ImGui_Text("Hello from imgui");
      if (ImGui_Button("Close me")) {
        showAnotherWindow = false;
      }
      ImGui_End();
    }

    render_c(win);
  }
  render_c(win);
  return 0;
}
