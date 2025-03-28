.DEFAULT_GOAL=Release

# define the OF_SHARED_MAKEFILES location
OF_SHARED_MAKEFILES_PATH=$(OF_ROOT)/libs/openFrameworksCompiled/project/makefileCommon

# if APPNAME is not defined, set it to the project dir name
ifndef APPNAME
	APPNAME = $(shell basename "`pwd`")
endif

include $(OF_SHARED_MAKEFILES_PATH)/config.shared.mk

# Name TARGET
ifeq ($(findstring Debug,$(MAKECMDGOALS)),Debug)
	TARGET_NAME = Debug

	ifndef RUN_TARGET
		RUN_TARGET = RunDebug
	endif

	ifndef PLATFORM_PROJECT_DEBUG_TARGET
		TARGET = bin/$(APPNAME)_debug
	else
		TARGET = $(PLATFORM_PROJECT_DEBUG_TARGET)
	endif

	ifndef PLATFORM_PROJECT_DEBUG_BIN_NAME
		BIN_NAME = $(APPNAME)_debug
	else
		BIN_NAME = $(PLATFORM_PROJECT_DEBUG_BIN_NAME)
	endif
else ifeq ($(findstring Release,$(MAKECMDGOALS)),Release)
	TARGET_NAME = Release

	ifndef RUN_TARGET
		RUN_TARGET = RunRelease
	endif

	ifndef PLATFORM_PROJECT_RELEASE_TARGET
		TARGET = bin/$(APPNAME)
	else
		TARGET = $(PLATFORM_PROJECT_RELEASE_TARGET)
	endif

	ifndef PLATFORM_PROJECT_RELEASE_BIN_NAME
		BIN_NAME = $(APPNAME)
	else
		BIN_NAME = $(PLATFORM_PROJECT_RELEASE_BIN_NAME)
	endif

else ifeq ($(MAKECMDGOALS),run)
	TARGET_NAME = Release
	ifndef PLATFORM_PROJECT_RELEASE_TARGET
		TARGET = bin/$(APPNAME)
	else
		TARGET = $(PLATFORM_PROJECT_RELEASE_TARGET)
	endif
	ifndef PLATFORM_PROJECT_RELEASE_BIN_NAME
		BIN_NAME = $(APPNAME)
	else
		BIN_NAME = $(PLATFORM_PROJECT_RELEASE_BIN_NAME)
	endif

else ifeq ($(MAKECMDGOALS),)
	TARGET_NAME = Release

	ifndef RUN_TARGET
		RUN_TARGET = run
	endif

	ifndef PLATFORM_PROJECT_RELEASE_TARGET
		TARGET = bin/$(APPNAME)
	else
		TARGET = $(PLATFORM_PROJECT_RELEASE_TARGET)
	endif

	ifndef PLATFORM_PROJECT_RELEASE_BIN_NAME
		BIN_NAME = $(APPNAME)
	else
		BIN_NAME = $(PLATFORM_PROJECT_RELEASE_BIN_NAME)
	endif
endif

ABIS_TO_COMPILE =

ifeq ($(findstring Release,$(TARGET_NAME)),Release)
	ifdef ABIS_TO_COMPILE_RELEASE
		ABIS_TO_COMPILE += $(ABIS_TO_COMPILE_RELEASE)
	endif
endif

ifeq ($(findstring Debug,$(TARGET_NAME)),Debug)
	ifdef ABIS_TO_COMPILE_DEBUG
		ifeq ($(findstring Release,$(TARGET_NAME)),Release)
			ifdef ABIS_TO_COMPILE_RELEASE
				ABIS_TO_COMPILE = $(filter-out $(ABIS_TO_COMPILE_DEBUG),$(ABIS_TO_COMPILE_RELEASE))
			endif
		endif
		ABIS_TO_COMPILE += $(ABIS_TO_COMPILE_DEBUG)
	endif
endif

ifeq ($(MAKECMDGOALS),clean)
	TARGET = bin/$(APPNAME)_debug bin/$(APPNAME)
	TARGET_NAME = Release
endif

