# Interrupt Controller (GIC-400) | RPi 2B
O "Generic Interrupt Controller" é um componente de hardware que centraliza as informações de interrupção que são enviadas para o processador. Ele recebe as interrupções dos vários dispositivos do sistema e envia para o processador.

Pode receber interrupções de:
- GPIO
- UART
- SPI
- etc.

## Arquitetura Geral
O processo de recebimento de interrupções no Raspberry Pi 2B, funciona mais ou menos da seguinte forma
```
Periféricos → [DISTRIBUTOR] → [CPU INTERFACE] → CPU Core
  Timer         (prioriza)      (mascara)        (executa)
  GPIO          (roteia)        (acknowledge)     (handler)
  UART          (gerencia)      (end-of-IRQ)     
```

Isso é importante para evitar conflitos entre sinais de múltiplas interrupções que chegariam simultaneamente, além de criar uma priorização e rotear os sinais para diferentes cores em sistemas mais complexos como o RPi 2B.

O GIC-400 fica dividido em 2 partes o **ditributor** e a **CPU Interface (GICC)**
### Distributor (GICD)
Tem como responsabilidade receber todas as interrupções dos dispositivos, priorizar as interrupções de 0 (maior prioridade) até 255 (menor prioridade, agrupar interrupções em categorias e rotear as interrupções para a **cpu interface** de um dos cores.
### CPU Interface (GICC)
Tem como responsabilidade filtrar as interrupções com base na prioridade atual da CPU, trocar o modo IRQ/FIQ para o core especifico no momento certo, fornecer o ID da interrupção em questão e por fim gerenciar o recebimento e fim das interrupções

## Registradores do GIC-400
### Registradores do distributor
Os registradores ficam mapeados na memória a partir do endereço `0x40001000`

| Offset      | Nome             | tamanho    | Função                              |
| ----------- | ---------------- | ---------- | ----------------------------------- |
| 0x000       | GICD_CTLR        | 32 bits    | Controle Geral                      |
| 0x100-0x11C | GICD_ISENABLERx  | 32x8 bits  | Habilita interrupções especificas   |
| 0x180-0x19C | GICD_ICENABLERx  | 32x8 bits  | Desabilita Interrupções específicas |
| 0x400-0x4FC | GICD_IPRIORITYRn | 8x128 bits | Prioridade de cada interrupção      |
| 0x800-0x8FC | GICD_ITARGETSRn  | 8x128 bits | CPU alvo para cada interrupção      |

### Registradores do CPU Interface
Esses ficam mapeados a partir do `0x40002000`

| Offset | Nome      | Função                      |
| ------ | --------- | --------------------------- |
| 0x00   | GICC_CTLR | Controle geral da Interface |
| 0x04   | GICC_PMR  | Filtro pela prioridade      |
| 0x0C   | GICC_IAR  | Acknowledgement ID          |
| 0x10   | GICC_EOIR | End of interrupt            |

## Separações Diferentes....
Tem um funcionamento curioso desses subsistemas que me confundiu na primeira vez que eu li mas agora eu entendo melhor, pq tem uma separação entre habilitar e desabiltar as interrupções e oq é o aknowledgement ID e o End of Interrupt?

### GICD_ISENABLERx vs GICD_ICENABLERx
No lugar de escrever 0 e 1 em um registrador como o GPFSEL, a configuração das interrupções individuais é feita em dois registradores. Você escreve 1 na posição específica do GICD_ISENABLERx para ligar uma interrupção e escreve em 1 na posição do GICD_ICENABLERx para desligar essa interrupção. Escrever 0 neles não faz nada.

ISSO É FEITO PARA MANTER A ATOMICIDADE DAS CONFIGURAÇÕES! GENIAL 🙃

### IAR e EOIR
Alguns sistemas tem a identificação da interrupção e a finalização da interrupção num sistema só, mas no RPi 2B eles ficam separados. Isso permite que uma interrupção comece a ser tratada e não termine, sendo interrompida por outra coisa. Dessa forma podemos tratar interrupções de forma paralela.

Ler de GICC_IAR automaticamente faz a interrupção passar de "pendente" para "ativa" mas a interrupção só se torna "finalizada" ao escrever em GICC_EOIR.

## Roteiro Geral do GIC-400 Durante uma Interrupção
### 1. Periférico gera interrupção
   - 1a. Sinal vai para o GICD

### 2. Distributor recebe o sinal  
   - 2a. Consulta prioridade (GICD_IPRIORITYRn)
   - 2b. Consulta se está habilitada (GICD_ISENABLERn)  
   - 2c. Consulta CPU alvo (GICD_ITARGETSRn)

### 3. CPU Interface recebe interrupção
   -  3a. Filtra prioridade (GICC_PMR)
   -  3b. Se passar no filtro coloca ID no GICC_IAR
   -  3c. Sinaliza IRQ para o CPU core

### 4. CPU Core recebe sinal IRQ
   -  4a. Consulta vector table → chama irq_handler  
   -  4b. Handler lê GICC_IAR → descobre ID da interrupção
   -  4c. Executa ISR específica baseado no ID
   -  4d. Escreve ID no GICC_EOIR → finaliza
