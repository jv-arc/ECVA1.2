# PWM no Raspberry Pi 2
## Canais e Multiplexação
No raspberry pi 2 temos dois canais de PWM que podem ser multiplexados para 4 GPIOs distintos, isso significa que podemos escolher quais GPIO que queremos utilizar cada um dos dois canais 

| Canal | GPIOs   | Pinos físicos |
| ----- | ------- | ------------- |
| PWM0  | 12 e 18 | 32 e 33       |
| PWM1  | 13 e 19 | 12 e 35       |

Isso nos dá flexibilidade para selecionar os GPIOs que me melhor se encaixam no projeto. Para multiplexar um canal para um GPIO basta utilizar [GPFSEL](registradores-gpfsel-raspberry-pi-controle-pinos-gpio-com-assembly.md) correspondente na função alternativa "ALT5", ou seja, com o valor `010`.

## Registradores de Controle PWM
Temos vários registradores mapeados na memória para controlar o funcionamento dos canais PWM, eles seguem em sequência a partir da posição de memória `0x20C000`.

### Controle - PWM_CTL `0x00`
Esse registrador liga e desliga os canais PWM e define seus modos de operação. Ele precisa ser setado mesmo que o GPFSEL equivalente esteja configurado.

### Status - PWM_STA `0x04`
É um registrador com várias flags de controle dos PWM, na maioria dos casos basta zerar antes da execução do programa para evitar que tenha lixo que atrapalhe o uso.

### Data - PWM_DAT1 `0x14` e PWM_DAT2 `0x24`
São o controle direto do sinal transmitido pelo PWM, o PWM_DAT1 controla o canal 1 (PWM0) e PWM_DAT2 controla o canal 2 (PWM0).

O data quando junto com o range pode controlar o duty cycle do canal.

### Range - PWM_RGN1 `0x10` e PWM_RGN_2 `0x20`
São registradores que controlam o "range" dos canais, o PWM_RGN1 controla o range do canal 1 (PWM0) e PWM_RGN2 controla o range do canal 2 (PWM1). O range é um controle da resolução do PWM, em conjunto com o controle de clock, o range determina a switching frequency dos canais.

###  Clock e Divisor de Clock - PWMCLK_CNTL `0xA0` e PWMCLK_DIV `0xA4`
São registradores que controlam o clock dos canais PWM. ???????


## Tabela
os registradores ficam assim em ordem em relação ao endereço base `0x20C000`

| Registrador | Offset | Função           |
| ----------- | ------ | ---------------- |
| PWM_CTL     | `0x00` | Controle         |
| PWM_STA     | `0x04` | Status           |
| PWM_RNG1    | `0x10` | Range PWM0       |
| PWM_DAT1    | `0x14` | Data PWM0        |
| PWM_RNG2    | `0x20` | Range PWM1       |
| PWM_DAT2    | `0x24` | Range PWM1       |
| ...         |        |                  |
| PWMCLK_CNTL | `0xA0` | Clock            |
| PWMCLK_DIV  | `0xA4` | Divisor de Clock |