# we only get a CLEAN_TARGET if a TARGET_NAME has been defined
# Like TARGET, this must be defined above or in a platform file.
ifdef TARGET_NAME
	CLEANTARGET = $(addprefix Clean,$(TARGET_NAME))
endif


ifeq ($(findstring ABI,$(MAKECMDGOALS)),ABI)
	include $(OF_SHARED_MAKEFILES_PATH)/config.project.mk
	-include $(OF_PROJECT_DEPENDENCY_FILES)
endif

.PHONY: all Debug Release after clean CleanDebug CleanRelease help force

# $(info MAKEFLAGS XXX = ${MAKEFLAGS})
JOBS = -j2

Release:
	@echo Compiling OF library for Release
	@$(MAKE) $(JOBS) -C $(OF_ROOT)/libs/openFrameworksCompiled/project/ Release PLATFORM_OS=$(PLATFORM_OS) ABIS_TO_COMPILE_RELEASE="$(ABIS_TO_COMPILE_RELEASE)"
	@echo
	@echo
	@echo Compiling $(APPNAME) for Release
ifndef ABIS_TO_COMPILE_RELEASE
	@$(MAKE) $(JOBS) ReleaseABI
else
	@$(foreach abi,$(ABIS_TO_COMPILE_RELEASE),$(MAKE) $(JOBS) ReleaseABI ABI=$(abi) &&) echo
endif



Debug:
	@echo Compiling OF library for Debug
	$(MAKE) $(JOBS) -C $(OF_ROOT)/libs/openFrameworksCompiled/project/ Debug PLATFORM_OS=$(PLATFORM_OS) ABIS_TO_COMPILE_DEBUG="$(ABIS_TO_COMPILE_DEBUG)"
	@echo
	@echo
	@echo Compiling $(APPNAME) for Debug
ifndef ABIS_TO_COMPILE_DEBUG
	@$(MAKE) $(JOBS) DebugABI
else
	@$(foreach abi,$(ABIS_TO_COMPILE_DEBUG),$(MAKE) DebugABI ABI=$(abi) &&) echo
endif

ReleaseNoOF:
	@echo Compiling $(APPNAME) for Release
ifndef ABIS_TO_COMPILE_RELEASE
	@$(MAKE) $(JOBS) ReleaseABI
else
	@$(foreach abi,$(ABIS_TO_COMPILE_RELEASE),$(MAKE) ReleaseABI ABI=$(abi) &&) echo
endif

DebugNoOF:
	@echo Compiling $(APPNAME) for Debug
ifndef ABIS_TO_COMPILE_DEBUG
	@$(MAKE) $(JOBS) DebugABI
else
	@$(foreach abi,$(ABIS_TO_COMPILE_DEBUG),$(MAKE) DebugABI ABI=$(abi) &&) echo
endif

ReleaseABI: $(TARGET)
ifneq ($(strip $(PROJECT_ADDONS_DATA)),)
	@$(MAKE) $(JOBS) copyaddonsdata PROJECT_ADDONS_DATA="$(PROJECT_ADDONS_DATA)"
endif
	@$(MAKE) $(JOBS) copyaddonslibs ADDONS_SHARED_LIBS_SO="$(ADDONS_SHARED_LIBS_SO)" ADDONS_SHARED_LIBS_DLL="$(ADDONS_SHARED_LIBS_DLL)" ADDONS_SHARED_LIBS_DYLIB="$(ADDONS_SHARED_LIBS_DYLIB)"
	@$(MAKE) $(JOBS) afterplatform BIN_NAME=$(BIN_NAME) ABIS_TO_COMPILE="$(ABIS_TO_COMPILE_RELEASE)" RUN_TARGET=$(RUN_TARGET) TARGET=$(TARGET)
	@$(PROJECT_AFTER)

DebugABI: $(TARGET)
ifneq ($(strip $(PROJECT_ADDONS_DATA)),)
	@$(MAKE) $(JOBS) copyaddonsdata PROJECT_ADDONS_DATA="$(PROJECT_ADDONS_DATA)"
