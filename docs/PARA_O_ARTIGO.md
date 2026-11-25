# Entrega para a sessão que escreve o artigo ESANN 2027

Só fatos, números e arquivos. O texto do artigo é do usuário. Tudo vem de resultados já gravados; nada foi inventado.
Gerado em 2026-11-17. Pasta: `hcpa/esann_materiais/`.

## 1. Figuras e tabela finais (largura 12,17 cm; atualizado em 2026-11-25)

Arquivos em `figuras_finais/` (nomes iguais aos do LaTeX). Fonte de todas as figuras: Latin Modern Roman 10 (a Computer Modern do artigo), com ρ, ≥, ■, ●, ▲ do Latin Modern Math; única exceção, o marcador ★ da Figura 4 (DejaVu Sans). Paleta das Figuras 3 e 4: azul `#1f4e8c`, vermelho `#b03a2e`, verde `#1e7a4c`, roxo `#6a3d9a`. A Figura 8 antiga foi descartada.

| Arquivo | O que mostra | Fatos para a legenda |
|---|---|---|
| `fig1_lesion_reliance.pdf` (3,0 cm) | Método: exame, máscara das lesões, Grad-CAM, lesões borradas (D), controle borrado (E) | Exame 1172_1.png (teste, grau 2). EfficientNetV2-S sem filtro, treino 0, Grad-CAM na camada 2× (19×19). Borrão gaussiano σ = 10 px a 299 px, máscara dilatada 3×3. Controle = as mesmas formas deslocadas para uma área sem lesão. p original 0,866; com lesões borradas 0,573; com controle borrado 0,854; A = p(E) − p(D) = 28,1 pontos. |
| `fig2_pipeline.pdf` (2,55 cm) | Pipeline em 4 etapas com um exemplo: Retinex → Green channel → CLAHE → Gaussian (nome do filtro sobre cada imagem), mesmo exame da Figura 1 | 576 = (5+1)(3+1)(2+1)(7+1) combinações (a fórmula saiu da figura; vai no texto). Essa cadeia é uma das 576. **Não aparece na figura:** 185 pipelines treinados (18 = sem filtro + 17 isolados; 150 D-ótimos; 20 de validação sorteados; 3 sobreposições) e 2.220 modelos (185 × 4 redes × 3 treinos). |
| `fig3_filters.pdf` (10,2 cm) | Mudança de A (% do A sem filtro) por filtro e rede: barras divergentes (vermelho = queda, azul = aumento), agrupadas pelas 4 etapas | % de mudança = 100 × A(filtro)/A(sem filtro) − 100; barra = média de 3 treinos, linha com extremos = ± 1 desvio padrão dos 3 treinos (só 3 treinos: indicação, não IC). A sem filtro (pontos): 11,5 / 7,6 / 7,4 / 9,9 (EffNetV2-S / B2 / InceptionV3 / ResNet-50). **Frangi, Canny e Otsu destroem o conteúdo da imagem** (AUC média 0,61 / 0,72 / 0,84): vale uma nota na legenda. |
| `fig4_auc_reliance.pdf` (8,0 cm) | (a) AUC × A entre pipelines; (b) desvios dentro do pipeline | Legenda única (nomes e símbolos das 4 redes); o ρ de **Spearman** está dentro de cada painel, ao lado do símbolo. Entre pipelines (185): 0,77 / 0,73 / 0,81 / 0,84. Entre os 3 treinos de um pipeline: 0,08 / 0,03 / 0,05 / 0,04. **Em (a) cada ponto é a AUC média de 3 treinos de um pipeline (o eixo diz só "AUC").** Retas de mínimos quadrados (tendência; a relação em (a) é curva: A perto de zero até AUC ≈ 0,8 e depois sobe; o ρ não depende do ajuste); em (b) o ajuste usa só a janela \|ΔAUC\| ≤ 0,05 (pipelines colapsados puxariam a reta). O ρ restrito (AUC 0,89 a 0,915: −0,04 / 0,32 / 0,20 / 0,30; n = 46 / 70 / 67 / 85) não está na figura (`dados/correlations_ladder.csv`). |
| `tabela_chains/` (`tabela_chains.tex` + `images/pipeline1..5.png`) | Tabela no lugar da antiga Figura 5: mesma AUC, A diferente (2 menores, sem filtro, 2 maiores) | Entre os 27 pipelines com AUC média das 4 redes a ±0,01 da do sem filtro (0,910; A = 9,1): A de 4,2 a 14,1 pontos. Ben Graham→CLAHE→Gaussian 0,903 / 4,2; AHE→Gaussian 0,903 / 4,3; LABNorm→Green channel→Median 0,901 / 12,7; LABNorm→Grayscale 0,904 / 14,1. Selecionados depois dos dados (post hoc). |

