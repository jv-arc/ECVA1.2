# Registradores GPFEL
Dentre todos os registradores de controle de GPIO, os registradores GPFSEL (GPIO Function Select) definem o comportamento dos pinos com palavras de 3 bits.
## Encontrando posições
Temos um total de 6 registradores do tipo (GPFSEL0 à GPFSEL5) cada um controlando 10 GPIOs em ordem.

Dessa forma podemos identificar o GPFSEL correto ao fazer a divisão inteira donúmero do pino desejado por 10.

```C
registrador_gpfsel = (numero_pino / 10)
```

Não podemos esquecer que dentro de cada GPFSEL temos várias palavras de 3 bits com o controle dos pinos em ordem, assim precisamos também encontrar em que posição estão os bits de controle do pino desejado.

Podemos fazer isso com o resto da divisão do numero do pino por dez vezes o comprimento da palavra de bits de controle

```C
deslocamento_bits = (numero_pino % 10) *3
``` 

### Exemplo
Se queremos encontrar o GPFSEL e o deslocamento do pino 18 (Importante pro PWM)

Fazemos:
```
18 /10 = 1 
``` 

Que nos indica que o registrador de controle do GPIO 18 é GPFSEL1

E encontramos o deslocamento:
```
18 % 10 = 8 (oitavo GPIO do GPFSEL1)
8 * 3 = 24 (deslocamento de 24 bits)
``` 

Com isso sabemos que os bits que controlam o GPIO 18 são os 24, 25 e 26 do GPFSEL1.


## Valores de Controle
Temos várias possibilidades para os GPIO, como entrada e saída (000 e 001) e funções alternativas que são especificas de cada pino.

| **Valor (3 bits)** | Binário | Função                      |
| ------------------ | ------- | --------------------------- |
| **0**              | 000     | Entrada (Input)             |
| **1**              | 001     | Saída (Output)              |
| **2**              | 010     | Função Alternativa 5 (ALT5) |
| **3**              | 011     | Função Alternativa 4 (ALT4) |
| **4**              | 100     | Função Alternativa 0 (ALT0) |
| **5**              | 101     | Função Alternativa 1 (ALT1) |
| **6**              | 110     | Função Alternativa 2 (ALT2) |
| **7**              | 111     | Função Alternativa 3 (ALT3) |
Podemos por exemplo setar o GPIO 18 para função alternativa 2 (110) para uso de PWM.
## Funcionamento no Código
Para utilizar os pinos é só acessa-los normalmente seja de forma direta ou pelo nmap, porém como esses registradores controlam vários pinos ao mesmo tempo é necessário apenas mudar os valores que desejamos e evitar mudar outros valores no registrador.

Copia valor original de `GPFSEL1` para `r1`
``` armasm
ldr r0, =GPIO_BASE
ldr r1, [r0, #GPFSEL1]
```

 Zera bits 24, 25 e 26 com máscara
```armasm
mov r2, #0b111
lsl r2, r2, #24
bic r1, r1, r2
``` 

Desloca 001 para escrever em 24, 25 e 26 e faz ou lógico com valor em `r1`
```armasm
mov r2, #0b1
lsl r2, r2, #24
orr r1, r1, r2
```

Escreve `r1` com o valor modificado de volta na posição de memória
```
str r1, [r0, #GPFSEL1]
```