# (C)2004-2010 SourceMod Development Team
# Makefile written by David "BAILOPAN" Anderson

ENVDIR= ../../forbuild
SRCDS_BASE = ../../srcds
SDKDIR= $(ENVDIR)/hl2sdks

MMSOURCE18 = $(ENVDIR)/metamod
SMSDK = $(ENVDIR)/sourcemod

HL2SDK_ORIG = $(SDKDIR)/hl2sdk
HL2SDK_OB = $(SDKDIR)/hl2sdk-ob
HL2SDK_OB_VALVE = $(SDKDIR)/hl2sdk-ob-valve
HL2SDK_L4D = $(SDKDIR)/hl2sdk-l4d
HL2SDK_L4D2 = $(SDKDIR)/hl2sdk-l4d2

#####################################
### EDIT BELOW FOR OTHER PROJECTS ###
#####################################

PROJECT = plugincvars

#Uncomment for Metamod: Source enabled extension
USEMETA = true

OBJECTS = sdk/smsdk_ext.cpp extension.cpp

##############################################
### CONFIGURE ANY OTHER FLAGS/OPTIONS HERE ###
##############################################
PACKAGEDIR = package
C_OPT_FLAGS = -DNDEBUG -O3 -funroll-loops -pipe -fno-strict-aliasing
C_DEBUG_FLAGS = -D_DEBUG -DDEBUG -g -ggdb3
C_GCC4_FLAGS = -fvisibility=hidden
CPP_GCC4_FLAGS = -fvisibility-inlines-hidden
CPP = gcc

override ENGSET = false
ifeq "$(ENGINE)" "original"
	HL2SDK = $(HL2SDK_ORIG)
	HL2PUB = $(HL2SDK)/public
	HL2LIB = $(HL2SDK)/linux_sdk
	CFLAGS += -DSOURCE_ENGINE=1
	METAMOD = $(MMSOURCE18)/core-legacy
	INCLUDE += -I$(HL2SDK)/public/dlls
	SRCDS = $(SRCDS_BASE)
	LIB_SUFFIX = _i486.so
	override ENGSET = true
endif
ifeq "$(ENGINE)" "orangebox"
	HL2SDK = $(HL2SDK_OB)
	HL2PUB = $(HL2SDK)/public
	HL2LIB = $(HL2SDK)/lib/linux
	CFLAGS += -DSOURCE_ENGINE=3
	METAMOD = $(MMSOURCE18)/core
	INCLUDE += -I$(HL2SDK)/public/game/server
	SRCDS = $(SRCDS_BASE)/orangebox
	LIB_SUFFIX = _i486.so
	override ENGSET = true
endif
ifeq "$(ENGINE)" "orangeboxvalve"
	HL2SDK = $(HL2SDK_OB_VALVE)
	HL2PUB = $(HL2SDK)/public
	HL2LIB = $(HL2SDK)/lib/linux
	CFLAGS += -DSOURCE_ENGINE=4
	METAMOD = $(MMSOURCE18)/core
	INCLUDE += -I$(HL2SDK)/public/game/server
	SRCDS = $(SRCDS_BASE)/orangebox
	LIB_PREFIX = lib
	LIB_SUFFIX = .so
	override ENGSET = true
endif
ifeq "$(ENGINE)" "left4dead"
	HL2SDK = $(HL2SDK_L4D)
	HL2PUB = $(HL2SDK)/public
	HL2LIB = $(HL2SDK)/lib/linux
	CFLAGS += -DSOURCE_ENGINE=5
	METAMOD = $(MMSOURCE18)/core
	INCLUDE += -I$(HL2SDK)/public/game/server
	SRCDS = $(SRCDS_BASE)/l4d
	LIB_SUFFIX = _i486.so
	override ENGSET = true
endif
ifeq "$(ENGINE)" "left4dead2"
	HL2SDK = $(HL2SDK_L4D2)
	HL2PUB = $(HL2SDK)/public
	HL2LIB = $(HL2SDK)/lib/linux
	CFLAGS += -DSOURCE_ENGINE=6
	METAMOD = $(MMSOURCE18)/core
	INCLUDE += -I$(HL2SDK)/public/game/server
	SRCDS = $(SRCDS_BASE)/left4dead2
	LIB_PREFIX = lib
	LIB_SUFFIX = .so
	override ENGSET = true
endif