**A Figura 3 antiga virou tabela:** `dados/tabela_redes.tex`. As figuras de tipo de lesão (antiga 8) e a antiga 7 foram descartadas; os dados por tipo de lesão continuam em `dados/lesion_type.csv`.

## 2. Resultados confirmatórios e exploratórios (fonte: `esann_figs/verification.txt`)

- **H1 (algum filtro mantém a AUC e reduz A em ≥ 3 redes): não confirmada.** LABNorm cumpre a regra em 2 redes; BenGraham, Gamma, Gaussian, MaxGreen, Morpho e Unsharp em 1.
- **H2 (concordância entre redes dos efeitos dos 17 filtros em A): confirmada.** Spearman médio 0,88 (faixa 0,85 a 0,97), p < 1e-4. Reteste com a configuração da V2S: InceptionV3 0,90 e ResNet-50 0,89.
- **H3 (a AUC se relaciona com A entre pipelines, não entre treinos): confirmada nas 4 redes.** Diferença das duas correlações de 0,69 a 0,80; sem pipelines colapsados, 0,61 a 0,66.
- **Pipelines com AUC média em [0,89; 0,915] e sem colapso:** ρ = −0,04 / 0,32 / 0,20 / 0,30 (n = 46 / 70 / 67 / 85).
- **Acurácia:** pipelines filtrados com AUC média abaixo da do sem filtro − 0,02: 155 / 115 / 101 / 87 (de 184). Melhor pipeline filtrado acima do sem filtro: +0,002 / +0,012 / +0,007 / +0,013. **Nenhum é significativamente melhor** (bootstrap hierárquico pareado, 20.000 reamostragens, Holm sobre 184 comparações por rede; menor p bruto unilateral 0,044, na EfficientNetV2-B2).
- **Grad-CAM:** correlação de Spearman entre AUPRC e AUC entre pipelines 0,83 a 0,87; entre treinos 0,02 a 0,10. Com Pearson dá 0,85 a 0,89 (fora da faixa citada).
- **Desvios padrão da AUC:** entre pipelines, excluindo os pipelines colapsados, 0,026 a 0,053; entre treinos do mesmo pipeline, ≈ 0,011 **apenas** para pipelines com AUC média ≥ 0,85 (0,008 a 0,011 por rede). Com todos os pipelines os valores são bem maiores (InceptionV3 e ResNet-50 colapsam em muitos).
- **Viés de validar no teste (parada antecipada):** 0,002 a 0,004 de AUC, medido só na EfficientNetV2-S (baseline e CLAHE), com treino reduzido. Não foi medido nas outras 3 redes.

## 3. Validação externa no DDR (fase 2b: modelos treinados no FGADR, avaliados no DDR)

