---
type: theory
domain: ["#Eletronica/Microcontroladores", "#Ciencia_da_Computacao/Sistemas_Embarcados", "#Ciencia_da_Computacao/Arquitetura_de_Computadores"]
topic: ["#Vector_Table/ARM", "#Interrupcoes/Gerenciamento", "#GIC_400/Funcionamento"]
lateral: ["#Raspberry_Pi_2B", "#x86_comparacao", "#GICC_IAR", "#GICC_EOIR", "#register_banking", "#subs_pc_lr_4", "#atomicidade", "#handler_IRQ", "#FIQ"]
state: normal
---

# Vector Table e Interrupções em Sistemas ARM | Raspberry Pi 2B
O conceito de vector table e interrupções deve ser bem claro da disciplina de [[sistemas operacionais]], MAS... É bom dar uma olhada como isso funciona especificamente em sistemas ARM.
## Relembrando a Vector Table
A vector table é uma estrutura de dados de extrema importância que direciona as exceções/interrupções do sistema para programas específicos, os "handlers", eles tem a responsabilidade de "tratar" do evento, salvando o contexto do processador, executando funções e por fim devolvendo o controle para o processo anterior.

A vector table acaba sendo uma lista bem grande de posições de memória ou de jumps que levam o processador para o handler específico para cada situação.

Se queremos adicionar funcionalidades específicas para o processador ao interagir com sinais de hardware devemos escrever handlers especiais para o projeto.
## Diferenças entre ARM e x86
Nos sistemas x86 temos uma tabela GIGANTESCA de handlers (mais de 200), nesses sistemas a posição na tabela é determinada **diretamente pelo tipo**, cada tipo diferente de interrupção tem uma entrada diferente na tabela e assim um handler diferente. Isso é bem diferente da situação no RPi 2B.

No Raspberry Pi e nos processadores ARM no geral temos um esquema diferente. Temos somente DUAS entradas na vector table para interrupções, uma para as interupções normais (IRQ) e outra para as "interrupções rápidas" (FIQ), e dessa forma, temos somente dois handlers de interrupção. Dessa forma o tratamento de tipos diferentes de interrupção deve ser feito pelo **mesmo handler**.

O handler da interrupção no ARM fica responsável por identificar a interrupção utilizando o registrador [[interrupt-controller-gic-400-raspberry-pi-2b-arquitetura-registradores|GICC_AIR]] e executar um branch ou qualquer outra coisa para tratar a interrupção específica.

### Vector Table Enxuta no ARM
Por conta das interrupções se concentrarem em só dois handlers a vector table no ARM fica um pouco mais vazia, tendo bem menos handlers.

| Offset | Nome           | Descrição                               |
| ------ | -------------- | --------------------------------------- |
| 0x00   | Reset          | Power-on/reset button                   |
| 0x04   | Undefined      | Instrução inválida                      |
| 0x08   | SVC            | Instrução `svc` para syscalls e outros` |
| 0x0C   | Prefetch Abort | Erro ao buscar instrução                |
| 0x10   | Data Abort     | Erro ao acessar dados                   |
| 0x14   | Reserved       | Não faz nada, sempre `nop`              |
| 0x18   | IRQ            | **interrupções **                       |
| 0x1C   | FIQ            | **Interrupções rápidas**                |

## Estrutura Geral de um Handler IRQ
Um handler no ARM precisa necessariamente obedecer a estrutura:
- Salvar contexto necessário
- Identificar a interrupção lendo GICC_AIR
- Executar ações relevantes
- Marcar a interrupção como finalizada escrevendo no GICC_EOIR
- Restaurar contexto anterior
- Devolver execução

É sempre bom lembrar que no ARM os registradores são [[processadores-arm-modos-operacao-interrupcoes-register-banking-conceitos|banqueados]] nos modos FIQ e IRQ e que o endereço de retorno é **salvo automaticamente** em `lr`. Outra coisa digna de nota: o GICC_EOIR apenas indica que a interrupção foi resolvida, ele não restaura o contexto e nem retorna para a função anterior.

## Destrinchando a Estrutura
Vamos ver um mock de um handler para IRQ no ARM.
### Na Vector Table
É bom dar uma olhada depois em como mudar a vector table mas por enquanto é bom ver que ela fica basicamente alguma coisa assim:
```armasm
vector_table:
	b _start
	b undefined_handler
	b svc_handler
	b prefetch_handler
	b data_handler
	nop
	b irq_handler     @ Nosso alvo
	b fiq_handler
