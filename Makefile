# All example are built at a time.

EXAMPLE_DIRS_C =                                   \
							examples/glfw_opengl3                \
	            examples/glfw_opengl3_image          \
	            examples/glfw_opengl3_jp


EXAMPLE_DIRS_ZIG =                                 \
							examples/zig_glfw_opengl3            \
							examples/zig_glfw_opengl3_image_load \
							examples/zig_iconfontviewer          \
							examples/zig_imcolortextedit         \
							examples/zig_imfileopendialog        \
							examples/zig_imgui_zoomable_image    \
							examples/zig_imguizmo                \
							examples/zig_imknobs                 \
							examples/zig_imnodes                 \
							examples/zig_implot                  \
							examples/zig_implot3d                \
              examples/zig_imPlotDemo              \
							examples/zig_imspinner               \
							examples/zig_imtoggle

EXAMPLE_DIRS_ZIG_RAYLIB =                          \
							examples/zig_raylib_basic            \
							examples/zig_raylib_cjk              \
							examples/zig_rlimgui_basic

ifeq ($(OS),Windows_NT)
	 EXAMPLE_DIRS_WIN32     += examples/win32_dx11
endif

EXAMPLE_DIRS_SDL =                                 \
			        examples/zig_sdl3_opengl3            \
			        examples/zig_sdl3_sdlgpu3            \
			        examples/sdl3_opengl3

EXAMPLE_DIRS_ALL += $(EXAMPLE_DIRS_C) $(EXAMPLE_DIRS_ZIG) $(EXAMPLE_DIRS_ZIG_RAYLIB) $(EXAMPLE_DIRS_SDL) $(EXAMPLE_DIRS_WIN32)

.PHONY: test clean gen cc zig raylib sdl fmt cleanall

all: zig cc sdl win32 raylib

cc:
	$(foreach exdir,$(EXAMPLE_DIRS_C), $(call def_make,$(exdir)))

zig:
	$(foreach exdir,$(EXAMPLE_DIRS_ZIG), $(call def_make,$(exdir)))

raylib:
	$(foreach exdir,$(EXAMPLE_DIRS_ZIG_RAYLIB), $(call def_make,$(exdir)))

sdl:
	$(foreach exdir,$(EXAMPLE_DIRS_SDL), $(call def_make,$(exdir)))

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

update:
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

	@# Delete old dcimgui/
	git clean -fd -q

	@echo =====================================
	@echo OK: updated done: "$(DCIMGUI_DIR)/*"
	@echo $(ZIP_NAME_DB)
	@echo =====================================

#
define def_make
	@echo ===============================
	@echo $(1)
	@echo ===============================
	@$(MAKE) -C  $(1) $(2)

endef

copylibs:
	$(MAKE) -C src/libc $@

MAKEFLAGS += --no-print-directory
