# Define os nomes dos arquivos
TARGET = program
SOURCE = interrupcao_botoes_2.s pLED1.s pLED2.s pLED3.s led_pwm.s
LINKER_SCRIPT = linker.ld

# Ferramentas da toolchain
AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump

# Regra principal para compilar tudo
all: $(TARGET).bin

# Converte o ELF para binário
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@
	$(OBJDUMP) -D $< > $(TARGET).lst

# Linka todos os objetos em um executável ELF
$(TARGET).elf: $(patsubst %.s, %.o, $(SOURCE))
	$(LD) -T $(LINKER_SCRIPT) -o $@ $(patsubst %.s, %.o, $(SOURCE))

# Regra genérica para compilar qualquer arquivo .s em um .o
%.o: %.s
	$(AS) -g -o $@ $<

.PHONY: clean
clean:
	rm -f $(patsubst %.s, %.o, $(SOURCE)) $(TARGET).elf $(TARGET).bin $(TARGET).lst
