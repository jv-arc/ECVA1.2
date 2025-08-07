---
type: theory
domain: ["#Eletronica/Sistemas_Embarcados", "#Ciencia_da_Computacao/Arquitetura_de_Computadores", "#Ciencia_da_Computacao/Programacao_de_Baixo_Nivel"]
topic: ["#Vector_Table/Modificacao", "#ARM/Interrupcoes", "#Raspberry_Pi/Boot_Process"]
lateral: ["#VBAR", "#linker_script", "#baremetal", "#x86_comparacao", "#labels_assembly", "#coprocessador_video"]
state: draft
---

# Modificando a Vector Table
Se você tiver prestado atenção em [[sis prog]] você deve ter percebido um problema com o processo de programar um handler customizado.... **Como modificar a vector table?**

Não dá para simplesmente escrever lá. Fazer algo como:
```armasm
ldr r0, =VECTOR_TABLE
str r1, [r0]
```
só vai retornar um erro no montador.

"VECTOR_TABLE" é uma **label** isso significa que ela **não existe no espaço de memória**. As labels só existem no código em linguagem de montagem e são resolvidas pelo montador antes de produzir código objeto. Assim, só podemos referenciar labels no código que nós mesmos programamos (ou importamos).

Para resolver isso temos duas alternativas, dar instruções específicas no **linker** de como linkar o código, ou utilizar o **VBAR** um registrador do Raspberry Pi 2B que indica a posição da vector table

## Usando o VBAR
O VBAR é um registrador do coprocessador de boot especificamente do RPi 2B, outras versões possuem registradores diferentes com endereços e funcionamentos distintos.

Para usar o VBAR precisamos:
- Comunicação com o coprocessador de vídeo, que é o responsável pelo boot no RPi 2B.
- Alinhamento da vector table na memória

### Comunicando com o Coprocessador
???????
## Usando o Linker
O linker gera uma imagem para o raspberry pi que indica exatamente como carregar as informações para a RAM. O linker prepara o código e o loader faz o resto.

Para usar o Linker precisamos:
- Exportar os pontos de acesso no código fonte
- Escrever o script de linkagem que mapeia as labels para as posições de memória
????????????