# Problema ao modificar a vector table
Se você tiver prestado atenção em (sis prog)[https://upload.wikimedia.org/wikipedia/commons/d/d4/Galvao_Bueno_2007_Desafio_Internacional_das_Estrelas.jpg] você deve ter percebido um problema com o processo de programar um handler customizado.... **Como modificar a vector table?**

Não dá para simplesmente escrever lá. Fazer algo como:
```armasm
ldr r0, =VECTOR_TABLE
str r1, [r0]
```
só vai retornar um erro no montador.

Nesse exemplo, "VECTOR_TABLE" é uma **label** isso significa que ela **não existe no espaço de memória**. As labels são abstrações em linguagem de monetagem para facilitar a programação, elas são resolvidas pelo montador antes de produzir código objeto. Assim, só podemos referenciar labels se elas estiverem disponíveis para o linker, seja quando nós mesmos programamos, ou quando importamos.

Para resolver isso temos duas alternativas, dar instruções específicas no **linker** de como linkar o código, ou utilizar o **VBAR** um registrador do Raspberry Pi 2B que indica a posição da vector table.

O VBAR é um registrador do coprocessador de boot especificamente do RPi 2B, outras versões possuem registradores diferentes com endereços e funcionamentos distintos.

O linker é um programa que gera uma imagem para o raspberry pi que indica exatamente como carregar as informações para a RAM. O linker prepara o código e o loader durante a execuçãos faz o resto.
