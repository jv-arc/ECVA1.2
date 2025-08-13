# Registradores de Controle de GPIO no Raspberry Pi

O Raspberry pi possui uma série de registradores mapeados na memória que podem ser acessados para controlar o funcionamento dos pinos, temos alguns registradores para dar `set` nos pinos, outro para dar `clear`  nos pinos e outros para controlar o modo de funcionamento.

## Mapeamento na Memória
Os registradores podem ser acessados com endereços de memória que variam com a versão do RaspberrryPi

Os endereços base são:

| Modelo do Raspberry Pi    | Endereço Base GPIO |
| ------------------------- | ------------------ |
| Raspberry Pi 1, Zero      | 0x20200000         |
| Raspberry Pi 2, 3, Zero W | 0x3F200000         |
| Raspberry Pi 4            | 0xFE200000         |
| Raspberry Pi 5            | 0x1F00200000       |
Acessamos os registradores de controle utilizando os endereços junto com um offset, porém temos formas diferentes dependendo do ambiente de programação.

## Baremetal
Podemos acessar os registradores diretamente com um offset do endereço base.

Definição das constantes:
```armasm
.equ GPIO_BASE, 0x3F200000 @ Endereço base dos GPIO no Raspberry Pi 2
.equ GPFSEL1,   0x04       @ Offset do GPFSEL1
.equ GPSET0,    0x1C       @ Offset do GPSET0
.equ GPCLR0,    0x28       @ Offset do GPLCR0
``` 

Que podemos ler e escrever normalemente:

```armasm
ldr r0, =GPIO_BASE      @ Carrega enderço base em r0
ldr r1, [r0, #GPFSEL1]  @ Carrega base + offset em r1
``` 


## Linux
Por conta da virtualização da memória não podemos acessar os endereços diretamente, precisamos fazer uma chamada de sistema para pedir acesso aos endereços.

Definições:
```armasm
.equ GPIO_BASE, 0x3F200000
.equ GPFSEL1,   0x04       

.section .data
    device_file: .asciz "/dev/mem"  @ É o nome do arquvio com acesso a memória
```


Execução da syscall `open`:
```armasm 
    mov r7, #5              @ 5 no r7 identifica a siscall open            
    ldr r0, =device_file    @ nome do arquivo
    mov r1, #2              @ 2 no r1 indica que é leitura/escrita
    mov r2, #0              @ modo como não precisamos usar deixar em 0
    svc #0                  @ chamada do sistema em si
```

Costuma ser bom ter tratamento de erro:
```armasm
    cmp r0, #0           @ verificar se houve erro
    blt error_exit       @ sair se erro (fd < 0)
    mov r4, r0           @ salvar file descriptor em r4
```

O file descriptor é um objeto do sistema operacional que identifica o arquivo aberto. Apesar do arquivo estar aberto precisamos mapear ele na memória do programa

Execução da syscall `nmap`:
```
    mov r7, #192            @ 192 no r7 identifica nmap2
    mov r0, #0              @ 0 significa q o kernel escolhe o endereçamento
    ldr r1, =page_size      @ comprimento (4KB)
    mov r2, #3              @ 3 indica leitura e escrita
    mov r3, #1              @ flags: MAP_SHARED
    mov r5, r4              @ file descriptor q conseguimos no open
    ldr r6, =gpio_base      @ offset do GPIO que queremos mapear
    lsr r6, r6, #12         @ dividir por 4096 para mmap2
    svc #0                         @ chamada do sistema

``` 


Verificação de erros:
``` armasm
    cmp r0, #-1                    @ verificar se mmap falhou
    beq error_close                @ fechar arquivo e sair se erro
``` 


Se tudo estiver correto vc vai ter um ponteiro pros valores em `r0`