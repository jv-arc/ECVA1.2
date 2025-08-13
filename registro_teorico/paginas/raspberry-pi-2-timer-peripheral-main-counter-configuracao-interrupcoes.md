# ARM Timer - Main Counter no Raspberry Pi 2
Além da contagem incremental com pooling usando o system timer. O raspberry pi 2 possui um componente chamado de **ARM Timer**, que fornece funcionalidades de temporização, ele possui dois contadores, o free timer que é incremental e serve para contar intervalos de tempo e o **main timer** que é decremental e pode ser configurado para gerar interrupções de forma periódica.

## Visão Geral do Funcionamento

De forma simplista o sistema tem um comportamento de contagem decremental, onde carregamos um valor no registrador que será decrementado em um certo período de tempo até se atingir o zero. Ao atingir o zero o sistema pode ser configurado para gerar uma interrupção de hardware. O período de tempo entre os decréscimos pode ser configurado para aplicações diferentes.

## Mapeamento na Memória
Temos uma série de registradores mapeados na memória que nos ajudam a utilizar o sistema. Esses registradores ficam mapeados em ordem a partir da posição `0x3F00B400`.

### Explicação das funções

**TIMER_LOAD**: nesse registrador podemos escrever o valor que será decrementado, se por exemplo, escrevermos 10, o timer vai contar de 10 até 0 em intervalos determinados de tempo.

**TIMER_VALUE**: nesse registrador podemos ler o valor atual da contagem, é útil para debbugging e outras aplicações.

**TIMER_CONTROL**: Nesse registrador podemos controlar o funcionamento do timer. Com sinais de enable para o timer, geração de interrupção e também para controlar o **preescaler**.

**TIMER_IRQ_CLR**: É uma flag interna que é automaticamente setada para 1 quando o ARM Timer gera uma interrupção.

### Tabela Resumindo
Os seguintes registradores são posicionados a partir do offset `0x3F00B400`.

| Registrador   | Offset | Função                             |
| ------------- | ------ | ---------------------------------- |
| TIMER_LOAD    | 0x00   | Seta o contador                    |
| TIMER_VALUE   | 0x04   | Lê o contador                      |
| TIMER_CONTROL | 0x08   | Configura o ARM Timer              |
| TIMER_IRQ_CLR | 0x0C   | Indica que uma interrupção ocorreu |

## Funcionamento do TIMER_CONTROL
O **TIMER_CONTROL** é um registrador no qual podemos escrever as configurações do **ARM Timer**. Alguns dos bits são reservados ou são para o funcionamento do free timer e não do **main timer** do qual estamos interessados.

| Bits | Nome             | Função                               |
| ---- | ---------------- | ------------------------------------ |
| 31-8 | xxx              | xxx                                  |
| 7    | TIMER_ENABLE     | habilita e desabilita o timer        |
| 6    | xxx              | xxx                                  |
| 5    | INTERRUPT_ENABLE | habilita e desabilita interrupção    |
| 4    | xxx              | xxx                                  |
| 3-2  | PRESCALE         | controla o período entre decrementos |
| 1    | COUNTER_32BIT    | 1=32 bits, 0=16 bits                 |
| 0    | xxx              | xxx                                  |

### Prescaler e Controle do Intervalo dos Decrementos
O **preescaler** é um valor que divide ou "escala" os decrementos com base no clock, seguindo a fórmula
$$
\text{frequência do contador} = \frac{\text{CLOCK}}{\text{PREESCALER}}
$$
Os valores do **preescaler** podem ser escolhidos com os bits 3 e 2 e assim dividem o clock do **ARM Timer** que é de 250MHz.

| Bit 3 | Bit 2 | Valor do Prescaler | frequência do contador |
| ----- | ----- | ------------------ | ---------------------- |
| 0     | 0     | 1                  | 250MHZ                 |
| 0     | 1     | 16                 | ~15MHz                 |
| 1     | 0     | 256                | ~977kHz                |
| 1     | 1     | 1                  | 250MHz                 |

Assim se tivermos um TIMER_CONTROLLER configurado com PREESCALER=01, o valor de TIMER_LOAD será decrementado em: 
$$\frac{250MHz}{16}  \approx 15MHz$$

Um outro exemplo com interrupção seria um TIMER_LOAD=44, com o PREESCALER=10, temos que as interrupções vão ocorrer em:
$$\frac{250MHz}{44*256} \approx 22kHz$$

## Cuidados com o TIMER_IRQ_CLR
O TIMER_IRQ_CLR é uma flag interna usada pelo **ARM Timer** que indica que foi ele que gerou a interrupção , ela é setada em 1 quando a interrupção é gerada e ela continua setada em 1 indicando ao hardware que foi ativado até que seja restaurada. 

Isso significa que ao gerar uma interrupção **PRECISAMOS** limpar essa flag, caso contrário **o sistema vai acreditar que a interrupção não foi tratada** 

Pra isso basta fazer uma leitura dela.
## Sobre as interrupções
É importante notar que mesmo que o componente **ARM Timer** esteja adequadamente configurado ainda é necessário configurar o GIC-400 para que as interrupções sejam recebidas e também um interrupt handler apropriado para a aplicação.