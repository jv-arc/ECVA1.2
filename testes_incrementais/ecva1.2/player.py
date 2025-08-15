import numpy as np
import sounddevice as sd
import os
import time

# --- Configurações ---
# Mude esta variável para o nome do seu arquivo de música (sem a extensão)
NOME_DA_MUSICA = "daft_punk"

# Taxa de amostragem que usamos no conversor. DEVE ser a mesma.
TAXA_DE_AMOSTRAGEM = 44100

# Monta o caminho do arquivo usando o formato do Windows
# os.path.join já usa a barra correta para cada SO ('\' no Windows)
caminho_do_arquivo = os.path.join("output", f"pwm_{NOME_DA_MUSICA}.bin")

def tocar_pwm(caminho):
    """Lê um arquivo de dados PWM e o toca no computador."""
    
    if not os.path.exists(caminho):
        print(f"Erro: Arquivo não encontrado em '{caminho}'")
        print("Você já executou o comando 'make' no ambiente WSL para gerá-lo?")
        return

    print(f"Carregando dados de '{caminho}'...")
    dados_pwm = np.fromfile(caminho, dtype=np.uint8)
    
    if len(dados_pwm) == 0:
        print("Arquivo de áudio está vazio!")
        return
        
    print("Convertendo PWM para áudio PCM...")
    audio_float = dados_pwm / 255.0
    audio_float = (audio_float * 2.0) - 1.0
    audio_pcm = (audio_float * 32767).astype(np.int16)
    
    duracao_segundos = len(audio_pcm) / TAXA_DE_AMOSTRAGEM
    print(f"Pronto para tocar! Duração: {duracao_segundos:.2f} segundos.")
    
    try:
        sd.play(audio_pcm, samplerate=TAXA_DE_AMOSTRAGEM)
        print("Tocando... Pressione Ctrl+C para parar.")
        sd.wait() # sd.wait() funciona bem no Windows
        print("\nReprodução terminada.")

    except KeyboardInterrupt:
        sd.stop()
        print("\nReprodução interrompida pelo usuário.")
    except Exception as e:
        print(f"Ocorreu um erro durante a reprodução: {e}")

if __name__ == "__main__":
    tocar_pwm(caminho_do_arquivo)