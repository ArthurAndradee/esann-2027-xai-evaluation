# Pré-registro da fase 3: treinar e testar no DDR (replicação num segundo banco)

Data: 2026-11-13. **Congelado** (sha256 em `PREREGISTRO_FASE3.sha256`) com a aprovação do usuário, antes de qualquer treino no DDR. Nenhum modelo tinha sido treinado no DDR no momento do congelamento.

## 1. Pergunta

O efeito de cada filtro sobre o uso das lesões, achado no FGADR, se repete quando a IA é treinada e testada em outro banco de fotos (DDR), com outras câmeras e outra população?

Motivo: a principal limitação do estudo é ter um único banco de treino. As fases 2 e 2b testaram modelos do FGADR no DDR e ficaram inconclusivas porque os modelos transferem mal (AUC 0,60–0,72). Aqui a IA aprende no próprio DDR.

## 2. Dados

- **Fonte:** DDR oficial (Li et al., Information Sciences 2019; CC BY-NC-SA 4.0), zip verificado por SHA-256 contra a distribuição dos autores em 13/11.
- **Preparação** (`experiments/fase3_ddr/preparar_base_ddr.py`): recorte quadrado no campo de visão e redução para 1280 × 1280 px, a resolução do FGADR, para os filtros agirem na mesma escala. Máscaras de lesão (EX, HE, MA, SE) com o mesmo recorte, nas pastas do FGADR. Base em `~/ic/hcpa-retinopathy/ddr_base/`, no formato do FGADR, para o pipeline validado rodar sem mudança de código.
- **Divisão sem vazamento:**
  - treino = graduação/train com grau 0–4 (6.260 fotos);
  - teste = graduação/test com grau 0–4 (3.759) + as 143 fotos de segmentação que estão em graduação/valid (3.902);
  - as fotos de segmentação que estão no treino ficam só no treino;
  - duplicatas exatas treino × teste saem do teste.
- **Base pronta (job 837783):**
  - treino 6.260 fotos (2.812 referáveis, 45%); teste 3.902 (1.808 referáveis, 46%);
  - 0 ilegíveis, 0 duplicatas treino × teste;
  - 427 fotos de segmentação ficaram só no treino.
- **Uso das lesões (A):** medido nas **328** fotos de teste com máscara (EX 185, HE 249, MA 270, SE 186), contra 524 no FGADR.
- **Igual ao FGADR:** sem conjunto de validação (o teste decide a parada do treino), e referável = grau ≥ 2.
- **Ambiente de filtragem:** os 18 datasets filtrados são criados antes, em CPU x86 (venv com OpenCV 4.9.0.80 e NumPy 1.26.4, as versões do container), com os mesmos scripts do pipeline (`preconstruir_datasets.sh`). Num teste com 30 imagens do FGADR, 23 saíram idênticas pixel a pixel ao container ARM; nas outras, no máximo 0,006% dos valores diferem. Os 18 são feitos no mesmo ambiente.

## 3. Condições, redes e treinos

- **Condições:** braço E1 (sem filtro + 17 filtros isolados) = 18.
- **Redes:** EfficientNetV2S, EfficientNetV2B2, InceptionV3, ResNet50, cada uma **com a mesma receita de treino adotada no FGADR**. Não há HPO nova no DDR (seria outra rodada de escolhas); declarado como limitação.
- **Seeds:** 5 por condição e rede (repetições 80–84, 180–184, 280–284, 380–384), em base e pasta de resultados separadas das do FGADR. Escolha do usuário depois do cálculo de poder (seção 7).
- **Total:** 18 × 4 × 5 = **360 treinos**. Protocolo de XAI igual ao da fase 1 (`--protocolo-xai --protocolo-completo`), avaliação em float32.
- **Execução:** `run_trabalhador.sh` com `experiments/campanhas_fase3.conf` (bases em `ddr_base/` e `ddr_home/`, folga de 90 min antes do limite de tempo).

## 4. Pré-condição

Uma rede entra nos testes só se o modelo sem filtro, na média das 5 seeds, tiver **AUC ≥ 0,80 no teste do DDR**. Se menos de 3 redes passarem, as hipóteses ficam **inconclusivas**.

## 5. Hipóteses confirmatórias

ΔA(f, rede) = A(filtro) − A(sem filtro), média das seeds, nas fotos de teste com máscara. Do FGADR usam-se os ΔA da fase 1a (`analise_fase1a/efeitos_por_filtro.csv`), que já estão fixos.

