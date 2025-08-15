# Controle de Interrupções no Raspberry Pi 2B
O Raspberry Pi 2B faz uso de uma arquitetura de hardware multifacetada para gerenciamento e roteamento de interrupções.

**NOTA:** A documentação do Raspberry Pi 2B não é nem um pouco clara, mas algumas informações puderam ser encontradas nos [[arquivos do kernerl linux]] e também encontramos uma [[implementação]].

Temos 2 sistemas básicos de interrupções que são comumente usados em programação baremetal, um padrão do BCM2836, o LIC e um outro legado do BCM2835, que é utilizado por retrocompatibilidade.

Os periféricos herdados do BCM2835 passam todos por um sistema de controle de interrupção e depois são agregados antes de passar para o controlador do BCM2836.

Também temos o [[GIC-400]], mas ele é mais utilizado para sistemas operacionais e aplicações que precisam de virtualização das funções de interrupção e assim possui um overhead significativo que não torna adequado o seu uso para aplicações mais críticas no tempo.

```
┌───────────┐   
│Periféricos│
│  BCM2835  │
└───────────┘
  │   │   │ ...
  ▼   ▼   ▼
┌────────────┐
│  BCM2835   │
│ Interrupt  │          ┌─────────────┐ 
│ Controller │          │ Periféricos │
│  (legado)  │          │   BCM2836   │
└────────────┘          └─────────────┘
     │ (sinal              │   │   │ ....
     │  agregado)          │   │   │
     ▼                     ▼   ▼   ▼
┌───────────────────────────────────────────────┐   
|   Local Interrupt Controller (LIC) BCM2836    |
|   - Recebe interrupções                       |
|   - Roteia para cores                         |
└───────────────────────────────────────────────┘
     │            │            │            │
     ▼            ▼            ▼            ▼
 ┌───────┐    ┌───────┐    ┌───────┐    ┌───────┐   
 | CPU 1 |    | CPU 2 │    │ CPU 3 │    │ CPU 4 │
 └───────┘    └───────┘    └───────┘    └───────┘
```

Tanto as interrupções de GPIOs quanto as interrupções do ARM Timer passam pelo agregamento legado do BCM2835.
## Interrupções no BCM2835 (legado)
No controlador do BCM2835 temos as interrupções separadas por grupos, cada grupo com o seu ID, para ativarmos um desses grupos basta escrever '1' na posição equivalente nos registradores de controle. 

O controle das interrupções do BCM2835 ficam numa região de memória começando em `0x3F00B200`, estamos mais interessados nos registradores `IRQs_ENABLEx` que controlam os IDs de interrupção de 0 à 63.

| Nome         | Offset | IRQs  |
| ------------ | ------ | ----- |
| IRQs_ENABLE1 | 0x10   | 0-31  |
| IRQs_ENABLE2 | 0x14   | 32-63 |

### Setando o Registro
Temos 64 IRQ-IDs e obviamente não dá pra decorar ou explicar tudo aqui, a questão que é relevante pro projeto são os GPIOs e o ARM Timer. Os GPIOs recebem IRQ-IDs em grupos, assim precisamos identificar qual GPIO queremos para saber qual IRQ-ID setar para por fim saber qual bit de que `IRQ_ENABLERx` setar.

Os GPIOs de 0 à 31 recebem o ID 49, como 49 é maior que 32, usamos o IRQ_ENABLE1, como também 49-32 é 17, para ativar as interrupções dos GPIO de 0 à 31, escrevemos 1 no bit 17 do registrador.

O ARM Timer é nitidamente mais fácil, seu ID é 0, assim basta escrever 1 no bit 0 do IRQs_ENABLE_1.

| IRQ-ID | Interrupção     | Registro     | Bit |
| ------ | --------------- | ------------ | --- |
| 0      | ARM TImer       | IRQs_ENABLE1 | 0   |
| 49     | GPIOs de 0 à 31 | IRQs_ENABLE2 | 17  |
| 50     | GPIOs de 0 à 31 | IRQs_ENABLE2 | 18  |

### Um exemplo:

```armasm

.equ BCM2835_INT_BASE, 0x3F00B200
.equ IRQs_ENABLE2,     0x14
....

@ Copia valor orginal
ldr r0, =BCM2835_INT_BASE
ldr r1, [r0, #IRQs_ENABLE2]

@ Gera novo valor
mov r2, #0b1
lsl r2, r2, #17
orr r1, r1, r2

@ Escreve de volta na memória
str r1, [r0, #IRQs_ENABLE2]

```

## BCM2836 Local Controller (LIC)
É o sistema específico do BCM2836 e é o hardware padrão para interrupções no sistema.  O **local controller** recebe, agrega, controla e roteia as interrupções de diversos tipos no dispositivo incluindo os do BCM2836. 

Para configurar isso adequadamente precisamos tanto **habilitar** as interrupções corretas e depois **rotear** elas para um core.

O bloco dos registros de configuração do LIC ficam a partir de `0x40000000.

### Habilitação
Assim como antes precisamos identificar qual tipo de interrupção deve ser habilitada, no LIC temos um registrador por core, cada um com o seu offset.

| Core | Offset |
| ---- | ------ |
| 0    | 0x60   |
| 1    | 0x64   |
| 2    | 0x68   |
| 3    | 0x6C   |

Cada um desses registros deve ser controlado escrevendo 1 no tipo de interrupção desejada.

| Bit | Nome           | Descrição                    |
| --- | -------------- | ---------------------------- |
| 0-3 | Generic TImers | Physcal, Virtual, Hypervisor |
| 4-7 | Mailboxes      | Comunicação inter-core       |
| 8   | GPU IRQ        | Periféricos BCM2835          |
| 9   | PMU IRQ        | Performance Monitor Unit     |
| 11  | Local Timer    | Timer dedicado BCM2836       |
**TODAS** as interrupções do controlador legado são agregadas no sinal "GPU IRQ".

### Roteamento
A pesar de todos os cores poderem ser configurados para receber qualquer interrupção, as interrupções legadas do BCM2835 devem ser diretamente roteadas para apenas um dos cores. Assim só um core pode "ouvir" essas interrupções por vez.

Para controlar isso usamos o registro no offset `0x0C` do LIC. Nele o controle é bem simples, apenas os dois primeiros bits são usados.

Para rotear as interrupções basta escrever no registro o número do core desejado.

| Roteia para: | Valor em 0x4000000C |
| ------------ | ------------------- |
| Core 0       | 00                  |
| Core 1       | 01                  |
| Core 2       | 10                  |
| Core 3       | 11                  |

### Exemplo
```armasm

.equ LIC_BASE,      0x40000000
.equ IRQs_CORE0,    0x60
.equ GPU_IRQ_ROUT,  0x0C
....
@ Posicao base em comum
ldr r0, =LIC_BASE

@ Carrega IRQ do core 0
ldr r1, [r0, #IRQs_CORE0]

@ Escreve valor de GPU_IRQ para Core 0
mov r2, #0b1
lsl r2, r2, #8
orr r1, r1, r2
str r1, [r0, #IRQs_CORE0]

@ Escreve valor de Core 0 no GPU_IRQ_ROUT
mov r1, #0
str r1, [r0, #GPU_IRQ_ROUT]

``` 