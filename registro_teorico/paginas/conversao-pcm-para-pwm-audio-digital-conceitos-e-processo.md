# Conversão PCM para PWM

## Modelos de Áudio e Intuição
Aprendemos desde pequenos sobre como os sons são ondas mecânicas cujo o meio é o ar. Fizemos exercícios no ensino médio sobre batimento, resolvemos problemas no vestibular, provas nas disciplinas de Física 2 na Poli e muito mais. O problema é que esse tipo de modelo é contraprodutivo para entender a conversão.

Nos modelos que estudamos desde sempre as ondas são funções periódicas em todo eixo real (normalmente o tempo), desde o menos infinito até o mais infinito. Essa descrição é claramente oposta à nossa experiência cotidiana. No dia a dia percebemos sons tendo começo, meio e fim, sendo bem localizados no tempo. 

É claro que não existe uma contradição matemática, sabemos muito bem disso por conta da disciplina de sinais, onde vimos como transformar pulsos em sobreposições infinitas de ondas com a transformada de Fourier. A percepção real limitada no tempo e a descrição com ondas infinitas é completamente compatível matematicamente, porém um desses pontos de vista vai te ajudar a entender a conversão de PCM para PWM e o outro não.

Para termos uma noção sólida do funcionamento do PWM é muito mais útil entender o som dessa forma, como uma série de pulsos com amplitude e comprimento definidos e não como ondas no plano cartesiano a pesar de que a descrição no domínio ser útil para analises mais avançadas de áudio.

## PCM (Pulse Code Modulation)
É uma técnica fundamental para converter sinais analógicos em digitais, muito usada para áudio e vídeo.

Temos 3 etapas fundamentais na codificação:
- **Amostragem**: o sinal analógico é medido em intervalos regulares no tempo.
- **Quantização**: cada amosta é convertida para o valor digital mais próximo disponível
- **Codificação**: Os valores quantizados são convertidos em sequências de bits 

Temos dois valores fundamentais no PCM. A **taxa de amostragem**, que determina com que frequência o sinal analógico é amostrado (para áudio é comum usar 44,1 kHz) e a **profundidade de bits**, que determina quantos bits são usados para representar as amostras (com uma profundidade de 16 bits é possível representar 65.536 valores diferentes de intensidade de som)

## Relembrando PWM
No PWM utilizamos pulsos repetidamente de largura variada, produzindo sinais equivalentes à amplitudes específicas modulando a largura do pulso. Os parâmetros em questão aqui são:
- **Duty Cycle**: Que está diretamente relacionado a largura do pulso
- **Switching Frequency**: Que determina a frequência com a qual os pulsos se repetem.
- **Resolução**: A unidade mínima (em percentual) que podemos incrementar o duty cycle.

## Processo de Conversão

### Básicos da Codificação PCM
Pode variar um pouco com a implementação, mas normalmente os valores de PCM são centrados no zero, assim para uma certa profundidade de bits temos o valor mínimo:
```math
\text{min} = -(2^{(\text{profundidade de bits} -1)} -1)
```
e o valor máximo:
```math
\text{max} = 2^{\text{profundidade de bits} -1}
```

Ou seja, num PCM com 16 bits de profundidade, os valores variam de $-(2^{15}) = -32.767$ até $2^{15} = 32.768$. Se esses valores ocorrerem numa taxa de amostragem de 44.100 Hz, significa que temos uma amplitudes de $-32.767$ à $32.768$ a cada 22,676 milhonésimos de segundo.

### Convertendo Parâmetros
Acho que é bem intuitivo entender como a **switching frequency** do PWM é a mesma que a **taxa de amostragem** do PCM, a tradução consiste basicamente em traduzir amplitude por amplitude em cada instânte de tempo em valores de largura para os mesmos instantes de tempo. Assim para realizarmos a conversão de PCM para PWM basta normalizar os valores da amplitude para valores de **duty cycle**, usando a resolução e a profundidade.

Em primeiro lugar precisamos de valores positivos para o PWM (já que não existe duty cycle negativo), surpreendentemente, basta somar o oposto do valor mínimo aos valores de amplitude do PCM. Se o PCM em questão tem $-32.767$ como mínimo, se somarmos $32.767$ em todos os valores de amplitude vamos ter todos os valores deslocados para um range positivo, indo de $0$ até $65.535$, que é $2^{16}-1$.

Com os valores todos positivos podemos fazer uma regra de três simples para encontrar o **duty cycle** equivalente. Como o **duty cycle** vai de 0% à 100% que equivale à $\text{resolução}$ até $n*\text{resolução}$, assim podemos fazer:

```math
\text{range} = \text{resolução} * \frac{1}{100} * \frac{\text{amplitude}}{\text{2^{\text{profundidade de bits}}-1}}
```

### Considerações Sobre Valores Positivos
Uma coisa que talvez tenha incomodado o leitor mais atento é o fato de termos só deslocado os valores PCM para uma região positiva. Ora, os valores negativos de PCM representam valores em módulo bem altos de amplitude, um valor de PWM próximo de 0 não parece traduzir isso muito bem né? A solução está no uso inteligente do sinal PWM produzido. Como discutido antes, o PWM se aproveita da resposta em frequência da saída para produzir o sinal desejado, se utilizarmos um filtro passa baixas a saída do PWM se aproxima da média da saída. 

Um passa baixas funciona basicamente realizando:
```math
v_{\text{output}}(t) = \frac{1}{T} \int \text{PWM}(t) \ \mathrm{dt}
```
ISSO É EXATAMENTE A MÉDIA DO SINAL 🤪

Dessa forma, se o PWM varia de 0V até 5V, os sinais produzidos ficam por volta de 2,5V e quando um sinal próximo de 0 é produzido, temos na realidade um desvio na amplitude da média para baixo, efetivamente produzindo uma amplitude negativa!

