# ECVA1.2
**Embedded Control Vector Audio 1.2**

O ECVA1.2 (pronuncia-se "essevai, dois") é um projeto experimental de reprodução de áudio através do PWM do Raspberry Pi 2B. O propósito foi realizar experimentos e aprender sobre diversas tecnologias na placa e outros conceitos relacionados ao desenvolvimento de baixo nível em assembly ARM A32.

A aplicação consiste em três módulos principais, um script para converter arquivos de áudio, um para de fato realizar a reprodução da música usando os recursos no raspberry pi e por fim um para ligar tudo na montagem.

O script de conversão faz uso das bibliotecas numpy, pydub e audioop-tls para converter arquivos de áudio de quase qualquer formato em dados direto em assembly. O sistema reprodução faz uso de uma série de recursos do BCM2836, como o registrador VBAR, o gerenciador de interrupções GIC-400, handlers de interrupção customizados e é claro o sistema de PWM da placa. A integração é feita no geral com uso de makefile e dos scripts de linkagem do GNU Linker (LD). 

---

Os textos produzidos estão divididos em grupos conforme a origem e utilidade para o projeto. 

Temos textos de:
- [Documentação](documentacao/indice.md): Onde se encontram detalhes de como usar a aplicação.
- [Registro Teórico](registro_teorico/indice.md): Onde se encontram informações teóricas sobre os recursos utilizados para o desenvolvimento.
- [Registro Experimental](registro_experimental/indice.md): Onde se encontram registros sobre códigos intermediários que foram produzidos para testes ao longo do desenvolvimento.

