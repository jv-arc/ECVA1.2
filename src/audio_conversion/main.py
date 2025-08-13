import numpy as np
from pydub import AudioSegment as AS
from pydub.effects import normalize
import os

DEFAULT_SAMPLE_RATE = 44100
DEFAULT_CHANNELS = 1
DEFAULT_SAMPLE_WIDTH = 2
INPUT_DIR = "./input"
TEMP_DIR = "./temp"
OUTPUT_DIR = "./output"



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
    
class TextEncoder:
    def __init__(self, temp_dir=TEMP_DIR, output_dir=OUTPUT_DIR, sample_width:int=DEFAULT_SAMPLE_WIDTH, pwm_amplitude:int=255):
        if sample_width not in [1, 2, 4]:
            raise ValueError(f"sample_width deve ser 1, 2 ou 4, recebido: {sample_width}")
        self.temp_dir = temp_dir
        self.output_dir = output_dir
        self.sample_width = sample_width
        self.pwm_amplitude = pwm_amplitude
        self.np_type_s_map = {1: np.int8, 2: np.int16, 4: np.int32}
        self.np_type_u_map = {1: np.uint8, 2: np.uint16, 4: np.uint32}
        self.bit_depth_map = {1: 8, 2: 16, 4: 32}
        self.bn_str_map = {0: "", 1: ".byte", 2: ".hword", 4: ".word", 8: ".quad"}
        self.bn_len_map = {0: 4, 1: 8, 2: 6, 4: 4, 8: 2}

    def read_raw_audio(self, file_name:str) -> np.array:
        os.makedirs(self.temp_dir, exist_ok=True)
        path = os.path.join(self.temp_dir, file_name + ".raw")
        dtype = self.np_type_s_map[self.sample_width]
        audio_data = np.fromfile(path, dtype=dtype)
        return audio_data
    
    def pcm_to_pwm(self, source: np.array) -> np.array:
        bit_depth = self.bit_depth_map[self.sample_width]
        d_type = self.np_type_u_map[self.sample_width]
        offset = 2**(bit_depth -1)
        max_range = 2**bit_depth -1
        pwm = ((source.astype(int) + offset) / max_range * self.pwm_amplitude).astype(int)
        return pwm

    def to_assembly(self, source:np.array, filename:str="music", label:str="music", length:int=1, align:int=0) -> str:
        N = len(source)
        step = self.bn_len_map[length]
        data_type = self.bn_str_map[length]
        
        os.makedirs(self.output_dir, exist_ok=True)
        path = os.path.join(self.output_dir, filename + ".s")
        if align != 0:
            txt_align = f".align {align}\n"
        else:
            txt_align = ""

        with open(path, "a") as f:
            f.write(f".section .data\n.global {label}\n")
            f.write(txt_align)
            f.write(label + ": \n")
            
            for i in range(0, N, step):
                f.write(f"\t{data_type}")
                for j in range(step):
                    if i+j < N:
                        f.write(" " + hex(source[i+j]))
                f.write("\n")

            f.write("\n")


def run_extraction(song):
    ac = AudioConverter()
    te = TextEncoder()

    original_segment = ac.load_file(file_name=os.path.join('./input', song))
    treated_segment = ac.normalize_audio(segment=original_segment)

    name = os.path.splitext(song)[0]
    if os.path.exists(f"./temp/{name}.raw"):
        os.remove(f"./temp/{name}.raw")
    ac.convert_file(segment=treated_segment, file_name=name)

    byte_stream = te.read_raw_audio(name)
    pwm_data = te.pcm_to_pwm(byte_stream)
    
    final_name = "pwm_" + name
    if os.path.exists(f"./output/{final_name}.s"):
        os.remove(f"./output/{final_name}.s")
    te.to_assembly(source=pwm_data, filename=final_name, label=name)

    input(f"Arquivo '{final_name}.s' criado na pasta de output.\n")
    
    return 0
    


def main ():
    entrada = input("Se o arquivo estiver na pasta 'input' aperte 's', caso contrário COLOQUE O ARQUIVO NA PASTA.\n\n Pressione 's' para continuar, qualquer outra coisa para fechar o programa\n")

    if entrada == 's':
        if not os.path.exists('./input'):
            print("Erro! Pasta 'input' não encontrada... Eu não esperava muito de você, mas nem isso?")
            return
        while True:
            try:
                files = [f for f in os.listdir('./input') if os.path.isfile(os.path.join('./input', f))]
            except PermissionError:
                print("Erro! Permissão negada para acessar a pasta input. Você não confia em mim? :(")
                return
        
            if not files:
                print("Erro! Estranho. A pasta input parece estar vazia.....")
                return
        
            print("\nArquivos na pasta input:")
            print("-" * 40)
            for i, filename in enumerate(files, 1):
                print(f"{i} - {filename}")
            print("0 - Sair")
            print("-" * 40)

            try:
                choice = input("Selecione um arquivo pelo número: ").strip()

                if choice == '0':
                    print("\nTchau...")
                    break
                
                file_index = int(choice) - 1

                if 0 <= file_index < len(files):
                    selected_file = files[file_index]
                    run_extraction(selected_file)
                else:
                    print("Quase! Por favor, tente com algum valor da lista. Eu sei que você consegue ;)")

            except ValueError:
                print("Eu disse para inserir um NÚMERO...")
            except KeyboardInterrupt:
                print("\nTchau...")
                break
    

if __name__ == "__main__":
    main()