endif
	@$(MAKE) $(JOBS) copyaddonslibs ADDONS_SHARED_LIBS_SO="$(ADDONS_SHARED_LIBS_SO)" ADDONS_SHARED_LIBS_DLL="$(ADDONS_SHARED_LIBS_DLL)" ADDONS_SHARED_LIBS_DYLIB="$(ADDONS_SHARED_LIBS_DYLIB)"
	@$(MAKE) $(JOBS) afterplatform BIN_NAME=$(BIN_NAME) ABIS_TO_COMPILE="$(ABIS_TO_COMPILE_DEBUG)" RUN_TARGET=$(RUN_TARGET) TARGET=$(TARGET)
	@$(PROJECT_AFTER)

all:
	$(MAKE) $(JOBS) Debug

run:
ifeq ($(PLATFORM_RUN_COMMAND),)
	@cd bin;./$(BIN_NAME)
else
	@$(PLATFORM_RUN_COMMAND)
endif

RunRelease:
ifeq ($(PLATFORM_RUN_COMMAND),)
	@cd bin;./$(BIN_NAME)
else
	@$(PLATFORM_RUN_COMMAND)
endif

RunDebug:
ifeq ($(PLATFORM_RUN_COMMAND),)
	@cd bin;./$(BIN_NAME)
else
	@$(PLATFORM_RUN_COMMAND)
endif

$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags: force
	@mkdir -p $(OF_PROJECT_OBJ_OUTPUT_PATH)
	@if [ "$(strip $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) $(OPTIMIZATION_LDFLAGS) $(LDFLAGS))" != "$(strip $$(cat $@ 2>/dev/null))" ]; then echo $(strip $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) $(OPTIMIZATION_LDFLAGS) $(LDFLAGS)) > $@; fi

$(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags: force
	@mkdir -p $(OF_PROJECT_OBJ_OUTPUT_PATH)
	@mkdir -p $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)
	@if [ "$(strip $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS))" != "$(strip $$(cat $@ 2>/dev/null))" ]; then echo $(strip $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS)) > $@; fi

# Rules to compile the project sources
#$(OBJS): $(SOURCES)
$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_ROOT)/%.cpp $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_ROOT)/%.cxx $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_ROOT)/%.cc $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_ROOT)/%.m $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_ROOT)/%.mm $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_ROOT)/%.c $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_ROOT)/%.S $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS)  $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<



#Rules to create and compile resource file to include icon
$(OF_PROJECT_OBJ_OUTPUT_PATH)%.res: $(ICON)
	@echo "Compiling Resource" $<
	@mkdir -p $(@D)
#Need to build an intermediate .rc file with Windows-like file path (C:/myproject/theIcon.ico)
	@echo MAINICON ICON \"$(shell cygpath -m $<)\" > $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.rc
	@$(RESOURCE_COMPILER) $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.rc -O coff -o $@




