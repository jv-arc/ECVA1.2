import numpy as np
from pydub import AudioSegment as AS
from pydub.effects import normalize
import os
import sys

# --- Constantes ---
DEFAULT_SAMPLE_RATE = 44100
DEFAULT_CHANNELS = 1
DEFAULT_SAMPLE_WIDTH = 2
INPUT_DIR = "./input"
TEMP_DIR = "./temp"
OUTPUT_DIR = "./output"

# --- Classe AudioConverter ---
class AudioConverter:
    def __init__(self, temp_dir=TEMP_DIR, sample_rate=DEFAULT_SAMPLE_RATE, channels=DEFAULT_CHANNELS, sample_width=DEFAULT_SAMPLE_WIDTH):
        self.temp_dir= temp_dir
        self.sample_rate = sample_rate
        self.channels = channels
        self.sample_width = sample_width
    def load_file(self, file_name: str) -> AS:
        if not os.path.exists(file_name):
            raise FileNotFoundError(f"Arquivo não encontrado: {file_name}")
        file = AS.from_file(file_name)
        return file
    def normalize_audio(self, segment: AS) -> AS:
        new_audio = segment.set_frame_rate(self.sample_rate).set_channels(self.channels).set_sample_width(self.sample_width)
        return normalize(new_audio)
    def convert_file(self, segment: AS, file_name: str) -> str:
        os.makedirs(self.temp_dir, exist_ok=True)
        path=os.path.join(self.temp_dir, file_name + ".raw")
        segment.export(path, format="raw")
        return path

# --- Classe TextEncoder ---
class TextEncoder:
    def __init__(self, temp_dir=TEMP_DIR, output_dir=OUTPUT_DIR, sample_width:int=DEFAULT_SAMPLE_WIDTH, pwm_amplitude:int=255):
        self.temp_dir = temp_dir
        self.output_dir = output_dir
        self.sample_width = sample_width
        self.pwm_amplitude = pwm_amplitude
        self.np_type_s_map = {1: np.int8, 2: np.int16, 4: np.int32}
        self.np_type_u_map = {1: np.uint8, 2: np.uint16, 4: np.uint32}
        self.bit_depth_map = {1: 8, 2: 16, 4: 32}
    def read_raw_audio(self, file_name:str) -> np.array:
        path = os.path.join(self.temp_dir, file_name + ".raw")
        dtype = self.np_type_s_map[self.sample_width]
        audio_data = np.fromfile(path, dtype=dtype)
        return audio_data
    def pcm_to_pwm(self, source: np.array) -> np.array:
        bit_depth = self.bit_depth_map[self.sample_width]
        offset = 2**(bit_depth -1)
        max_range = 2**bit_depth -1
        pwm = ((source.astype(int) + offset) / max_range * self.pwm_amplitude).astype(int)
        return pwm
    def export_to_binary(self, source: np.array, filename: str) -> str:
        os.makedirs(self.output_dir, exist_ok=True)
        path = os.path.join(self.output_dir, filename + ".bin")
        source.astype(np.uint8).tofile(path)
        return path
    def create_assembly_wrapper(self, bin_filename: str, label: str):
        N = os.path.getsize(os.path.join(self.output_dir, bin_filename))
        s_filename = os.path.splitext(bin_filename)[0] + ".s"
        path = os.path.join(self.output_dir, s_filename)
        with open(path, "w") as f:
            f.write(f".section .rodata\n")
            f.write(f".global {label}\n")
            f.write(f".align 4\n\n")
            f.write(f"{label}:\n")
            f.write(f'    .incbin "{os.path.join(self.output_dir, bin_filename)}"\n\n')
            f.write(f".global {label}_len\n")
            f.write(f"{label}_len:\n")
            f.write(f"    .word {N}\n")

# --- Função de Execução ---
def run_extraction(input_filepath):
    song_filename = os.path.basename(input_filepath)
    name_without_ext = os.path.splitext(song_filename)[0]
    ac = AudioConverter()
    te = TextEncoder()
    print(f"Processando '{song_filename}'...")
    original_segment = ac.load_file(file_name=input_filepath)
    treated_segment = ac.normalize_audio(segment=original_segment)
    ac.convert_file(segment=treated_segment, file_name=name_without_ext)
    byte_stream = te.read_raw_audio(name_without_ext)
    pwm_data = te.pcm_to_pwm(byte_stream)
    final_name_base = "pwm_" + name_without_ext
    bin_file = te.export_to_binary(source=pwm_data, filename=final_name_base)
    print(f"-> Arquivo binário '{bin_file}' gerado com sucesso.")
    te.create_assembly_wrapper(bin_filename=final_name_base + ".bin", label=name_without_ext)
    print(f"-> Arquivo Assembly '{os.path.join(OUTPUT_DIR, final_name_base)}.s' gerado com sucesso.")

# --- Ponto de Entrada ---
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Erro: Forneça o caminho do arquivo de áudio como argumento.")
        sys.exit(1)
    input_file = sys.argv[1]
    run_extraction(input_file)