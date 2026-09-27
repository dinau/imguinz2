TARGET = $(notdir $(CURDIR))

ifeq ($(V),)
  D = @
endif

# Link selection: true or false
#STATIC_CIMGUI = true

ifeq ($(OS),Windows_NT)
	CFLAGS += -static
	EXE = .exe
endif

# Eliminale warinings
CFLAGS_EXTRA += -Wno-pointer-sign
#CFLAGS += -W-no-


# TC : gcc or clang or zig
#TC ?= gcc
TC ?= zigcc

ifeq ($(TC),gcc)
	CC  = $(CCACHE) gcc
	CXX = $(CCACHE) g++
	CXXFLAGS += -Wno-stringop-overflow
endif
ifeq ($(TC),clang)
	CC =  clang
	CXX = clang++
endif
ifeq ($(TC),clangcl)
	CC =  clang-cl
	CXX = clang-cl
endif
ifeq ($(TC),zigcc)
	CC =  zig cc
	CXX = zig c++
	AR  = zig ar
	ifeq ($(HIDE_CONSOLE_WINDOW),true)
		CFLAGS += -Wl,--subsystem,windows
	endif
endif

LIBS_DIR           = ../../../src/libc
IMGUI_DIR          = $(LIBS_DIR)/imgui
STB_DIR            = $(LIBS_DIR)/stb
#
DCIMGUI_DIR        = $(LIBS_DIR)/dcimgui
DCIMGUI_BUILD_DIR  = $(DCIMGUI_DIR)/.build
#
CIMGUI_DIR         = $(LIBS_DIR)/cimgui
#
UTILS_DIR          = ./utils
RESOURCES_DIR      = ./resources
FONT_HEADER_DIR    = $(RESOURCES_DIR)/fonticon
#
BUILD_DIR          = .build
#
DCIMGUI_ARCHIVE_DIR = $(LIBS_DIR)
LIB_CIMGUI_ARCHIVE = $(DCIMGUI_ARCHIVE_DIR)/libcimgui.a

#
VPATH += .:$(DCIMGUI_DIR):$(DCIMGUI_DIR)/backends:$(IMGUI_DIR):$(IMGUI_DIR)/backends:$(UTILS_DIR):src

