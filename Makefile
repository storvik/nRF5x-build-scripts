##
# nRF5x general makefile
##

# Optional variables
#: VERBOSE: Detailed output, showing all commands and outputs
#: LINKER_SCRIPT: Path to custom linker script, should be used in most applications
#: FLASH_SNR: Serial number for programmer (not optional if multiple programmers connected)
#: SOFTDEVICE_HEX: Path to softdevice, used when flashing and / or verifying chip
#: PROGRAM_HEX: Path to program hex file, used mainly when flashing and / or verifying chip

# Variable setup
include $(BUILD_SCRIPT_PATH)/Makefile.variables

# Compiler setup
TOOLCHAIN_PREFIX ?= arm-none-eabi
AS      = $(abspath $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_PREFIX)-as)
CC      = $(abspath $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_PREFIX)-gcc)
LD      = $(abspath $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_PREFIX)-gcc)
OBJCOPY = $(abspath $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_PREFIX)-objcopy)
OBJDUMP = $(abspath $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_PREFIX)-objdump)
SIZE    = $(abspath $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_PREFIX)-size)
GDB     = $(abspath $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_PREFIX)-gdb)

MAKE_BUILD_FOLDER = mkdir -p $(OUTPUT_PATH)
REMOVE_BUILD_FOLDER = rm -rf $(OUTPUT_PATH)

# Device uppercase
DEVICE ?= $(shell echo $(NRF_MODEL) | tr a-z A-Z)
DEVICE_IC ?= $(shell echo $(NRF_IC) | tr a-z A-Z)

ifndef DEVICE_IC
	$(error "Cant detect which IC (ex. nrf51422/nrf52832). You must define it in project Makefile.")
endif

START_CODE ?= gcc_startup_$(NRF_MODEL).s
SYSTEM_FILE ?= system_$(NRF_MODEL).c

ifeq ("$(VERBOSE)","1")
NO_ECHO :=
else
NO_ECHO := @
endif

SDK_PATH = $(SDK_VERSIONS_PATH)/$(SDK_VERSION)/

ifndef SOFTDEVICE
    SOFTDEVICE = blank
    LINKER_SCRIPT ?= $(SDK_PATH)components/toolchain/gcc/$(NRF_MODEL)_xx$(NRF_IC_VARIANT).ld
else
    CFLAGS += -DSOFTDEVICE_PRESENT
    CFLAGS += -DSOFTDEVICE_$(SOFTDEVICE)
endif

LINKER_COMMON_PATH = $(SDK_PATH)components/toolchain/gcc
LINKER_SCRIPT ?= $(SDK_PATH)components/softdevice/$(SOFTDEVICE)/toolchain/armgcc/armgcc_$(SOFTDEVICE)_$(NRF_IC)_xx$(NRF_IC_VARIANT).ld

# Check SDK version and include correct file
ifeq ($(SDK_VERSION), 14.2.0)
    CFLAGS += -DSDK_VERSION_14
    include $(BUILD_SCRIPT_PATH)/Makefile.sdk14
else
ifeq ($(SDK_VERSION), 13.0.0)
    CFLAGS += -DSDK_VERSION_13
    include $(BUILD_SCRIPT_PATH)/Makefile.sdk13
else
ifeq ($(SDK_VERSION), 12.1.0)
    CFLAGS += -DSDK_VERSION_12
    include $(BUILD_SCRIPT_PATH)/Makefile.sdk12
else
ifeq ($(SDK_VERSION), 11.0.0)
    CFLAGS += -DSDK_VERSION_11
    include $(BUILD_SCRIPT_PATH)/Makefile.sdk11
else
endif
endif
endif
endif

ifdef USE_BLE
    CFLAGS += -DBLE_STACK_SUPPORT_REQD
endif

ifdef USE_ANT
    CFLAGS += -DANT_STACK_SUPPORT_REQD
endif

print-% : ; @echo $* = $($*)

OUTPUT_NAME ?= $(addsuffix _$(SOFTDEVICE), $(PROJECT_NAME))

LIBRARY_INCLUDES = $(addprefix -I,$(LIBRARY_PATHS))
CMSIS_INCLUDE = $(addprefix -I,$(CMSIS_INCLUDE_PATH))

VPATH = $(SOURCE_PATHS):$(LIBRARY_PATHS)

# Device specific flags
ifeq ($(DEVICE), NRF51)
    CPUFLAGS += -mthumb -mcpu=cortex-m0 -march=armv6-m
else
ifeq ($(DEVICE), NRF52)
    CPUFLAGS += -mthumb -mcpu=cortex-m4
    CPUFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16

ifeq ($(SDK_VERSION), 14.2.0)
	CFLAGS += -DNRF52_PAN_74
else
ifeq ($(SDK_VERSION), 13.0.0)
    CFLAGS += -DNRF52_PAN_12
    CFLAGS += -DNRF52_PAN_15
    CFLAGS += -DNRF52_PAN_20
    CFLAGS += -DNRF52_PAN_31
    CFLAGS += -DNRF52_PAN_36
    CFLAGS += -DNRF52_PAN_51
    CFLAGS += -DNRF52_PAN_54
    CFLAGS += -DNRF52_PAN_55
    CFLAGS += -DNRF52_PAN_58
    CFLAGS += -DNRF52_PAN_64
    CFLAGS += -DNRF52_PAN_74