- **H4, H5a e H5b: NÃO AVALIÁVEIS.** Pré-condição: AUC do sem filtro no DDR ≥ 0,70 em ≥ 3 redes. Só a InceptionV3 passa.
- AUC sem filtro no DDR (IC 95%): EfficientNetV2-S 0,654 [0,624; 0,682]; V2-B2 0,603 [0,581; 0,624]; InceptionV3 0,717 [0,680; 0,756]; ResNet-50 0,643 [0,584; 0,703]. No FGADR, 0,904 a 0,917.
- Imagens: AUC em 3.759 (1.690 referáveis, 2.069 não); A em **756** imagens com máscara (não 757: uma das 757 não tem máscara de nenhum dos 4 tipos).
- Na InceptionV3 (única apta, descritivo): CLAHE reduz A (ΔA −3,8 pontos, IC [−5,5; −2,0], vale pela regra); Green channel e Grayscale **também reduzem** (−4,1 e −3,7 pontos), o oposto do FGADR, com perda de AUC (−0,088 e −0,142).
- Desvios registrados: a fase 2 original (reps 40–49, AUC no DDR 0,652 a 0,682) usou interpolação errada (D5); a fase 2b refez os 160 treinos, **decidida depois de ver a pré-condição falhar**, e isso precisa constar. D7: A também em escala logit, sem divergência. Causa provável do desempenho baixo: domínio e critério de graduação (AUC por grau: grau 0 contra 3 = 0,91; contra 2 = 0,66), e não a interpolação. Detalhes em `esann_figs/ddr_notes.txt`.
- DDR verificado contra o download oficial (SHA-256, 7.891 arquivos idênticos; licença oficial CC BY-NC-SA 4.0; citar Li et al., Information Sciences 501, 2019, 511–522).

## 4. Escolhas e limitações a declarar

- O exame do ERAMIA (0361_1.png) foi descartado porque o controle caía 29% sobre lesão anotada e o A dessa imagem era negativo. Em toda a base, só 36% das imagens têm controle sem sobreposição com lesão anotada.
- O exame da Figura 1 tem A = 28,1 pontos, o dobro da média; ilustra o efeito, mas não é típico. Média de A nas 524 imagens: 11,5 pontos nas execuções da campanha (3 treinos) e 13,3 no modelo da Figura 1.
- ERAMIA: o artigo submetido usou **495 condições** (r de Pearson AUC × Dice = 0,865); a campanha completa tem **576 condições × 10 treinos** (r = 0,859).
- O orçamento de fila do PCAD não está registrado como um limite formal; o que está registrado são dois nós de GPU compartilhados, fila longa e limite de 24 h por job.
- dA e IC de dA da Figura 4 vêm da fase 1a (bootstrap só de imagens, como pré-registrado; não inclui a variação entre treinos).

## 5. Fase 3 (treinar e testar no próprio DDR): CONCLUÍDA em 2026-11-19

Arquivos: `dados/fase3_resumo.json`, `dados/fase3_efeitos_por_filtro_ddr.csv`, `dados/fase3_PREREGISTRO.md`. Pré-registro e análise congelados (sha256 conferido, sem alteração) antes de qualquer treino; a análise rodou sozinha, sem ajuste depois de ver dados.

- **Desenho:** 18 condições (sem filtro e 17 filtros isolados) × 4 redes × 5 seeds = 360 treinos, todos concluídos, nenhuma falha. Treino com 6.260 fotos do DDR, teste com 3.902 (328 com máscara de lesão para medir A). Mesma receita de treino do FGADR (sem nova busca de hiperparâmetros), parada antecipada no teste, imagens reduzidas a 1280 px. Poder pré-calculado: H6 ≈ 0,65 se o ρ verdadeiro for 0,5 e ≈ 0,95 se for 0,7 (limitado pelos 17 filtros, não pelas seeds).
- **Pré-condição (AUC do sem filtro no DDR ≥ 0,80): as 4 redes passam.** EffNetV2-S 0,875; V2-B2 0,885; InceptionV3 0,908; ResNet-50 0,895.
- **H6 (ordem dos 17 filtros no DDR igual à do FGADR): NÃO confirmada.** ρ por rede 0,58 / 0,23 / 0,20 / 0,23 (média 0,31), p de permutação 0,087; os 4 ρ são positivos. Resultado negativo não exclui uma replicação moderada (poder ≈ 0,65 nesse cenário).
- **H7 (concordância entre as redes no DDR): confirmada.** ρ médio 0,86 (pares de 0,74 a 0,93), p < 0,0001.
- **H8 (direção dos filtros-chave, bootstrap hierárquico, Holm entre os 3 testes de cada rede): NENHUMA confirmada.** H8a CLAHE reduz A: 0 de 4 redes. H8b canal verde aumenta A: 2 de 4. H8c tons de cinza aumentam A: 0 de 4. Critério: ≥ 3 de 4.

