HIDE_CONSOLE_WINDOW = true
DEBUG_INFO = false

include sdl3_opengl3.mk

ifeq ($(OS),Windows_NT)
  LDFLAGS += -lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32
  LDFLAGS += -luuid -lcomdlg32 -ladvapi32 -lsetupapi -lhid -lversion
  LDFLAGS += -lws2_32 -ldinput8 -ldxguid -ldxerr8  -lwinmm
  #	AFTER_BUILD = @cp -f $(SDL3_DIR)/bin/SDL3.dll .
endif


VPATH += ../../src/libc/cimgui

#UTILS_OBJS += .build/utils_cimgui.o

CXXFLAGS += -Wno-nullability-completeness

include makefile.common.mk
