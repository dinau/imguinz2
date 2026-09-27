# All example are built at a time.

EXAMPLE_DIRS_C =                                     \
							examples/czig/glfw_opengl3             \
	            examples/czig/glfw_opengl3_image       \
	            examples/czig/glfw_opengl3_jp


EXAMPLE_DIRS_ZIG =                                   \
							examples/zig/glfw_iconfontviewer       \
							examples/zig/glfw_imcolortextedit      \
							examples/zig/glfw_imfileopendialog     \
							examples/zig/glfw_imgui_zoomable_image \
							examples/zig/glfw_imguizmo             \
							examples/zig/glfw_imknobs              \
							examples/zig/glfw_imnodes              \
							examples/zig/glfw_implot               \
							examples/zig/glfw_implot3d             \
							examples/zig/glfw_imspinner            \
							examples/zig/glfw_imtoggle             \
							examples/zig/glfw_opengl3              \
							examples/zig/glfw_opengl3_image_load   \
              examples/zig/glfw_imPlotDemo
EXAMPLE_DIRS_WASM =                                  \
							examples/wasm/zig_webgl                \
							examples/wasm/zig_wgpu

EXAMPLE_DIRS_ZIG_RAYLIB =                            \
							examples/raylib/raylib_basic           \
							examples/raylib/raylib_cjk             \
							examples/raylib/rlimgui_basic

ifeq ($(OS),Windows_NT)
	 EXAMPLE_DIRS_WIN32     += examples/czig/win32_dx11
endif

EXAMPLE_DIRS_SDL =                                   \
			        examples/sdl3/sdl3_opengl3             \
			        examples/sdl3/sdl3_sdlgpu3             \
			        examples/czig/sdl3_opengl3


EXAMPLE_DIRS_ALL += $(EXAMPLE_DIRS_C)          \
										$(EXAMPLE_DIRS_ZIG)        \
									 	$(EXAMPLE_DIRS_ZIG_RAYLIB) \
									 	$(EXAMPLE_DIRS_SDL)        \
									 	$(EXAMPLE_DIRS_WASM)       \
									 	$(EXAMPLE_DIRS_WIN32)

.PHONY: test clean gen cc zig raylib sdl fmt win32 cleanall update copylibs cjk

all: zig cc sdl wasm win32 # raylib

cc:
	$(foreach exdir,$(EXAMPLE_DIRS_C), $(call def_make,$(exdir)))

zig:
	$(foreach exdir,$(EXAMPLE_DIRS_ZIG), $(call def_make,$(exdir)))

raylib:
	$(foreach exdir,$(EXAMPLE_DIRS_ZIG_RAYLIB), $(call def_make,$(exdir)))

sdl:
	$(foreach exdir,$(EXAMPLE_DIRS_SDL), $(call def_make,$(exdir)))
wasm:
	$(foreach exdir,$(EXAMPLE_DIRS_WASM), $(call def_make,$(exdir)))

win32:
	$(foreach exdir,$(EXAMPLE_DIRS_WIN32), $(call def_make,$(exdir)))

fmt:
	$(foreach exdir,$(EXAMPLE_DIRS_ALL), $(call def_make,$(exdir),$@ ))

clean: cleanall
	@-rm -fr .zig-cache

cleanall:
	@-$(foreach exdir,$(EXAMPLE_DIRS_ALL), $(call def_make,$(exdir),$@ ))
	@-$(MAKE) -C src/libzig clean

DB_VER             = 0.21
IMGUI_VER          = 1.92.9b
WORK_DIR           = 00work
IMGUI_EXT_DIR      = $(WORK_DIR)/imgui
DB_DIR             = $(WORK_DIR)/dear_bindings
DCIMGUI_DIR        = src/libc/dcimgui
IMGUI_DIR          = src/libc/imgui
LIBC_DIR           = src/libc
ZIP_NAME_DB        = DearBindings_v$(DB_VER)_ImGui_v$(IMGUI_VER)-docking
ZIP_NAME_IMGUI     = v$(IMGUI_VER)-docking

update: # Update Dear ImGui and Dear Bingings
	@-mkdir -p $(WORK_DIR)
	@-mkdir -p $(IMGUI_DIR)
	@# Download load Dear ImGui sources
	curl -L https://github.com/ocornut/imgui/archive/refs/tags/$(ZIP_NAME_IMGUI).zip --output-dir $(WORK_DIR) -O
	@-rm -fr   $(IMGUI_DIR)
	unzip -o -q $(WORK_DIR)/$(ZIP_NAME_IMGUI) -d $(LIBC_DIR)
	mv  -f $(LIBC_DIR)/imgui-$(IMGUI_VER)-docking  $(LIBC_DIR)/imgui

	@# Download load generated Dear bindings sources
	curl -L https://github.com/dearimgui/dear_bindings/releases/download/$(ZIP_NAME_DB)/$(ZIP_NAME_DB).zip --output-dir $(WORK_DIR) -O
	@# Unzip
	unzip -o -q $(WORK_DIR)/$(ZIP_NAME_DB) -d $(DCIMGUI_DIR)

	@# Delete none needed files
	#git clean -fd -q

	@echo =====================================
	@echo OK: updated done: "$(DCIMGUI_DIR)/*"
	@echo $(ZIP_NAME_DB)
	@echo =====================================

#
CALL_COUNT := 0
define def_make
$(eval CALL_COUNT := $(shell expr $(CALL_COUNT) + 1))
	@echo [$(CALL_COUNT)]: $(1)
	@$(MAKE) -C  $(1) $(2)
	@#-$(MAKE) -C  $(1) cleanpdb
	@echo

endef

copylibs:
	$(MAKE) -C src/libc $@

MAKEFLAGS += --no-print-directory


cjk:
	rg -l '[\u3000-\u303f\u3040-\u309f\u30a0-\u30ff\u4e00-\u9fff\uff00-\uffef]' -g '*.{zig,nim,c,h,cpp}'