# CImGui / ImGui sources
DCIMGUI_SRCS_CPP += $(notdir $(wildcard $(DCIMGUI_DIR)/*.cpp))
DCIMGUI_SRCS_CPP += $(notdir $(BACKEND_SRCS_CPP))
IMGUI_SRCS_CPP  += $(notdir $(wildcard $(IMGUI_DIR)/*.cpp))
CIMGUI_SRCS_CPP  += $(notdir $(wildcard $(CIMGUI_DIR)/*.cpp))

# My sources
MAIN_SRCS_C   += $(notdir $(wildcard src/*.c))

# Utils sources
UTILS_SRCS_CPP += $(notdir $(wildcard $(UTILS_DIR)/*.cpp))
UTILS_SRCS_C   += $(notdir $(wildcard $(UTILS_DIR)/*.c))

DCIMGUI_OBJS += $(addprefix $(DCIMGUI_BUILD_DIR)/,$(DCIMGUI_SRCS_CPP:.cpp=.o) $(IMGUI_SRCS_CPP:.cpp=.o)) $(CIMGUI_SRCS_CPP:.cpp=.o)
UTILS_OBJS   += $(addprefix $(BUILD_DIR)/,$(UTILS_SRCS_C:.c=.o) $(UTILS_SRCS_CPP:.cpp=.o))
MAIN_OBJS    += $(addprefix $(BUILD_DIR)/,$(MAIN_SRCS_C:.c=.o))

#
CFLAGS += -MMD -MP
ifeq ($(STATIC_CIMGUI),true)
#CFLAGS += -static
else
#CFLAGS += -shared
endif
#
CFLAGS += -Wall -Wno-unused-function
#CFLAGS +=  -Wextra
CFLAGS += -O2
ifeq ($(CC),gcc)
CFLAGS +=  -Wl,-s
CFLAGS += -ffunction-sections -fdata-sections -Wl,--gc-sections
else
STRIP = strip $(TARGET)$(EXE)
endif
# Includes INCS
CFLAGS += -I$(DCIMGUI_DIR) -I$(DCIMGUI_DIR)/backends -I$(IMGUI_DIR) -I. -I$(IMGUI_DIR)/backends
CFLAGS += -I$(UTILS_DIR)  -I$(FONT_HEADER_DIR)
CFLAGS += -I$(STB_DIR)

# CImGui flags
#CFLAGS += -DCIMGUI_IMPL_API="extern \"C\""
CFLAGS += -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS
# ImGui flags
CFLAGS += -DImDrawIdx="unsigned int"
CFLAGS += -DIMGUI_ENABLE_WIN32_DEFAULT_IME_FUNCTIONS

# LIBS
ifeq ($(OS),Windows_NT)
LIBS += -lgdi32 -limm32 -lopengl32
else
LIBS += -L/usr/lib/x86_64-linux-gnu -lGL -lX11 -lglfw
endif

DEPS_IMGUI  = $(wildcard $(IMGUI_DIR)/*.h)
DEPS_CIMGUI = $(DCIMGUI_DIR)/dcimgui.h
DEPS_OTHER  = $(wildcard *.h) $(wildcard $(UTILS_DIR)/*.h)
DEPS_PROJ   = $(wildcard *.h)

# Hide console winodw
ifeq ($(HIDE_CONSOLE_WINDOW),true)
	ifeq ($(OS),Windows_NT)
		LDFLAGS += -mwindows
	endif
endif

CXXFLAGS += -DCIMGUI_API="extern \"C\""
CXXFLAGS += $(CFLAGS)
CXXFLAGS += -fno-exceptions -fno-rtti -std=c++11
LDFLAGS += -L$(DCIMGUI_ARCHIVE_DIR)

# Strip debug info
ifneq (($DEBUG_INFO),true)
	LDFLAGS += -s
endif

MAKE_DIRS = $(BUILD_DIR)        \
 	          $(DCIMGUI_BUILD_DIR)

all: $(MAKE_DIRS) $(LIB_CIMGUI_ARCHIVE) $(TARGET)$(EXE) afterbuild

lib: $(LIB_CIMGUI_ARCHIVE)
afterbuild:
	-$(AFTER_BUILD)

MAKE_DEPS += makefile.common.mk Makefile sdl3_opengl3.mk
$(TARGET)$(EXE): $(UTILS_OBJS) $(MAIN_OBJS) $(MAKE_DEPS)
	@echo [$(CXX)]: - Link - $@
	$(D)$(CXX) $(CXXFLAGS) -o $@  $(UTILS_OBJS) $(MAIN_OBJS) -lcimgui $(LIBS) $(LDFLAGS)

$(LIB_CIMGUI_ARCHIVE): $(DCIMGUI_OBJS)
	@echo [ $(AR) ]: $@
	$(D)$(AR) -rc $@ $^

$(DCIMGUI_BUILD_DIR)/%.o: %.cpp $(DEPS_IMGUI) $(MAKE_DEPS)
	@echo [$(CXX)]: $(notdir $<)
	$(D)$(CXX) -c -o $@ $(CXXFLAGS) $<

$(DCIMGUI_BUILD_DIR)/%.o: %.c $(DEPS_CIMGUI) $(MAKE_DEPS)
	@echo [$(CC)]: $(notdir $<)
	$(D)$(CC) -c -o $@ $(CFLAGS) $(CFLAGS_EXTRA) $<

$(BUILD_DIR)/%.o: %.cpp $(DEPS_PROJ) $(MAKE_DEPS)
	@echo [$(CXX)]: $(notdir $<)
	$(D)$(CXX) -c -o $@ $(CXXFLAGS) $<

$(BUILD_DIR)/%.o: %.c $(DEPS_PROJ) $(MAKE_DEPS)
	@echo [$(CC)]: $(notdir $<)
	$(D)$(CC) -c -o $@ $(CFLAGS) $(CFLAGS_EXTRA) $<

.PHONY: run gen clean cleanall cleanobjs  cleanother cleancache $(BUILD_DIR)

$(BUILD_DIR):
	@-mkdir -p  $@

$(DCIMGUI_BUILD_DIR):
	@-mkdir -p $@

$(UTILS_OBJ_DIR):
	@ -mkdir -p $@

run: all
	./$(TARGET)

clean:
	@-rm $(TARGET)$(EXE)
	@-rm $(MAIN_OBJS)
	@-rm -fr $(BUILD_DIR)
	@-rm -fr .zig-cache
cleanother:
	@-rm -fr $(UTILS_OBJ_DIR)
cleanobjs: clean cleanother
	@-rm $(LIB_CIMGUI_ARCHIVE)
	@-rm -fr $(DCIMGUI_BUILD_DIR)
cleanall: cleanobjs
	@-rm -fr $(BUILD_DIR)
	@-rm -fr $(DCIMGUI_BUILD_DIR)
cleancache: all
	@-rm -fr .zig-cache

fmt:
	zig fmt .

include $(wildcard $(BUILD_DIR)/*.d)
