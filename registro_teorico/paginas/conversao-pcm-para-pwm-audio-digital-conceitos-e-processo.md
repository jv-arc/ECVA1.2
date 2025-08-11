# Conversão PCM para PWM
## Modelos de Áudio e Intuição
Aprendemos desde pequenos sobre como os sons são ondas mecânicas cujo o meio é o ar. Fizemos exercícios no ensino médio sobre batimento, resolvemos problemas no vestibular, provas nas disciplinas de Física 2 na Poli e muito mais. O problema é que esse tipo de modelo é contraprodutivo para entender a conversão.

Nos modelos que estudamos desde sempre as ondas são funções periódicas em todo eixo real (normalmente o tempo), desde o menos infinito até o mais infinito. Essa descrição é claramente oposta à nossa experiência cotidiana. No dia a dia percebemos sons tendo começo, meio e fim, sendo bem localizados no tempo. 

É claro que não existe uma contradição matemática, sabemos muito bem disso por conta da disciplina de sinais, onde vimos como transformar pulsos em sobreposições infinitas de ondas com a transformada de Fourier. A percepção real limitada no tempo e a descrição com ondas infinitas é completamente compatível matematicamente, porém um desses pontos de vista vai te ajudar a entender a conversão de PCM para PWM e o outro não.

Para termos uma noção sólida do funcionamento do PWM é muito mais útil entender o som dessa forma, como uma série de pulsos com amplitude e comprimento definidos e não como ondas no plano cartesiano (a pesar de que a descrição no domínio ser útil para analises mais avançadas de áudio.

## PCM (Pulse Code Modulation)
É uma técnica fundamental para converter sinais analógicos em digitais, muito usada para áudio e vídeo.

Temos 3 etapas fundamentais na codificação:
- **Amostragem**: o sinal analógico é medido em intervalos regulares no tempo.
- **Quantização**: cada amosta é convertida para o valor digital mais próximo disponível
- **Codificação**: Os valores quantizados são convertidos em sequências de bits 

Temos dois valores fundamentais no PCM. A **taxa de amostragem** determina com que frequência o sinal analógico é amostrado (para áudio é comum usar 44,1 kHz) e a **profundidade de bits** determina quantos bits são usados para representar as amostras (com uma profundidade de 16 bits é possível representar 65.536 valores diferentes de intensidade de som)

## Relembrando PWM

?????
## Processo de Conversão
?????