ifeq "$(USEMETA)" "true"
	LINK_HL2 = $(HL2LIB)/tier1_i486.a $(LIB_PREFIX)vstdlib$(LIB_SUFFIX) $(LIB_PREFIX)tier0$(LIB_SUFFIX)

	LINK += $(LINK_HL2)

	INCLUDE += -I. -I.. -Isdk -I$(HL2PUB) -I$(HL2PUB)/engine -I$(HL2PUB)/tier0 -I$(HL2PUB)/tier1 \
		-I$(METAMOD) -I$(METAMOD)/sourcehook -I$(SMSDK)/public -I$(SMSDK)/public/sourcepawn 
	CFLAGS += -DSE_EPISODEONE=1 -DSE_DARKMESSIAH=2 -DSE_ORANGEBOX=3 -DSE_ORANGEBOXVALVE=4 \
		-DSE_LEFT4DEAD=5 -DSE_LEFT4DEAD2=6
else
	INCLUDE += -I. -I.. -Isdk -I$(SMSDK)/public -I$(SMSDK)/public/sourcepawn
endif

LINK += -m32 -lm -ldl

CFLAGS += -D_LINUX -Dstricmp=strcasecmp -D_stricmp=strcasecmp -D_strnicmp=strncasecmp -Dstrnicmp=strncasecmp \
	-D_snprintf=snprintf -D_vsnprintf=vsnprintf -D_alloca=alloca -Dstrcmpi=strcasecmp -Wall -Werror -Wno-switch \
	-Wno-unused -mfpmath=sse -msse -DSOURCEMOD_BUILD -DHAVE_STDINT_H -m32
CPPFLAGS += -Wno-non-virtual-dtor -fno-exceptions -fno-rtti

################################################
### DO NOT EDIT BELOW HERE FOR MOST PROJECTS ###
################################################

ifeq "$(DEBUG)" "true"
	BIN_DIR = Debug
	CFLAGS += $(C_DEBUG_FLAGS)
else
	BIN_DIR = Release
	CFLAGS += $(C_OPT_FLAGS)
endif

ifeq "$(USEMETA)" "true"
	BIN_DIR := $(BIN_DIR).$(ENGINE)
endif

OS := $(shell uname -s)
ifeq "$(OS)" "Darwin"
	LINK += -dynamiclib
	BINARY = $(PROJECT).ext.dylib
else
	LINK += -static-libgcc -shared
	BINARY = $(PROJECT).ext.so
endif

GCC_VERSION := $(shell $(CPP) -dumpversion >&1 | cut -b1)
ifeq "$(GCC_VERSION)" "4"
	CFLAGS += $(C_GCC4_FLAGS)
	CPPFLAGS += $(CPP_GCC4_FLAGS)
endif

OBJ_LINUX := $(OBJECTS:%.cpp=$(BIN_DIR)/%.o)

$(BIN_DIR)/%.o: %.cpp
	$(CPP) $(INCLUDE) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

all: check
	mkdir -p $(BIN_DIR)/sdk
	if [ "$(USEMETA)" = "true" ]; then \
		ln -sf $(HL2LIB)/$(LIB_PREFIX)vstdlib$(LIB_SUFFIX); \
		ln -sf $(HL2LIB)/$(LIB_PREFIX)tier0$(LIB_SUFFIX); \
	fi
	$(MAKE) -f Makefile extension	
	mkdir -p $(PACKAGEDIR)
	if [ "$(USEMETA)" != "true" ]; then \
		cp $(BIN_DIR)/$(BINARY) $(PACKAGEDIR)/; \
	fi
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGINE)" = "original" ]; then \
		cp $(BIN_DIR)/$(BINARY) $(PACKAGEDIR)/$(PROJECT).ext.ep1.so; \
	fi
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGINE)" = "orangeboxvalve" ]; then \
		cp $(BIN_DIR)/$(BINARY) $(PACKAGEDIR)/$(PROJECT).ext.ep2v.so; \
	fi
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGINE)" = "orangebox" ]; then \
		cp $(BIN_DIR)/$(BINARY) $(PACKAGEDIR)/$(PROJECT).ext.ep2.so; \
	fi
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGINE)" = "left4dead" ]; then \
		cp $(BIN_DIR)/$(BINARY) $(PACKAGEDIR)/$(PROJECT).ext.l4d.so; \
	fi
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGINE)" = "left4dead2" ]; then \
		cp $(BIN_DIR)/$(BINARY) $(PACKAGEDIR)/$(PROJECT).ext.l4d2.so; \
	fi

check:
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGSET)" = "false" ]; then \
		echo "You must supply one of the following values for ENGINE:"; \
		echo "left4dead2, left4dead, orangeboxvalve, orangebox, or original"; \
		exit 1; \
	fi

extension: check $(OBJ_LINUX)
	$(CPP) $(INCLUDE) $(OBJ_LINUX) $(LINK) -o $(BIN_DIR)/$(BINARY)

debug:
	$(MAKE) -f Makefile all DEBUG=true

default: all

clean: check
	rm -rf $(BIN_DIR)/*.o
	rm -rf $(BIN_DIR)/sdk/*.o
	rm -rf $(BIN_DIR)/$(BINARY)