- **H6 · Replicação entre bancos (principal).** Para cada rede apta, Spearman ρ entre os 17 ΔA do FGADR e os 17 ΔA do DDR. **Confirmada se** a média de ρ nas redes aptas for > 0 num teste de permutação dos rótulos de filtro no DDR (10.000 permutações; p < 0,05) **e** ρ > 0 em ≥ 3 redes aptas.
- **H7 · Replicação entre redes no DDR** (a H2, dentro do DDR). Spearman médio dos 17 ΔA entre os pares de redes aptas > 0 por permutação (p < 0,05) **e** todos os pares positivos.
- **H8 · Direção dos filtros-chave no DDR.** Bootstrap hierárquico (seeds e fotos; 10.000), unilateral, Holm entre os 3 testes de cada rede:
  - **H8a:** o CLAHE reduz A;
  - **H8b:** o canal verde aumenta A;
  - **H8c:** os tons de cinza aumentam A.

  Cada uma é confirmada em ≥ 3 redes aptas.

**Exploratório (rotulado):** ΔAUC de cada filtro; H3 não é testável (só 18 condições); análises por tipo de lesão; sanidade e Deletion; comparação com os modelos do FGADR avaliados no DDR (fases 2 e 2b).

## 6. Previsões

- H6 confirmada: ρ entre bancos menor que o 0,88 entre redes no FGADR, mas positivo (aposta: 0,5–0,7), puxado sobretudo pelos filtros destrutivos.
- H7 confirmada.
- H8a confirmada. H8b e H8c incertas: o efeito de tirar a cor se mostrou frágil (receita, escala logit, inversão no DDR).

## 7. Poder (calculado antes de qualquer treino no DDR)

Fonte: `experiments/fase3_ddr/poder_fase3.py` (saída em `poder_fase3.txt` e `poder_fase3.csv`), só com dados da fase 1a e as contagens da base do DDR (328 fotos com máscara).

- k = quanto o erro no DDR é maior que o previsto (1; 1,5; 2).
- escala = tamanho dos efeitos no DDR em relação ao FGADR.

| Hipótese | 3 seeds, k = 1 | 3 seeds, k = 1,5 | 5 seeds, k = 1 | 5 seeds, k = 1,5 |
|---|---|---|---|---|
| H6, ρ verdadeiro 0,5 | 0,64 | 0,66 | 0,66 | 0,65 |
| H6, ρ verdadeiro 0,7 | 0,96 | 0,95 | 0,96 | 0,95 |
| H7 | 1,00 | 0,99 | 1,00 | 1,00 |
| H8a CLAHE reduz (escala 1) | 0,90 | 0,39 | 0,99 | 0,68 |
| H8b verde aumenta (escala 1) | 1,00 | 0,78 | 1,00 | 0,94 |
| H8c cinza aumenta (escala 1) | 0,76 | 0,20 | 0,95 | 0,44 |

Leitura:

- **H6:** o limite é o número de filtros (17 pontos), não o ruído. Mais seeds não ajudam. A H6 detecta bem uma replicação forte (ρ ≥ 0,7; entre redes no FGADR, ρ = 0,85–0,97) e mal uma moderada (ρ = 0,5: 0,6–0,66). Declarado como limitação: um resultado negativo na H6 não exclui uma replicação moderada.
- **H8:** depende das seeds. Com 3, só tem poder se o ruído no DDR for o previsto (k = 1).
- **Número de seeds:** 5 (360 treinos), escolhido pelo usuário em 13/11 antes do congelamento, para a H8 aguentar um ruído no DDR até 1,5× o previsto.

## 8. Ordem de execução

1. Base do DDR preparada (job 837783) e conferida (contagens, alinhamento das máscaras, sem vazamento).
2. Cálculo de poder → aprovação do usuário (5 seeds) → congelamento (sha256).
3. Script de análise escrito e testado só com dados sintéticos → congelado.
4. Datasets filtrados das 18 condições criados antes, em CPU (no máximo 4 ao mesmo tempo, para poupar o disco de rede).
5. Ensaio: 1 treino descartável (repetição 85, fora da análise, resultados em pasta separada `ddr_ensaio/`) para medir o tempo e conferir as saídas.
6. 360 treinos por trabalhadores de GPU → conferência → análise congelada.