# Rules to compile the project external sources
$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_EXTERNAL_SOURCE_PATHS)/%.cpp $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_EXTERNAL_SOURCE_PATHS)/%.cxx $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	@$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_EXTERNAL_SOURCE_PATHS)/%.cc $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_EXTERNAL_SOURCE_PATHS)/%.m $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_EXTERNAL_SOURCE_PATHS)/%.mm $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_EXTERNAL_SOURCE_PATHS)/%.c $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(PROJECT_EXTERNAL_SOURCE_PATHS)/%.S $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(PROJECT_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<




#Rules to compile the addons sources when the addon path is specified explicitly
# PROJECT_ADDONS_OBJ_PATH=$(realpath .)/$(OF_PROJECT_OBJ_OUTPUT_PATH)addons/
PROJECT_ADDONS_OBJ_PATH=./$(OF_PROJECT_OBJ_OUTPUT_PATH)addons/
$(PROJECT_ADDONS_OBJ_PATH)%.o: %.cpp $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
ifdef PROJECT_ADDON_PATHS
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(PROJECT_ADDONS_OBJ_PATH)$*.d -MT $(PROJECT_ADDONS_OBJ_PATH)$*.o -o $@ -c $<
endif

$(PROJECT_ADDONS_OBJ_PATH)%.o: %.cxx $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
ifdef PROJECT_ADDON_PATHS
	@echo "Compiling" $<
	@mkdir -p $(@D)
	@$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(PROJECT_ADDONS_OBJ_PATH)$*.d -MT $(PROJECT_ADDONS_OBJ_PATH)$*.o -o $@ -c $<
endif

$(PROJECT_ADDONS_OBJ_PATH)%.o: %.m $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
ifdef PROJECT_ADDON_PATHS
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(PROJECT_ADDONS_OBJ_PATH)$*.d -MT $(PROJECT_ADDONS_OBJ_PATH)$*.o -o $@ -c $<
endif

$(PROJECT_ADDONS_OBJ_PATH)%.o: %.mm $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
ifdef PROJECT_ADDON_PATHS
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(PROJECT_ADDONS_OBJ_PATH)$*.d -MT $(PROJECT_ADDONS_OBJ_PATH)$*.o -o $@ -c $<
endif

$(PROJECT_ADDONS_OBJ_PATH)%.o: %.cc $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
ifdef PROJECT_ADDON_PATHS
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(PROJECT_ADDONS_OBJ_PATH)$*.d -MT $(PROJECT_ADDONS_OBJ_PATH)$*.o -o $@ -c $<
endif

$(PROJECT_ADDONS_OBJ_PATH)%.o: %.c $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
ifdef PROJECT_ADDON_PATHS
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(PROJECT_ADDONS_OBJ_PATH)$*.d -MT $(PROJECT_ADDONS_OBJ_PATH)$*.o -o $@ -c $<
endif

$(PROJECT_ADDONS_OBJ_PATH)%.o: %.S $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
ifdef PROJECT_ADDON_PATHS
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(PROJECT_ADDONS_OBJ_PATH)$*.d -MT $(PROJECT_ADDONS_OBJ_PATH)$*.o -o $@ -c $<
endif






#Rules to compile the standard addons sources
$(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(OF_ADDONS_PATH)/%.cpp $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(OF_ADDONS_PATH)/%.cxx $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(OF_ADDONS_PATH)/%.cc $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(OF_ADDONS_PATH)/%.m $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(OF_ADDONS_PATH)/%.mm $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(OF_ADDONS_PATH)/%.c $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<

$(OF_ADDONS_PATH)/addons/$(OF_PROJECT_OBJ_OUTPUT_PATH)%.o: $(OF_ADDONS_PATH)/%.S $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CC) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.d -MT $(OF_ADDONS_PATH)/$(OF_PROJECT_OBJ_OUTPUT_PATH)$*.o -o $@ -c $<



# Rules to compile the addons sources from the core
$(OF_PROJECT_OBJ_OUTPUT_PATH)libs/openFrameworks/%.o: $(OF_ROOT)/libs/openFrameworks/%.cpp $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo "Compiling" $<
	@mkdir -p $(@D)
	$(CXX) -c $(OPTIMIZATION_CFLAGS) $(CFLAGS) $(CXXFLAGS) $(OF_CORE_INCLUDES_CFLAGS) $(ADDON_INCLUDE_CFLAGS) -MMD -MP -MF $(OF_PROJECT_OBJ_OUTPUT_PATH)libs/openFrameworks/$*.d -MT $(OF_PROJECT_OBJ_OUTPUT_PATH)libs/openFrameworks/$*.o -o $@ -c $<


# Rules to link the project
$(TARGET): $(OF_PROJECT_OBJS) $(OF_PROJECT_RESOURCES) $(OF_PROJECT_ADDONS_OBJS) $(OF_PROJECT_LIBS) $(TARGET_LIBS) $(OF_PROJECT_OBJ_OUTPUT_PATH).compiler_flags
	@echo '🔗 Linking $(TARGET) for $(ABI_LIB_SUBPATH)'
	@mkdir -p $(@D)
# $(LD)
	$(CXX) -o $@ $(OPTIMIZATION_LDFLAGS) $(OF_PROJECT_OBJS) $(OF_PROJECT_RESOURCES) $(OF_PROJECT_ADDONS_OBJS) $(TARGET_LIBS) $(OF_PROJECT_LIBS) $(LDFLAGS) $(OF_CORE_LIBS)

clean:
	@$(MAKE) CleanDebug
	@$(MAKE) CleanRelease

$(CLEANTARGET)ABI:
ifneq ($(OF_PROJECT_ADDONS_OBJS),)
	rm -f $(OF_PROJECT_ADDONS_OBJS)
endif
	rm -rf $(OF_PROJECT_OBJ_OUTPUT_PATH)
	rm -f $(TARGET)
	rm -rf $(BIN_NAME)

$(CLEANTARGET):
ifndef ABIS_TO_COMPILE
	@$(MAKE) $(CLEANTARGET)ABI
else
ifeq ($(TARGET_NAME),Debug)
	@$(foreach abi,$(ABIS_TO_COMPILE_DEBUG),$(MAKE) $(CLEANTARGET)ABI ABI=$(abi) &&) echo done
else
	@$(foreach abi,$(ABIS_TO_COMPILE_RELEASE),$(MAKE) $(CLEANTARGET)ABI ABI=$(abi) &&) echo done
endif
endif
	@rm -rf bin/libs

after: $(TARGET_NAME)
	-cp ${OF_LIBS_PATH}/*/lib/${PLATFORM_LIB_SUBPATH}/*.${SHARED_LIB_EXTENSION} bin/ ; true
	@echo
	@echo "     compiling done"
	@echo "     to launch the application"
	@echo
	@echo "     cd bin"
	@echo "     ./$(BIN_NAME)"
	@echo "     "
	@echo "     - or -"
	@echo "     "
	@echo "     $(MAKE) $(RUN_TARGET)"
	@echo

copyaddonsdata:
	@echo
	@echo "Copying addons data"
	@mkdir -p bin/data
	@cp -rf $(PROJECT_ADDONS_DATA) bin/data/

copyaddonslibs:
	@if [ -n "$(ADDONS_SHARED_LIBS_SO)" ]; then \
		echo "Copying shared libraries"; \
		for lib in $(ADDONS_SHARED_LIBS_SO); do \
			cp -fa $$lib bin/; \
		done \
	fi
	@if [ -n "$(ADDONS_SHARED_LIBS_DLL)" ]; then \
		echo "Copying shared libraries"; \
		for lib in $(ADDONS_SHARED_LIBS_DLL); do \
			cp -f $$lib bin/; \
		done \
	fi
	@if [ -n "$(ADDONS_SHARED_LIBS_DYLIB)" ]; then \
		echo "Copying shared libraries"; \
		for lib in $(ADDONS_SHARED_LIBS_DYLIB); do \
			cp -fa $$lib bin/; \
		done \
	fi
help:
	@echo
	@echo openFrameworks universal makefile
	@echo
	@echo "Targets:"
	@echo
	@echo "make Debug:		builds the library with debug symbols"
	@echo "make Release:		builds the library with optimizations"
	@echo "make:			= make Release"
	@echo "make all:		= make Release"
	@echo "make CleanDebug:	cleans the Debug target"
	@echo "make CleanRelease:	cleans the Release target"
	@echo "make clean:		cleans everything"
	@echo "make help:		this help message"
	@echo
	@echo
	@echo this should work with any OF app, just copy any example
	@echo change the name of the folder and it should compile
	@echo "only .cpp support, don't use .c files"
	@echo it will look for files in any folder inside the application
	@echo folder except that in the EXCLUDE_FROM_SOURCE variable.
	@echo "it doesn't autodetect include paths yet"
	@echo "add the include paths editing the var USER_CFLAGS"
	@echo at the beginning of the makefile using the gcc syntax:
	@echo -Ipath
	@echo
	@echo to add addons to your application, edit the addons.make file
	@echo in this directory and add the names of the addons you want to
	@echo include
	@echo


#legacy targets
AndroidRelease:
	$(MAKE) Release PLATFORM_OS=Android

AndroidDebug:
	$(MAKE) Debug PLATFORM_OS=Android

CleanAndroid:
	$(MAKE) clean PLATFORM_OS=Android
