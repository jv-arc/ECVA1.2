# Geração de Interrupções no Raspberry Pi 2B
O Raspberry Pi 2B faz uso de uma arquitetura de hardware multifacetada para gerenciamento e roteamento de interrupções.

##  Sistemas Para Baremetal
Temos 2 sistemas de interrupções principais usados em programação baremetal, um padrão do BCM2836, e um outro para retrocompatibilidade com o BCM2835.

Os periféricos herdados do BCM2835 passam todos por um sistema de controle de interrupção e depois são agregados antes de passar para o controlador do BCM2836.

```
┌───────────┐   
│Periféricos│
│  BCM2835  │
└───────────┘
  │   │   │
  ▼   ▼   ▼
┌────────────┐
│  BCM2835   │        ┌─────────────┐ 
│ Interrupt  │        │ Periféricos │
│ Controller │        │   BCM2836   │
└────────────┘        └─────────────┘
    │ (agregado)         │   │   │
    ▼                    ▼   ▼   ▼
┌────────────────────────────────────────┐   
|        Local Controller BCM2836        |
└────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐   
|           Roteamento BCM2836           |
└────────────────────────────────────────┘
     │         │         │         │
     ▼         ▼         ▼         ▼
 ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐   
 | CPU 1 | | CPU 2 │ │ CPU 3 │ │ CPU 4 │
 └───────┘ └───────┘ └───────┘ └───────┘
```

### BCM2836 Local Controller
É o sistema específico do BCM2836 e é o hardware padrão para interrupções no sistema.  O **local controller** recebe, agrega, controla e roteia as interrupções de diversos tipos no dispositivo incluindo os do BCM2836. 

| Bit | Nome           | Descrição                    |
| --- | -------------- | ---------------------------- |
| 0-3 | Generic TImers | Physcal, Virtual, Hypervisor |
| 4-7 | Mailboxes      | Comunicação inter-core       |
| 8   | GPU IRQ        | Periféricos BCM2835          |
| 9   | PMU IRQ        | Performance Monitor Unit     |
| 11  | Local Timer    | Timer dedicado BCM2836       |

### Periféricos BCM2835
Temos um sistema de hardware para gerenciamento de interrupções diretamente do BCM2835, que gerencia todas as interrupções herdadas dele.

Esse sistema controla interrupções de periféricos que já haviam no Raspberry Pi 1.

## GIC-400
É uma interface de hardware que alguns sistemas operacionais precisam. Hypervisores precisam de interfaces para virtualizar recursos. O GIC-400 fornece isso.

O GIC-400 também fornece recursos de priorização, gerenciamento de energia e outros. Porém esses recursos vem com um overhead que pode não ser adequado em sistemas baremetal.

