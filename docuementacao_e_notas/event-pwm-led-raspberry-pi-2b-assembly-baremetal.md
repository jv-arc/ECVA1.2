---
type: event
domain: ["#Eletronica/Microcontroladores", "#Ciencia_da_Computacao/Sistemas_Embarcados", "#Ciencia_da_Computacao/Programacao_de_Baixo_Nivel"]
topic: ["#Raspberry_Pi/PWM_Configuracao", "#Assembly/Baremetal_Programacao", "#Hardware/Registradores_Controle"]
lateral: ["#PWM_RNG", "#PWM_DAT", "#PWMCLK_DIV", "#GPIO", "#Raspberry_Pi_2B", "#clock_19_2MHz", "#PWM_PASSWORD", "#debug_LEDs", "#experimento_LED"]
state: normal
---

# Registro do Experimento de LED com PWD 
O objetivo é testar se os conhecimentos de PWM estão precisos e se são úteis para o projeto ao programar em assembly um programa que gere um sinal para um LED que seja facilmente testável a olho nu.

## Conta Inicial
O Clock base do PWM tem 19.2MHz, ao escolher um PWMCLK_DIV de 4000 e um range de 24.000 temos:
$$
\frac{19.2\text{MHz}}{4000*24000} = 0,2\text{Hz} = \text{switching frequency}
$$

Assim temos por volta de 5 segundos por período do PWM.

Vamos testar alguns valores para PWM_DAT1

| PWM_DAT | Duty Cycle | Período Esperado |
| ------- | ---------- | ---------------- |
| 4800    | 20%        | 1 segundo        |
| 9600    | 40%        | 2 segundos       |
| 19200   | 80%        | 4 segundo        |
## Visão Geral
Eu só consegui fazer esse troço funcionar colocando vários delays ao longo do código e verificações, e resets completos do PWM. Para testes foi incluso pinos de teste GPIO17 e GPIO19 para indicar condições de falha e de sucesso.

O código terminou com a estrutura:
1. Definições de constantes
2. Configuração dos pinos
3. Desligar PWM
4. Configurar PWM
5. Ligar PWM
6. Funções de Teste e Delay


## Definição de Constantes

Definição dos endereços de GPIO:
```armasm
.section .text
.global _start

.equ GPIO_BASE, 0x3F200000
.equ GPFSEL1,   0x04
.equ GPSET0,    0x1C
.equ GPCLR0,    0x28
```
  
Seguida pelos endereços do PWM:
```armasm
.equ PWM_BASE,  0x3F20C000
.equ PWM_CTL,   0x00
.equ PWM_STA,   0x04
.equ PWM_RNG1,  0x10
.equ PWM_DAT1,  0x14
```

E os endereços de controle de clock

```armasm
.equ CLK_BASE,    0x3F101000
.equ PWMCLK_CNTL, 0xA0
.equ PWMCLK_DIV,  0xA4
```

Temos também uma "senha" de controle do clock do PWM ela é utilizada para garantir que não ocorram modificações no PWM por acidente. Todas as escritas nos registradores PWMCLK_CNTL e PWMCLK_DIV devem ter a "senha" nos bits mais altos.

```armasm
.equ PWM_PASSWORD, 0x5A000000
```

## Configuração dos GPIOs
Todos os acessos a memória foram feitos utilizando o `r0` como base, como sempre, ao utilizar o GPFSEL, primeiro lemos o valor e depois modificamos apenas oque queremos para evitar problemas.

```armasm
ldr r0, =GPIO_BASE
ldr r1, [r0, #GPFSEL1]
```

Prosseguimos com a limpeza dos valores de 21 à 29 que são os que controlam os GPIO17 à 19.
```armasm

@ Limpa GPIO17 em 21-23
mov r2, #0b111
lsl r2, r2, #21
bic r1, r1, r2

@ Limpa GPIO18 em 24-26
mov r2, #0b111
lsl r2, r2, #24
bic r1, r1, r2

@ Limpa GPIO19 em 27-29
mov r2, #0b111
lsl r2, r2, #27
bic r1, r1, r2
```

Com os valores limpos podemos escrever os valores, GPIO17 e 19 ficam com o valor `001` que indica saída, já GPIO18 fica com `010` que indica a função alternativa (ALT5) para multiplexação com PWM.

```armasm
@ Gera valor de GPIO17
mov r2, #0b001
lsl r2, r2, #21
mov r3, r2

@ Gera valor de GPIO18
mov r2, #0b010
lsl r2, r2, #24
orr r3, r3, r2

@ Gera valor de GPIO19
mov r2, #0b001
lsl r2, r2, #27
orr r3, r3, r2
```

Por fim escrevemos o valor no registrador:
```armasm
orr r1, r1, r3
str r1, [r0, #GPFSEL1]
```

## Matando PWM
O processo acessa tanto os valores de `PWM_BASE`  e `CLK_BASE` conforme for necessário.

### Controle do PWM
Primeiro zeramos todos os sinais de controle do PWM, talvez não seja necessário zerar tudo, mas foi a configuração que deu certo no teste de hoje.

```armasm
@ Carrega endereco
ldr r0, =PWM_BASE

@ Zero valores
mov r1, #0
str r1, [r0, #PWM_CTL]
str r1, [r0, #PWM_RNG1]
str r1, [r0, #PWM_DAT1]
```