| Filtro | Rede | ΔA (pontos) [IC 95%] | p ajustado (Holm) | ΔAUC |
|---|---|---|---|---|
| CLAHE | EffNetV2-S / V2-B2 / InceptionV3 / ResNet-50 | +0,03 [−2,11; 2,21] / +0,92 [−1,44; 3,32] / +4,62 [−3,46; 11,83] / +7,90 [2,20; 13,54] | 0,51 / 0,78 / 0,88 / 0,997 | −0,033 / −0,024 / −0,026 / −0,010 |
| Canal verde | idem | +2,77 [0,85; 4,65] / +3,02 [1,33; 4,76] / +4,27 [0,07; 9,04] / +3,69 [0,01; 7,76] | 0,006 / 0,001 / 0,071 / 0,075 | −0,004 / +0,001 / −0,013 / +0,007 |
| Tons de cinza | idem | +0,76 [−0,95; 2,47] / +0,62 [−0,81; 2,02] / +0,48 [−3,52; 5,18] / +0,80 [−1,93; 3,56] | 0,39 / 0,40 / 0,88 / 0,55 | −0,017 / −0,005 / −0,009 / +0,009 |

  Os ICs são sem ajuste; o p ajustado por Holm é o que decide. O canal verde aumenta A nas 4 redes (+2,8 a +4,3), mas passa em Holm só nas duas EfficientNets. O CLAHE não reduz A no DDR (na ResNet-50 ele aumenta, o oposto da previsão); a única redução consistente é a de AUC (−0,010 a −0,033).
- **Declarar:** a fase 3 responde a uma pergunta diferente da validação externa da seção 3 (lá, modelos treinados no FGADR; aqui, treinados no DDR). Não houve nova HPO no DDR; o limiar de parada é o teste (como no FGADR).

## 6. O que NÃO existe (não inventar)

FLOPs e tempo de treino por execução (Figura 3); qualquer confirmação de H4/H5; texto da Figura 7.

## 7. Arquivos de dados (em `dados/`)

`filter_effects_wide.csv` (Figura 4), `pipelines_summary.csv` e `pipelines_long.csv` (todos os 185 pipelines), `chains_similar_auc.csv` (Figura 6), `correlations_ladder.csv`, `lesion_type.csv` (Figura 8), `ddr_results.csv`, `ddr_resumo.txt`, `ablation_per_image.csv`, `design_185.csv`, `networks.csv`, `exames_escolhidos.csv`, `tabela_redes.tex`. Verificações numéricas completas: `../esann_figs/verification.txt` e `../esann_figs/ddr_notes.txt`.

## 8. Sobreposição do controle com as lesões anotadas e sensibilidade (adicionado depois)

Arquivos: `dados/control_overlap_per_image.csv`, `dados/control_overlap_resumo.txt`, `dados/control_overlap_sensibilidade.csv`; a coluna `ctrl_overlap_pct` foi acrescentada a `dados/ablation_per_image.csv`. O controle de cada imagem é o mesmo em todas as execuções (rng(0), mesma ordem das 524 imagens).

- **Sobreposição do controle com lesão anotada** (% da área do controle): mediana 0,96%; Q1 0,00%; Q3 3,65%; máximo 56,8%.
  - Sobreposição 0: 35,5% das imagens (186). ≤ 5%: 83,6% (438). > 20%: 2,7% (14).
