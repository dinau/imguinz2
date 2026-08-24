#include "imgui_toggle.h"

#ifndef CIMTOGGLE_API
#    define CIMTOGGLE_API
#endif

extern "C" {

CIMTOGGLE_API bool Toggle(const char* label, bool* v, const ImVec2 size ){
  return ImGui::Toggle(label, v, size);
}

CIMTOGGLE_API bool ToggleFlag(const char* label, bool* v, ImGuiToggleFlags flags, const ImVec2 size){
  return ImGui::Toggle(label, v, flags, size);
}

CIMTOGGLE_API bool ToggleAnim( const char* label, bool* v, ImGuiToggleFlags flags, float animation_duration, const ImVec2 size){
  return ImGui::Toggle(label, v, flags, animation_duration, size);
}

CIMTOGGLE_API bool ToggleCfg(    const char* label, bool* v, const ImGuiToggleConfig config){
  return ImGui::Toggle(label, v, config);
}

CIMTOGGLE_API bool ToggleRound(const char* label, bool* v, ImGuiToggleFlags flags, float frame_rounding, float knob_rounding, const ImVec2 size){
  return ImGui::Toggle(label, v, flags, frame_rounding, knob_rounding, size);
}

CIMTOGGLE_API bool ToggleAnimRound(const char* label, bool* v, ImGuiToggleFlags flags, float animation_duration, float frame_rounding, float knob_rounding, const ImVec2 size){
  return ImGui::Toggle(label, v, flags, animation_duration, frame_rounding, knob_rounding, size);
}

/*
IMGUI_API bool Toggle(const char* label, bool* v, const ImVec2& size = ImVec2());
IMGUI_API bool Toggle(const char* label, bool* v, ImGuiToggleFlags flags, const ImVec2& size = ImVec2());
IMGUI_API bool Toggle(const char* label, bool* v, ImGuiToggleFlags flags, float animation_duration, const ImVec2& size = ImVec2());
IMGUI_API bool Toggle(const char* label, bool* v, const ImGuiToggleConfig& config);
IMGUI_API bool Toggle(const char* label, bool* v, ImGuiToggleFlags flags, float frame_rounding, float knob_rounding, const ImVec2& size = ImVec2());
IMGUI_API bool Toggle(const char* label, bool* v, ImGuiToggleFlags flags, float animation_duration, float frame_rounding, float knob_rounding, const ImVec2& size = ImVec2());
*/


} // extern "C"
