# All example are built at a time.
EXAMPLE_DIRS =                                     \
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
	 EXAMPLE_DIRS     += examples/win32_dx11
endif

EXAMPLE_DIRS_SDL =                                 \
			        examples/zig_sdl3_opengl3            \
			        examples/zig_sdl3_sdlgpu3            \
			        examples/sdl3_opengl3

.PHONY: test clean gen cc zig zig_raylib sdl fmt cleanall

all: zig cc sdl zig_raylib

cc:
	$(foreach exdir,$(EXAMPLE_DIRS), $(call def_make,$(exdir)))

zig:
	$(foreach exdir,$(EXAMPLE_DIRS_ZIG), $(call def_make,$(exdir)))

zig_raylib:
	$(foreach exdir,$(EXAMPLE_DIRS_ZIG_RAYLIB), $(call def_make,$(exdir)))

sdl:
	$(foreach exdir,$(EXAMPLE_DIRS_SDL), $(call def_make,$(exdir)))

fmt:
	$(foreach exdir,$(EXAMPLE_DIRS), $(call def_make,$(exdir),$@ ))

test:
	@echo $(notdir $(EXAMPLE_DIRS))

clean: cleanall
	@-rm -fr .zig-cache

cleanall:
	@-$(foreach exdir,$(EXAMPLE_DIRS), $(call def_make,$(exdir),$@ ))
	@-$(foreach exdir,$(EXAMPLE_DIRS_ZIG), $(call def_make,$(exdir),$@ ))
	@-$(foreach exdir,$(EXAMPLE_DIRS_ZIG_RAYLIB), $(call def_make,$(exdir),$@ ))
	@-$(MAKE) -C src/libzig clean

WORK_DIR           = ../imguinz2_work
DB_DIR             = $(WORK_DIR)/dear_bindings
DCIMGUI_DIR        = src/libc/dcimgui
IMGUI_DIR          = src/libc/imgui
IMGUI_EXTERNAL_DIR = ../000imguin_dev/imguin_git/libs/cimgui/imgui
DB_VER             = 0.21
IMGUI_VER          = 1.92.8
ZIP_NAME           = DearBindings_v$(DB_VER)_ImGui_v$(IMGUI_VER)-docking

update:
	-mkdir -p $(IMGUI_DIR)
	@# Copy new ImGui sources
	cp -fr $(IMGUI_EXTERNAL_DIR)/* $(IMGUI_DIR)/
	@# Download load generated Dear bindings sources
	curl -L https://github.com/dearimgui/dear_bindings/releases/download/$(ZIP_NAME)/$(ZIP_NAME).zip --output-dir $(WORK_DIR) -O
	@# Delete dcimgui/
	-rm -fr src/dcimgui/{*,backends/*}
	@# Unzip
	unzip -o $(WORK_DIR)/$(ZIP_NAME) -d $(DCIMGUI_DIR)
	@echo =====================================
	@echo OK: updated done: "$(DCIMGUI_DIR)/*"
	@echo $(ZIP_NAME)
	@echo =====================================

#
define def_make
	@echo ===============================
	@echo $(1)
	@echo ===============================
	@$(MAKE) -C  $(1) $(2)

endef


MAKEFLAGS += --no-print-directory
