import numpy as np
from scipy.io.wavfile import write
import os

# --- Parâmetros do Sinal de Teste em Rampa ---
SAMPLE_RATE = 44100         # Deve ser o mesmo do seu projeto
RAMP_DURATION_S = 1.0       # Duração de cada rampa de 0 a 255
CYCLES = 10                 # Quantas vezes a rampa se repete (10 * 1s = 10s)

PWM_MIN_VALUE = 0           # Valor PWM inicial
PWM_MAX_VALUE = 255         # Valor PWM final

OUTPUT_DIR = "input"        # Salva o .wav diretamente na pasta de entrada
FILENAME = "ramp_signal.wav" # Nome do nosso ficheiro de áudio de teste

def generate_ramp_wav():
    """Gera um ficheiro .wav com um sinal de PWM em rampa e o salva na pasta 'input'."""
    
    print("Gerando sinal de teste em rampa PWM...")
    
    # Calcula o número de amostras para uma única rampa de 1 segundo
    samples_per_ramp = int(SAMPLE_RATE * RAMP_DURATION_S)
    
    # --- Cria uma única rampa de 0 a 255 ---
    # np.linspace cria um array com valores espaçados igualmente entre um início e um fim.
    # Isto irá gerar 44100 valores que vão subindo suavemente de 0 até 255.
    one_ramp = np.linspace(start=PWM_MIN_VALUE, stop=PWM_MAX_VALUE, num=samples_per_ramp, dtype=np.uint8)
    
    # Repete a rampa 10 vezes para ter 10 segundos de áudio
    full_signal_pwm = np.tile(one_ramp, CYCLES)
    
    total_duration = len(full_signal_pwm) / SAMPLE_RATE
    print(f"Sinal PWM gerado com {len(full_signal_pwm)} amostras (Duração: {total_duration:.1f}s).")
    
    # --- Converte o sinal PWM (0-255) para o formato de áudio PCM (-32767 a 32767) ---
    print("Convertendo sinal para o formato de áudio PCM de 16-bit...")
    audio_float = full_signal_pwm / 255.0             # Normaliza para 0.0 a 1.0
    audio_float = (audio_float * 2.0) - 1.0           # Mapeia para -1.0 a 1.0
    audio_pcm = (audio_float * 32767).astype(np.int16) # Converte para 16-bit
    
    # Garante que a pasta de saída existe
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = os.path.join(OUTPUT_DIR, FILENAME)
    
    # Escreve o ficheiro .wav
    write(output_path, SAMPLE_RATE, audio_pcm)
    
    print("-" * 40)
    print(f"SUCESSO! Ficheiro de teste '{output_path}' foi criado.")
    print("Agora você pode atualizar o 'main.s' e rodar 'make' para compilá-lo.")
    print("-" * 40)

if __name__ == "__main__":
    generate_ramp_wav()