else
    CFLAGS += -DNRF52_PAN_12
    CFLAGS += -DNRF52_PAN_15
    CFLAGS += -DNRF52_PAN_20
    CFLAGS += -DNRF52_PAN_30
    CFLAGS += -DNRF52_PAN_31
    CFLAGS += -DNRF52_PAN_36
    CFLAGS += -DNRF52_PAN_51
    CFLAGS += -DNRF52_PAN_53
    CFLAGS += -DNRF52_PAN_54
    CFLAGS += -DNRF52_PAN_55
    CFLAGS += -DNRF52_PAN_58
    CFLAGS += -DNRF52_PAN_62
    CFLAGS += -DNRF52_PAN_63
    CFLAGS += -DNRF52_PAN_64
endif
endif
endif
endif

ASMFLAGS += -x assembler-with-cpp

#CFLAGS += -Os
CFLAGS += -std=gnu99 -c $(CPUFLAGS) -Wall
CFLAGS += -D$(DEVICE) -D$(DEVICE_IC) -D$(BOARD)
CFLAGS += -s -ffunction-sections -fdata-sections
CFLAGS += -D$(shell echo $(SOFTDEVICE) | tr a-z A-Z)
CFLAGS += $(CMSIS_INCLUDE) $(LIBRARY_INCLUDES) -MD

LDFLAGS += $(CPUFLAGS)
LDFLAGS += -Xlinker -Map=$(OUTPUT_PATH)/$(OUTPUT_NAME).map
LDFLAGS += -mabi=aapcs -L $(LINKER_COMMON_PATH) -T$(LINKER_SCRIPT)
LDFLAGS += -Wl,--gc-sections
LDFLAGS += --specs=nano.specs -lc -lnosys

HEX = $(OUTPUT_PATH)$(OUTPUT_NAME).hex
ELF = $(OUTPUT_PATH)$(OUTPUT_NAME).elf
BIN = $(OUTPUT_PATH)$(OUTPUT_NAME).bin

SRCS = $(SYSTEM_FILE) $(notdir $(APPLICATION_SRCS))
OBJS = $(addprefix $(OUTPUT_PATH), $(SRCS:.c=.o)) $(addprefix $(OUTPUT_PATH),$(APPLICATION_LIBS))
DEPS = $(addprefix $(OUTPUT_PATH), $(SRCS:.c=.d))
SRCS_AS = $(START_CODE)
OBJS_AS = $(addprefix $(OUTPUT_PATH), $(SRCS_AS:.s=.os))

all: begin $(OBJS) $(OBJS_AS) $(HEX) finished ## Makes project to OUTPUT_PATH and displays overview of file sizes

rebuild: clean all ## Cleans build dir before running make all

include $(BUILD_SCRIPT_PATH)/Makefile.nrfjprog

begin:
	@echo "--> Compiling project..."

finished:
	@echo "--> Makefile successfully finished..."
	@echo "    Errors: none"

clean: ## Remove all build files, including the build dir specified in OUTPUT_PATH
	@echo "--> Cleaning project folders..."
	@echo "    Removing build folder"; $(REMOVE_BUILD_FOLDER)

$(HEX): $(OBJS) $(OBJS_AS)
	$(NO_ECHO)$(LD) $(LDFLAGS) $(OBJS_AS) $(OBJS) -o $(ELF)
	$(NO_ECHO)$(OBJCOPY) -Oihex $(ELF) $(HEX)
	$(NO_ECHO)$(OBJCOPY) -Obinary $(ELF) $(BIN)
	$(NO_ECHO)$(SIZE) $(ELF)

size: $(ELF)
	$(SIZE) $(ELF)

$(OUTPUT_PATH)%.o: %.c
	@echo "    Compiling file: $(notdir $<)"
	$(NO_ECHO)$(MAKE_BUILD_FOLDER)
	$(NO_ECHO)$(CC) $(LDFLAGS) $(CFLAGS) $< -o $@

$(OUTPUT_PATH)%.os: %.s
	@echo "    Compiling file: $(notdir $<)"
	$(NO_ECHO)$(CC) $(CPUFLAGS) $(ASMFLAGS) $(LIBRARY_INCLUDES) -c -o $@ $<

docs: ## Make documentation by running the command defined in Makefile.variables, default: doxygen
	@echo "--> Creating documentation...";
	@echo "    Running: $(DOCS_CMD)"; $(DOCS_CMD)
	@echo "    Documentation generated...";

-include $(DEPS)

#.PHONY: all clean rebuild size
.PHONY: help

help: ## Display this help screen
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "Optional arguments:"
	@awk 'BEGIN {FS = ": "} /^#: [a-zA-Z_-]+: / {printf "\033[36m%-30s\033[0m %s\n", $$2, $$3}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
