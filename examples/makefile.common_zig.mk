TARGET = $(notdir $(CURDIR))

ifeq ($(OS),Windows_NT)
	EXE = .exe
endif

all:
	@echo zig-$(shell zig version)
	zig build $(OPT)
	@-$(AFTER_BUILD_CMD)

ZIG_BIN_DIR = zig-out/bin

run: all
	(cd $(ZIG_BIN_DIR); $(LOCAL_LIB_PATH) ./$(TARGET)$(EXE))
ifneq ($(COPY_IMGUI_INI),false)
	@-cp $(ZIG_BIN_DIR)/imgui.ini .
	@-cp $(ZIG_BIN_DIR)/$(TARGET).ini .
endif
	$(AFTER_EXEC)

clean:
	@-rm -fr zig-out .zig-cache zig-pkg

cleanpdb:
ifeq ($(OS),Windows_NT)
	@-rm  zig-out/bin/$(TARGET).pdb
endif

cleancache: all
	@-rm -fr .zig-cache

cleanall: clean

fmt:
	zig fmt .
