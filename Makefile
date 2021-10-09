# gcc config
# GCC_TOOL_PATH
#firmware info
-include config.mk

ARCH = arm-none-eabi-gcc-ar
AS = arm-none-eabi-gcc
CC = arm-none-eabi-gcc
ELFTOOL = arm-none-eabi-objcopy
LD = arm-none-eabi-gcc
STRIP = arm-none-eabi-strip
ARM_SIZE = arm-none-eabi-size
#sdk path
LIBDIR = ./lib/$(PLATFORM)/
SDK_DIR = ./sdk

ifeq ($(PLATFORM), EFR32MG13P732F512)
ifeq ($(DEBUG_SYMBOLS), TRUE)
LIB_FILES = $(LIBDIR)/libtuya_sdk_debug.a
CCFLAGS = -DAPP_DEBUG \
	-DEFR32MG13P \
	-g3 \
	-O0 \

ASMFLAGS = -g3 \	

LDFLAGS = -g3 \

else
LIB_FILES = $(LIBDIR)/libtuya_sdk.a
CCFLAGS = -Os \

ASMFLAGS =
LDFLAGS =
endif
endif

TOOL = $(SDK_DIR)/tool

# app code
SOURCE_FILES = \
$(wildcard ./src/*.c) \
$(wildcard ./tools/gcc_boot/*.c) \
$(wildcard ./tools/gcc_boot/$(PLATFORM)/*.c) \

CINC = -I./ \
-I $(LIBDIR) \
-I./include \
-I./lib/include \


OUTPUT_DIR = ./build

# others info, don't change
ARCHITECTURE_DIR = efr32
GLOBAL_BASE_DIR     = $(SDK_DIR)/platform/base/hal/..

CSOURCES = $(filter %.c, $(SOURCE_FILES))
ASMSOURCES = $(filter %.s79, $(SOURCE_FILES))
ASMSOURCES2 = $(filter %.s, $(SOURCE_FILES))

COBJS = $(addprefix $(OBJ_DIR)/,$(CSOURCES:.c=.o))
ASMOBJS = $(addprefix $(OBJ_DIR)/,$(ASMSOURCES:.s79=.o))
ASMOBJS2 = $(addprefix $(OBJ_DIR)/,$(ASMSOURCES2:.s=.o))

OBJ_DIRS = $(sort $(dir $(COBJS)) $(dir $(ASMOBJS)) $(dir $(ASMOBJS2)))

# GNU ARM compiler
# Add linker circular reference as the order of objects may matter for any libraries used
GROUP_START =-Wl,--start-group
GROUP_END =-Wl,--end-group        

CCFLAGS+= -D__STACK_SIZE=2400 \
	-D__HEAP_SIZE=10240 \
	-DEFR32MG13P \
	-gdwarf-2 \
    -mcpu=cortex-m4 \
    -mthumb \
    -std=gnu99 \
    $(CDEFS) \
    $(CINC) \
    -Wall  \
    -Wno-unused-parameter \
    -Wno-unused-variable \
    -Wno-unused-but-set-variable \
    -c  \
    -fmessage-length=0  \
    -ffunction-sections  \
    -fdata-sections  \
    -mfpu=fpv4-sp-d16  \
    -mfloat-abi=softfp

ASMFLAGS+= -gdwarf-2 \
	-mcpu=cortex-m4 \
	-mthumb \
	-c \
	-x assembler-with-cpp \
	$(CINC) \
	$(ASMDEFS) \
	-mfpu=fpv4-sp-d16  \
	-mfloat-abi=softfp


LDFLAGS+= -lm \
	-gdwarf-2 \
	-mcpu=cortex-m4 \
	-lgcc \
	-mcpu=cortex-m4 -specs=nano.specs -specs=nosys.specs \
	-mthumb -T "$(GLOBAL_BASE_DIR)/hal/micro/cortexm3/efm32/gcc-cfg.ld" \
	-L"$(GLOBAL_BASE_DIR)/hal/micro/cortexm3/" \
	-Xlinker --defsym="SIMEEPROM_SIZE=36864" \
	-Xlinker --defsym="FLASH_SIZE=524288" \
	-Xlinker --defsym="RAM_SIZE=65536" \
	-Xlinker --defsym=APP_GECKO_INFO_PAGE_BTL=1 \
	-Xlinker --gc-sections \
	-Xlinker -Map="./$(OUTPUT_DIR)/$(TARGET).map" \
	-mfpu=fpv4-sp-d16 \
	-mfloat-abi=softfp  -u _printf_float \
	-Wl,--start-group -lc -Wl,--end-group \
	-Wl,--no-wchar-size-warning \


ARCHFLAGS = r
ELFTOOLFLAGS_BIN = -O binary
ELFTOOLFLAGS_HEX = -O ihex
ELFTOOLFLAGS_S37 = -O srec

.PHONY: all clean PROLOGUE

all: PROLOGUE $(OBJ_DIRS) $(COBJS) $(ASMOBJS) $(ASMOBJS2)
	@echo 'Linking...'
	@echo 'Building out file: tuya_sdk.out'
	$(LD) $(GROUP_START) $(LDFLAGS) $(COBJS) $(ASMOBJS) $(ASMOBJS2) $(LIB_FILES) $(GROUP_END) -o $(OUTPUT_DIR)/dev.out
	$(STRIP) $(OUTPUT_DIR)/dev.out
	@echo ' '
	
	@echo 'Building bin file: tuya_sdk.bin'
	$(ELFTOOL) $(OUTPUT_DIR)/dev.out $(ELFTOOLFLAGS_BIN) $(OUTPUT_DIR)/$(TARGET).bin
	@echo ' '
	
	@echo 'Building hex file: tuya_sdk.hex'
	$(ELFTOOL) $(OUTPUT_DIR)/dev.out $(ELFTOOLFLAGS_HEX) $(OUTPUT_DIR)/$(TARGET).hex
	@echo ' '
	
	@echo 'Building s37 file: tuya_sdk.s37'
	$(ELFTOOL) $(OUTPUT_DIR)/dev.out $(ELFTOOLFLAGS_S37) $(OUTPUT_DIR)/$(TARGET).s37
	@echo ' '
	
	@echo 'Running size tool'
	$(ARM_SIZE) "$(OUTPUT_DIR)/$(TARGET).s37"
	@echo ' '
	
	
	@echo ' '
	$(RM) -rf ../common
	$(RM) -rf ../../../tools/
	@echo 'Done.'


PROLOGUE:
#	@echo $(COBJS)
#	@echo $(ASMOBJS)
#	@echo $(ASMOBJS2)

$(OBJ_DIRS):
	@mkdir -p $@
	@mkdir -p $(OUTPUT_DIR)
$(COBJS): %.o:
	@echo 'Building $(notdir $(@:%.o=%.c))...'
	@$(CC) $(CCFLAGS) -o $@ $(filter %$(@:$(OBJ_DIR)/%.o=%.c),$(CSOURCES))

$(ASMOBJS): %.o:
	@echo 'Building $(notdir $(@:%.o=%.s79))...'
	@$(AS) $(ASMFLAGS) -o $@ $(filter %$(@:$(OBJ_DIR)/%.o=%.s79),$(ASMSOURCES))

$(ASMOBJS2): %.o:
	@echo 'Building $(notdir $(@:%.o=%.s))...'
	@$(AS) $(ASMFLAGS) -o $@ $(filter %$(@:$(OBJ_DIR)/%.o=%.s),$(ASMSOURCES2))


clean:
	$(RM) -rf ./build
