# Add backend driver in imgui
BACKEND_SRCS_CPP += dcimgui_impl_opengl3.cpp
BACKEND_SRCS_CPP += dcimgui_impl_sdl3.cpp
BACKEND_SRCS_CPP += imgui_impl_opengl3.cpp
BACKEND_SRCS_CPP += imgui_impl_sdl3.cpp

#
CFLAGS += -DCIMGUI_USE_SDL3
CFLAGS += -DCIMGUI_USE_OPENGL3
CFLAGS += -DSDL_ENABLE_OLD_NAMES
LIBS   += -L.

# SDL3 library settings
ifeq ($(OS),Windows_NT)
  SDL3_DIR = ../../src/libc/sdl/SDL3/x86_64-w64-mingw32
  CFLAGS += -I$(SDL3_DIR)/include -I$(SDL3_DIR)/include/SDL3
  LIBS   += -L$(SDL3_DIR)/lib
	ifeq ($(STATIC_SDL3),true)
		LIBS += -lSDL3
	else
		LIBS += -lSDL3.dll
	endif
else
	CFLAGS += $(shell pkg-config --cflags sdl3)
	LIBS += -lSDL3
endif
