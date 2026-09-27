#include <stdio.h>
#include <GLFW/glfw3.h>
#include "appimgui.h"
#include "loadImage.h"
#include "saveImage.h"

// Constants
const char* SaveImageName = "ImageSaved";

// Global vars
GLFWwindow *window;
int cbItemIndex = 0;

typedef struct {
  char* kind;
  char* ext;
} TImageFormat;

TImageFormat imageFormatTbl[] = {  {.kind = "JPEG 90%", .ext = ".jpg"}
                                 , {.kind = "PNG",      .ext = ".png"}
                                 , {.kind = "BMP",      .ext = ".bmp"}
                                 , {.kind = "TGA",      .ext = ".tga"}};
/*--------------
 * setTooltip()
 *-------------*/
void setTooltip(const char* str) {
  if (ImGui_IsItemHovered(ImGuiHoveredFlags_DelayNormal)) {
    if (ImGui_BeginTooltip()) {
      ImGui_Text("%s", str);
      ImGui_EndTooltip();
    }
  }
}

COpts copts = {.docking = true, .viewport = false, .title_bar_icon_name = "./resources/z.png"};

/*------
 * main
 *-----*/
int main(void) {
  Window* win = createImGui_c(1024, 900, "Dear ImGui window", &copts);
  if (win == NULL) {
    fprintf(stderr, "Failed to create Dear ImGui window\n");
    return 1;
  }

  /*------------
   * Load image
   *-----------*/
  const char* ImageName = "./resources/fuji-400.jpg";
  GLuint textureId;
  int textureWidth = 0;
  int textureHeight = 0;
  LoadTextureFromFile(ImageName, &textureId, &textureWidth, &textureHeight);

  setupFonts(NULL); // NULL: Setup default CJK fonts and Icon fonts
  setTheme_c(THEME_DARK);

  while (!shouldClose_c(win)) {
    pollEvents_c(win);
    if (isIconified_c(win)) {
      continue;
    }
    frame_c(win);

    showInfoWindow_c(win);
    ImGui_ShowDemoWindow(NULL);

      static int counter = 0;
      char svName[1024];
      char sTooltipBuf[1024 * 2];
    //# Show image save window
    {
      ImGui_Begin("Image save test", NULL, 0);
      // Save button for capturing window image
      ImGui_PushIDInt(0);
      ImVec4 col1 = {.x = 0.7, .y = 0.7, .z = 0.0, .w = 1.0};
      ImGui_PushStyleColorImVec4(ImGuiCol_Button, col1);
      ImVec4 col2 = {.x = 0.8, .y = 0.8, .z = 0.0, .w = 1.0};
      ImGui_PushStyleColorImVec4(ImGuiCol_ButtonHovered, col2);
      ImVec4 col3 = {.x = 0.9, .y = 0.9, .z = 0.0, .w = 1.0};
      ImGui_PushStyleColorImVec4(ImGuiCol_ButtonActive, col3);
      ImVec4 col4 = {.x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0};
      ImGui_PushStyleColorImVec4(ImGuiCol_Text, col4);

      // Image save button
      char* imageExt = imageFormatTbl[cbItemIndex].ext;
      snprintf(svName, sizeof(svName), "%s_%05d%s", SaveImageName, counter, imageExt);
      if (ImGui_Button("Save Image")) {
        ImVec2 wkSize = ImGui_GetMainViewport()->WorkSize;
        saveImage(svName, 0, 0, wkSize.x, wkSize.y, 3, 90);    // # --- Save Image !
      }
      ImGui_PopStyleColorEx(4);
      ImGui_PopID();
      // Show tooltip help
      snprintf(sTooltipBuf, sizeof(sTooltipBuf), "Save to \"%s\"", svName);
      setTooltip(sTooltipBuf);
      counter++;

      ImGui_SameLine();
      // ComboBox: Select save image format
      ImGui_SetNextItemWidth(100);
      if (ImGui_BeginCombo("##", imageFormatTbl[cbItemIndex].kind, 0)) {
        for (int n = 0; n < sizeof(imageFormatTbl)/sizeof(TImageFormat); n++) {
          bool is_selected = (cbItemIndex == n);
          if (ImGui_SelectableBoolPtr(imageFormatTbl[n].kind, &is_selected, 0)) {
            if (is_selected) {
              ImGui_SetItemDefaultFocus();
            }
            cbItemIndex = n;
          }
        }
        ImGui_EndCombo();
      }
      setTooltip("Select image format");
      //
      ImGui_End();
    }

    // Show image load window
    {
      ImGui_Begin("Image load test", NULL, 0);
        // Load image
        ImVec2 size = {.x = (float)textureWidth, .y = (float)textureHeight};
        ImGui_SetNextWindowSize(size, ImGuiCond_Always);
        ImGui_ImageEx((ImTextureRef){._TexData = NULL, ._TexID = textureId} ,size ,(ImVec2){.x = 0, .y = 0} ,(ImVec2){.x = 1, .y = 1});
      ImGui_End();
    }

    render_c(win);
  }
  destroyImGui_c(win);
  return 0;
}