```

### Iníciar e Guardar Contexto
É aqui que o handler começa
```armasm
irq_handler:
	push {r0-r2}
```
Salvamos só os registradores que vamos usar para evitar perder tempo, `r13` e `r14` são salvos automaticamente por conta do banqueamento.

### Descobrindo qual Interrupção
Usamos GICC_IAR para identificar qual interrupção que aconteceu (É bom guardar direito)
```armasm
ldr r0, =GICC_BASE
ldr r1, [r0, #GICC_IAR]
```
Lembrando que GICC_BASE é em `0x40002000` e GICC_IAR fica num offset de `0x10`

### Pula para o Tratamento Específico
Podemos fazer uma série de comparações para pular para uma subrotina específica que resolva a interrupção que carregamos de GICC_IAR.
```armasm
...
cmp r1, #96    @96 é o número do timer
beq handle_timer_interrupt
cmp r1, #81    @81 é o número de GPIO
beq handle_gpio_interrupt
...
b finish_irq
```
Se a interrupção não se enquadrar em nenhuma categoria ele só pula para o fim do handler.

### Execução do Handler
É aqui que rola a magia, pode configurar GPIO, resetar Timer e o escambau.
```armasm
handle_xxx_interrupt:
....
```

### Marcando a Interrupção como concluída
Escrevemos em GICC_EIOR para indicar que a interrupção foi finalizada, precisamos escrever exatamente o valor lido de GICC_AIR para finalizar a interrupção
```armasm
ldr r0, =GICC_BASE
str r1, [r0, #GICC_EIOR]
```
Se escrever o valor errado o GICC não identifica a interrupção como finalizada.

### Restaurando o contexto
Restauramos exatamente o contexto que salvamos antes
```armasm
pop {r0-r2}
```
Não esquecer do banqueamento!!!!
### Retorno da Execução
É nesse ponto aqui que o handler devolve a execução ao ponto antes da interrupção
```arasm
subs pc, lr, #4
```
É crucial notar que o ARM sempre salva em `lr` o endereço depois daquele em que estava antes do chaveamento.

Se o processador estava executando na posição `0x400` e ocorre uma troca de contexto, seja por conta de uma interrupção ou por conta de um branch mesmo, o endereço salvo em `lr` acabaria sendo `0x404`. Isso funciona muito bem numa chamada de subrotina. 

```arasm
0x400   bl subrotina
0x404   add r0, r0, r1

subrotina:
0x600   push {r0-r3}
.....   ....
0x700   bx lr   @Volta 
```
Depois de sair de `0x400` é para `0x404` que a instrução `bx lr` deve levar o processador. Isso é uma **decisão de projeto**! Apesar disso ser o ideal na chamada de subrotinas isso não funciona direito para o handler.

Se utilizassemos `bx lr` voltaríamos para o endereço errado.
```arasm
0x400   cmp r1, r2     <- ocorre a interrupção
0x404   add r0, r0, r1 <- para onde volta

handler:
0x600   push {r0-r3}
.....   ....
0x700   bx lr          <- Volta incorretamente 
```
Se a interrupção ocorresse quando `pc=0x400` a instrução em `0x400` seria interrompida (ah vá) mas o `lr` tá apontadando para `0x404`isso significa que ao retornar a instrução em `0x400` não seria executada 🤔

A solução é bem simples, fazemos o retorno para o endereço `lr` -4, como no ARM temos acesso a esses registradores podemos escrever diretamente:
```arasm
subs pc, lr, #4
```
assim garantimos que a instrução que foi interrompida seja executada.