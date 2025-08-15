# --- Toolchain e Configurações ---
# Define o prefixo da toolchain bare-metal
TOOLCHAIN = arm-none-eabi-

# Define as ferramentas usando o prefixo
AS = $(TOOLCHAIN)as
LD = $(TOOLCHAIN)ld
OBJCOPY = $(TOOLCHAIN)objcopy

PYTHON = python3
CONVERTER_PY = converter.py

# --- Flags de Compilação ---
# Flag de CPU para o Raspberry Pi 2B (Cortex-A7)
CPUFLAGS = -mcpu=cortex-a7

# Flags para o montador (Assembler)
ASFLAGS = $(CPUFLAGS)

# --- Nomes de Arquivos ---
# O alvo final é o kernel7.img
TARGET = kernel7.img
# O arquivo ELF intermediário
ELF = kernel.elf
# O nosso linker script
LINKER_SCRIPT = linker.ld

# --- Definição de Arquivos de Código-Fonte ---
# Encontra automaticamente qualquer arquivo .mp3 na pasta input
AUDIO_FILES = $(wildcard input/*.mp3)
# Remove a extensão .mp3 para obter o nome base
AUDIO_FILES_NO_EXT = $(basename $(AUDIO_FILES))
# Gera o nome do arquivo .s que será criado na pasta output
GENERATED_S_FILES = $(patsubst input/%, output/pwm_%.s, $(AUDIO_FILES_NO_EXT))
# Gera os nomes dos arquivos .o correspondentes
GENERATED_O_FILES = $(patsubst %.s, %.o, $(GENERATED_S_FILES))
# Lista final de todos os objetos que formarão nosso kernel
OBJS = main.o $(GENERATED_O_FILES)

# --- Regras do Makefile ---
.PHONY: all clean

# A regra padrão constrói o alvo final
all: $(TARGET)

# REGRA DE DUMP: Cria o kernel7.img (binário puro) a partir do ELF
# Corresponde a: "arm-none-eabi-objcopy programa.elf -O binary kernel7.img"
$(TARGET): $(ELF)
	@echo "✨ Extraindo binário puro (dumping) -> $@"
	$(OBJCOPY) $(ELF) -O binary $(TARGET)

# REGRA DE LINK: Cria o arquivo ELF a partir de todos os objetos .o
# Corresponde a: "arm-none-eabi-ld -T linker.ld x.o y.o -o programa.elf"
$(ELF): $(OBJS)
	@echo "🔗 Linkando objetos para criar o ELF -> $@"
	$(LD) -T $(LINKER_SCRIPT) -o $(ELF) $(OBJS)

# REGRA DE GERAÇÃO (Python): Cria o .s e .bin a partir do .mp3
output/pwm_%.s: input/%.mp3 $(CONVERTER_PY)
	@echo "🐍 Gerando binário e wrapper Assembly para $<..."
	$(PYTHON) $(CONVERTER_PY) $<

# REGRA DE MONTAGEM (Assembly): Cria um .o a partir de um .s
# Corresponde a: "arm-none-eabi-as -mcpu=cortexa7 x.s -o x.o"
%.o: %.s
	@echo "🛠️  Montando $< para $@..."
	$(AS) $(ASFLAGS) $< -o $@

# REGRA DE LIMPEZA: Remove todos os arquivos gerados
clean:
	@echo "🧹 Limpando arquivos gerados..."
	rm -f main.o $(TARGET) $(ELF)
	rm -rf output temp