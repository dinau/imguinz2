#pragma once

#ifdef __cplusplus
extern "C" {
#endif

ImFont* setupFonts(const char* theFontPath);
float point2px(float point); //## Convert point to pixel

#ifdef __cplusplus
}
#endif