- **Controle fora do campo de visão:** mediana 1,37%; 12,0% das imagens têm mais de 5% fora. Só 46,8% dos controles mantêm a forma intacta (sem pixels cortados ao deslocar).
- A sobreposição cresce com a quantidade de lesão (Spearman 0,78 entre a área da máscara e a sobreposição): as imagens com mais lesão têm menos área livre para o controle.
- **Sensibilidade (só as 438 imagens com sobreposição ≤ 5%, contra as 524):** nenhum veredito muda.
  - A médio sem filtro (pontos), 524 → 438 imagens: EffNetV2-S 11,5 → 10,6; V2-B2 7,6 → 7,9; InceptionV3 7,4 → 7,4; ResNet-50 9,9 → 10,0.
  - **H2** segue confirmada: ρ médio entre redes 0,878 → 0,917 (pares de 0,890 a 0,968).
  - **H3** segue confirmada nas 4 redes: diferença (ρ entre − ρ dentro) de 0,69 a 0,80 → 0,71 a 0,81; sem pipelines colapsados, 0,61 a 0,66 → 0,63 a 0,69.
  - O cálculo com as 524 imagens reproduz exatamente os números já reportados (H2 0,878; H3 0,69 a 0,80). O IC de H3 aqui usa 2.000 reamostragens (não 10.000).
- Limitação a declarar: em parte das imagens (16% têm sobreposição > 5%) o controle cai sobre lesão anotada, o que subestima A nessas imagens; o subconjunto exclui justamente as imagens com mais lesão, então o nível de A não é comparável entre os dois conjuntos, só a ordem dos filtros e as correlações.

## 9. Decomposição de A e robustez à escala (adicionado em 2026-11-22)

Arquivos: `dados/A_decomposicao.csv` (por rede e condição: p original médio, queda pelas lesões, queda pelo controle, A em pontos, A em logit), `dados/A_decomposicao_resumo.txt`, script `make_decomposicao_A.py`. Fonte: ablações da campanha (alvo "todas", 524 imagens, 3 treinos).

- **A = média de [ p(controle borrado) − p(lesões borradas) ]**, em pontos de probabilidade (1 ponto = 0,01); é a diferença queda_lesão − queda_controle.
- **O efeito dos filtros em A vem da queda causada pelas lesões, não do controle.** Exemplo, EfficientNetV2-S: queda pelas lesões 10,7 (sem filtro), 1,4 (CLAHE), −0,8 (AHE), 13,4 (canal verde); o controle fica entre −3,9 e −0,3 nesses casos.
- **Queda do controle** (negativa: borrar o controle costuma subir p um pouco): sem filtro −0,8 / −2,4 / −1,9 / −0,9 (EffNetV2-S / B2 / InceptionV3 / ResNet-50). Nos 17 filtros: EfficientNetV2-S −12,9 a +3,4 (−6,0 a +0,5 sem Frangi/Canny/Otsu); B2 −9,7 a −0,6 (−3,7 a −0,6); InceptionV3 −1,7 a −0,2; ResNet-50 −1,8 a +0,6. O controle soma de 1 a 6 pontos a A; no B2 sem filtro são 2,4 dos 7,6 pontos. **Não use "−3 a +0,6" para todos os filtros: esse intervalo vale só para CLAHE, AHE, canal verde, cinza, Gaussian e Median.**
- **Escala logit:** A recalculado em logit (p limitado a [10⁻⁴, 1 − 10⁻⁴]) mantém a ordem dos 17 filtros: Spearman entre A em pontos e A em logit 0,95 / 0,93 / 0,97 / 0,99 (EffNetV2-S / B2 / InceptionV3 / ResNet-50). A probabilidade original média é parecida entre os filtros não destrutivos (0,69 a 0,83), então o efeito não vem de redes mais ou menos confiantes.
- **O que A não prova:** o borrão não remove a lesão; A baixo significa pouca dependência do detalhe das regiões anotadas, não que a rede ignora as lesões.

