//impl_dcimgui.zig:743:14: error: indexable pointer to opaque type 'impl_dcimgui.struct_ImGuiContext_t' not allowed
//    Ctx: [*c]ImGuiContext,
//             ^~~~~~~~~~~~
//impl_dcimgui.zig:2241:35: note: opaque declared here
//pub const struct_ImGuiContext_t = opaque {
//                                  ^~~~~~

#include "dcimgui.h"
struct ImGuiContext_t { int _dummy; };



#define ImGuiContext_t ImGuiContext_t_real
#define ImGuiContext ImGuiContext_real
#include "dcimgui_internal.h"
#undef ImGuiContext
#undef ImGuiContext_t
