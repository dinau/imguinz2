#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "imgui.h"
#include "setupFonts.h"
#define MAX_PATH  2048
const char* IconFontPath = "resources/fonticon/fa6/fa-solid-900.ttf";
char sBufFontPath[MAX_PATH];
char WinFontNameTbl[][MAX_PATH] = {
                                  "meiryo.ttc"     // Windows 7,8
                                 ,"YuGothM.ttc"    // Windows 10
                                 ,"segoeui.ttf"    // English standard
                                 };
char LinuxFontNameTbl[][MAX_PATH] = { // For Linux Mint 22 (Ubuntu/Debian family ok ?)
                            "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"          // JP
                           ,"/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf"               // Debian
                           ,"/usr/share/fonts/opentype/ipafont-gothic/ipam.ttf"               // Debian
                           ,"/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf" // Linux Mint English
                           };
/*-------------
 * existFile()
 * -----------*/
static bool existsFile(const char* path) {
  if (path == NULL){
    return false;
  }
  FILE* fp = fopen(path, "r");
  if (fp == NULL) return false;
  fclose(fp);
  return true;
}
/*-----------------
 * getWinFontPath()
 *----------------*/
char* getWinFontPath(char* sBuf, int bufSize, const char* fontName) {
  char* sWinDir = getenv("windir");
  if (sWinDir == NULL) return NULL;
  snprintf(sBuf, bufSize, "%s\\Fonts\\%s", sWinDir, fontName);
  return sBuf;
}
/*------------
 * point2px()
 *-----------*/
float point2px(float point) { //## Convert point to pixel
  return (point * 96) / 72;
}
ImFont* font = NULL;
/*--------------
 * setupFonts()
 * theFontPath: a null-terminated string specifying the font path.
 *              Pass NULL to fall back to the default behavior
 *              (auto-detect Windows/Linux fonts). If not NULL and
 *              the file exists, this font is used with priority.
 *-------------*/
ImFont* setupFonts(const char* theFontPath) {
  ImGuiIO& pio = ImGui::GetIO();
  ImFontConfig* config  = new ImFontConfig();
  char* fontPath;
  font = NULL;

  // Use theFontPath with priority if specified and it exists
  if (theFontPath != NULL && existsFile(theFontPath)) {
    font = pio.Fonts->AddFontFromFileTTF(theFontPath, point2px(13.0)
        , config
        , NULL);
    printf("Found FontPath(priority): [%s]\n", theFontPath);
  }

  if (font == NULL) {
    int tableLen = sizeof(WinFontNameTbl) / MAX_PATH;
    for(int i=0; i<tableLen; i++){
      fontPath = getWinFontPath(sBufFontPath, sizeof(sBufFontPath), WinFontNameTbl[i]);
      if (existsFile(fontPath)) {
        font = pio.Fonts->AddFontFromFileTTF(fontPath, point2px(13.0)
            , config
            , NULL);
        printf("Found FontPath: [%s]\n",fontPath);
        break;
      }
    }
  }

  if (font == NULL) {
    int tableLen = sizeof(LinuxFontNameTbl) / MAX_PATH;
    for(int i=0; i<tableLen; i++){
      fontPath = LinuxFontNameTbl[i];
      if (existsFile(fontPath)) {
        font = pio.Fonts->AddFontFromFileTTF(fontPath, point2px(13)
            , config
            , NULL);
        printf("Found FontPath: [%s]\n",fontPath);
        break;
      }
    }
  }

  if (font == NULL) {
    printf("Error!: Font loading falied: in %s\n", __FILE__);
    printf("Default has been set.\n");
    pio.Fonts->AddFontDefaultVector(NULL);
  }
  // Merge IconFont
  config->MergeMode = true;
  font = pio.Fonts->AddFontFromFileTTF(IconFontPath, point2px(11), config , NULL);
  if (font != NULL){
    printf("Found Icon FontPath: [%s]\n",IconFontPath);
  }
  return font;
}