Também zeramos as flags do PWM
```armasm
mov r1, #0xFF
str r1, [r0, #PWM_STA]
```

### Controle do Clock
Começamos carregando o endereço de modificação dos registradores de clock e também a "senha".

```armasm
ldr r0, =CLK_BASE
ldr r1, =PWM_PASSWORD
```

Usamos o valor (1<<5) para enviar um sinal de desligamento para o PWM
``` armasm
mov r2, #1
lsl r2, r2, #5
orr r1, r1, r2
str r1, [r0, #PWMCLK_CNTL]
```

Fazemos um espera verificando se o "busy bit" está ligado, ele indica que o dispositivo está ocupado, ou seja que a escrita não terminou.

```armasm
wait_kill:
	ldr r2, [r0, #PWMCLK_CNTL]
	mov r3, #1
	lsl r3, r3, #7 @ Busy bit
	tst r2, r3
	bne wait_kill @ Loop estiver ocupado
```

Também testamos se de fato está desligado, usando o bit ENB:
``` armasm
ldr r2, [r0, #PWMCLK_CNTL]
tst r2, #(1<<4)
bne fail_kill
```


Também zeramos o divisor com um delay no final (provavelmente overkill):
``` armasm
ldr r1, =PWM_PASSWORD
str r1, [r0, #PWMCLK_DIV]
bl delay
```

## Configuração
Como já estamos com `CLK_BASE` em `r0` não precisamos carregar de novo.
### Setando o Divisor
O divisor fica setado com o valor `32` ele precisa de um deslocamento para a esquerda de 12 bits, o divisor pode ir de 0 à 4095.
``` armasm
ldr r1, =PWM_PASSWORD
ldr r2, =32
lsl r2, r2, #12
orr r1, r1, r2
str r1, [r0, #PWMCLK_DIV]

bl delay
```

### Setando o Clock
Aqui tem um ponto crítico para ligar o clock do PWM e ainda no modo normal precisamos exatamente da palavra `00010001`, isso aqui deu bastante dor de cabeça e é muito importante!!!

```armasm
ldr r1, =PWM_PASSWORD
mov r2, #0b00010001
orr r1, r1, r2
str r1, [r0, #PWMCLK_CNTL]
```

De novo aguardamos o dispositivo terminar de escrever
```armasm
wait_config:
ldr r2, [r0, #PWMCLK_CNTL]
mov r3, #1
lsl r3, r3, #7 @ Busy bit
tst r2, r3
bne wait_config @ Loop estiver ocupado
```

E depois testamos se a configuração está feita.
``` armasm
ldr r2, [r0, #PWMCLK_CNTL]
tst r2, #(1<<4)
beq fail_config
  
bl delay
```

## Ligando o PWM
Como estamos lidando com registradores de PWM carregamos o endereço
``` armasm
ldr r0, =PWM_BASE
```

Começamos limpando as flags de status
```armasm
mov r1, #0xFF
str r1, [r0, #PWM_STA]
```

Fazemos o set do range para o canal PWM0 com o valor 1000

```armasm
ldr r1, =1000
str r1, [r0, #PWM_RNG1]
```

Fazemos o set do data para o canal PWM0 com o valor 300 (duty cycle de 30%) 
```armasm
ldr r1, =300
str r1, [r0, #PWM_DAT1]
```

E ligamos o PWM e pulamos para o código que finaliza o processo.
``` armasm
mov r1, #0x81
str r1, [r0, #PWM_CTL]

b controle
``` 

## Código Auxilizar
### Funções de Debug
Se o código não fizesse nada quando tudo dá certo eu não teria como diferenciar a situação de quando o código não executa de quando o código executa mas incorretamente sem ligar o LED no PWM. Para contornar isso eu decidi associar as 3 possibilidades de LED ligados a possibilidades do programa.

| GPIO 17 | GPIO19 | Significado                 |
| ------- | ------ | --------------------------- |
| OFF     | OFF    | O código não rodou          |
| ON      | OFF    | Não conseguiu matar o PWM   |
| OFF     | ON     | Não conseguiu ligar o PWM   |
| ON      | ON     | O código executou até o fim |

Liga os dois leds para indicar que o código chegou no fim
``` armasm
controle:
	mov r2, #0b101
	lsl r2, r2, #17
	ldr r0, =GPIO_BASE
	str r2, [r0, #GPSET0]
	b end
```

  Liga apenas o GPIO17 para indicar que houve uma falha em matar o PWM
``` armasm
fail_kill:
	mov r2, #1
	lsl r2, r2, #17
	ldr r0, =GPIO_BASE
	str r2, [r0, #GPSET0]
	b end
```

Liga apenas o GPIO19 para indicar que houve uma falha em liar o PWM
```armasm
fail_config:
	mov r2, #1
	lsl r2, r2, #19
	ldr r0, =GPIO_BASE
	str r2, [r0, #GPSET0]
	b end
```

### Outros
Temos um loop infinito no final do código
```armasm
end:
	b end
```
E também um loop de delay 
``` armasm
delay:
	ldr r4, =500
delay_loop:
	subs r4, r4, #1
	bne delay_loop
	bx lr
```
