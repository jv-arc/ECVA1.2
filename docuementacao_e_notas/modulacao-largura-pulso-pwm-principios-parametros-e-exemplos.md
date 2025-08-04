---
type: theory
domain: ["#Eletronica/Sinais"]
topic: ["#Modulacao_Largura_Pulso/Funcionamento_Parametros"]
lateral: ["#sinal_analogico_digital", "#constante_tempo", "#filtragem_sinal", "#exemplos_graficos", "#duty_cycle", "#resolucao", "#exemplo_8_bits"]
state: normal
---

# PWM (Pulse Width Modulation)
É uma técnica para produzir sinais analógicos (ou quase isso) controlando um sinal digital ao longo do tempo.

## Princípio Básico de Funcionamento
A ideia básica do PWM é que boa parte dos sistemas físicos e, mais especialmente dispositivos eletrônicos, não distinguem sinais de mesma potência em intervalos muito curtos de tempo.

Como todos tem uma determinada constante de tempo, nenhum desses sistemas podem reagir instantaneamente à variações na entrada. Esse comportamento funciona basicamente como um filtro que suaviza os sinais enviados.

Contanto que você esteja operando na frequência adequada para a constante de tempo do sistema, é possível simular um sinal de qualquer tensão utilizando um sinal de ligado e desligado com potência equivalente.

## Exemplos

Um sinal que passa 1/4 do tempo em 5V tem a mesma potência que um sinal que fica constante em 1.25V. um sinal que passa 1/2 do tempo, a potência de 2.5 V e 3/4 do tempo tem a mesma potência que um de 3.75V

#### PWM 25% (0.25ms 5V, 0.75ms 0V)
```
┌───┐               ┌───┐                   5V         
│   │               │   │               
│   │               │   │               
│   │               │   │               
│   │               │   │                   
|───┼───────────────┼───└───────────────|   0V
|   │               │   
0   0.25ms          1ms                 2ms
``` 


#### Constante (1ms 100% 1.25V)
```
                                            5V



┌───────────────────────────────────────┐   1.25 V         
│                                       |
|───────────────────────────────────────|   0V
|                                       |   
0                                       2ms
```

#### PWM 50% (0.5ms 5V, 0.5ms 0V):
```
┌──────────┐            ┌──────────┐                5V         
│          │            │          │               
│          │            │          │               
│          │            │          │               
│          │            │          │                   
|──────────┼────────────┼──────────└────────────|   0V
|          │            │          
0          0.5ms        1ms                     2ms
``` 

#### Constante (1ms 100% 2.5V)
``` 
                                                    5V


┌───────────────────────────────────────────────┐   2.5 V         
│                                               |
│                                               |
|───────────────────────────────────────────────|   0V
|                                               |   
0                                               2ms
``` 


#### PWM 75% (0.75ms 5V, 0.25 ms 0V):
```
┌────────────────┐      ┌────────────────┐          5V         
│                │      │                │               
│                │      │                │               
│                │      │                │               
│                │      │                │                   
|────────────────┼──────┼────────────────└──────|   0V
|                │      │                
0                0.75ms 1ms                     2ms

```


#### Constante (1ms 100% 3.75V):
```
                                                    5V

┌───────────────────────────────────────────────┐   3.75 V         
│                                               |
│                                               |
│                                               |
|───────────────────────────────────────────────|   0V
|                                               |   
0                                               2ms
``` 


## Parâmetros do PWM
Temos uma série de parâmetros que definem o comportamento do PWM e assim são os nossos alvos na modulação de sinais com a técnica.

### Período e Switching Frequency
O período é a quantidade total de tempo de um ciclo completo de ligar e desligar, isto é o tempo em low somado com o tempo em high.
```
|---------- 1ms (período completo) ----------|
|-------- 0.75ms ON --------|-- 0.25ms OFF --|
```

A switching frequency em contrapartida é o inverso do período.

### Duty Cycle e Resolução
O duty cycle é a proporção em que o sinal fica em high comparado ao período total do ciclo. Já a resolução é a granularidade que conseguimos controlar o duty cycle, ela normalmente é resultado das tecnologias específicas sendo utilizadas, como a frequência de clock e o número de bits no contador usado.

Num sistema em que só podemos contar intervalos de tempo com 8 bits, só podemos contar 256 partições de tempo dentro do intervalo do ciclo completo, isso significa que o sistema não consegue setar um valor num intervalo de tempo menor.

```
# Número de subsdivisões
8 bits - > 2^8 = 256 valores possíveis (0, 1, 2, .... 255)

# Resolução
1/256 -> 0.39%
```

Isso significa que o nosso duty cycle só pode ser de múltiplos de 0.39% e assim os períodos de ON e OFF só podem ser de múltiplos de 0.39% do período.  

É perceptível a importância do duty cycle no PWM, é através dele que conseguimos controlar diretamente a onda de saída e assim a tensão do sinal.

