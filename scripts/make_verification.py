#!/usr/bin/env python3
"""Gera verification.txt (valor encontrado, esperado, método) a partir dos resultados já gravados. Nada novo é treinado."""
import json
from pathlib import Path

import numpy as np
import pandas as pd

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
A = ["efficientnetv2s", "efficientnetv2b2", "inceptionv3", "resnet50"]
N = ["EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50"]
o = json.load(open(AQUI / "verification_numbers.json"))
h3 = json.load(open(REPO / "experiments/analise_h3/resumo.json"))
f1a = json.load(open(REPO / "experiments/analise_fase1a/resumo.json"))
rob = json.load(open(REPO / "experiments/analise_robustez/resumo.json"))
c = pd.read_csv(AQUI / "accuracy_counts.csv")
t = pd.read_csv(AQUI / "accuracy_tests_all_pipelines.csv")
f = lambda d, k=None: " / ".join(f"{(d[a] if k is None else d[a][k]):.2f}" for a in A)
f3 = lambda d, k=None: " / ".join(f"{(d[a] if k is None else d[a][k]):.3f}" for a in A)
L = []
def sec(titulo, achado, esperado, metodo, ok=None):
    L.append(f"## {titulo}\nEncontrado: {achado}\nEsperado: {esperado}\nMétodo: {metodo}\n" + (f"Situação: {ok}\n" if ok else ""))

L.append("# Verificações (ESANN 2027). Ordem: valor encontrado, valor esperado, método, situação.\n"
         "Redes na ordem EfficientNetV2-S / -B2 / InceptionV3 / ResNet-50.\n")

sec("Otimismo por usar o teste na parada antecipada",
    "0,002 a 0,004 de AUC (baseline 0,914 com validação = teste contra 0,910 com validação interna; CLAHE 0,898 contra 0,896); "
    "menor que o DP entre seeds (~0,007) naquele experimento.",
    "0,002 a 0,004", "Rodada 3 (job 829979, experiments/diagnostico_auprc/CICLO_METODOLOGIA.md, seção 'Viés de validar no teste'): "
    "EfficientNetV2-S treinada com 1.100 imagens nos dois braços, um braço com a validação igual ao teste (como na campanha) e "
    "outro com validação interna separada; vício = AUC(val=teste) − AUC(val interna). Só V2S, baseline e CLAHE; não foi medido nas outras 3 redes.",
    "confere (medido em 2 condições da V2S; extrapolar às outras redes é suposição)")

d = pd.read_csv(REPO / "experiments/analise_h3/por_execucao.csv")
sec("Desvio padrão da AUC entre treinos do mesmo pipeline e entre pipelines",
    "ENTRE TREINOS (DP agrupado de 3 treinos): pipelines com AUC média ≥ 0,85: " + f3(o["sd_auc_within_pooled_pipelines_auc_ge_085"]) +
    f" (agrupado nas 4 redes {np.sqrt(np.mean([v**2 for v in o['sd_auc_within_pooled_pipelines_auc_ge_085'].values()])):.3f}); "
    "pipelines sem nenhum treino colapsado: " + f3(o["sd_auc_within_pooled_sem_colapsados"]) +
    "; todos os 185 (inclui colapsados): " + f3(o["sd_auc_within_pooled"]) + ".  "
    "ENTRE PIPELINES (DP das médias): sem pipelines colapsados: " + f3(o["sd_auc_between_pipelines_sem_colapsados"]) +
    "; todos os 185: " + f3(o["sd_auc_between_pipelines"]) + ".",
    "entre treinos ≈ 0,011; entre pipelines 0,026 a 0,053",
    "AUC por treino (analise_h3/por_execucao.csv). Entre treinos: raiz da média das variâncias dos 3 treinos de cada pipeline. "
    "Entre pipelines: DP (ddof=1) das médias dos pipelines. 'Colapsado' = pipeline com algum treino com AUC < 0,70 ou DP de p(RD) < 0,05.",
    "confere SE as definições forem: entre pipelines = sem pipelines colapsados (0,026 a 0,053); entre treinos ≈ 0,011 = pipelines com AUC média ≥ 0,85. "
    "As outras definições dão valores bem maiores (a Inception e a ResNet-50 colapsam em muitos pipelines); o texto do artigo deve dizer qual.")

r = o["corr_restrita_890_915"]
sec("Correlação entre pipelines restrita a não colapsados com AUC média em [0,89; 0,915]",
    "Spearman " + f(r, "spearman") + " (n = " + " / ".join(str(r[a]["n"]) for a in A) + "); Pearson " + f(r, "pearson"),
    "−0,04 / 0,32 / 0,20 / 0,30 (n = 46 / 70 / 67 / 85)", "Médias dos 3 treinos por pipeline; exclui pipelines com algum treino colapsado; correlação de Spearman entre A e AUC.", "confere exatamente")

d1 = f1a["H1"]["dissociacoes_por_filtro"]
n2 = [k for k, v in d1.items() if v == 2]; n1 = sorted(k for k, v in d1.items() if v == 1)
sec("H1: número de redes em que cada filtro cumpre a regra (dissocia)",
    f"nenhum filtro em 3 ou 4 redes; em 2 redes: {n2}; em 1 rede ({len(n1)}): {n1}; nos demais: 0. H1 NÃO confirmada.",
    "LAB normalization em 2 redes e seis filtros em 1", "Regra: limite inferior do IC 95% de ΔAUC > −0,02 E ΔA < 0 com p unilateral Holm (entre os 17 filtros) < 0,05; "
    "IC por bootstrap de imagens, 3 seeds (analise_fase1a/resumo.json).", "confere (LABNorm 2; BenGraham, Gamma, Gaussian, MaxGreen, Morpho, Unsharp em 1)")

p = f1a["H2"]["pares"]
sec("H2: concordância entre redes dos efeitos dos 17 filtros em A",
    f"média de Spearman {f1a['H2']['media_spearman']:.3f} (faixa {min(p.values()):.3f} a {max(p.values()):.3f}), p de permutação {f1a['H2']['p_permutacao']:.1e}. "
    f"Reteste com a configuração da V2S: InceptionV3 {rob['inceptionv3']['spearman_dA_config_propria_vs_v2s']:.3f}, ResNet-50 {rob['resnet50']['spearman_dA_config_propria_vs_v2s']:.3f} "
    "(Spearman entre ΔA com a configuração própria e ΔA com a da V2S, 17 filtros).",
    "média 0,88 (0,85 a 0,97); reteste 0,90 e 0,89", "Spearman dos 17 ΔA entre cada par de redes; permutação dos rótulos de filtro, 10.000 (analise_fase1a.py; analise_robustez.py).", "confere")

hp, hs = h3["H3_principal"]["por_arquitetura"], h3["H3_sensibilidade_sem_degenerados"]["por_arquitetura"]
sec("H3: entre pipelines menos entre treinos",
    "diferença " + f3(hp, "diferenca") + " (r entre " + f3(hp, "r_entre") + "; r dentro " + f3(hp, "r_dentro") + "); sem colapsados " + f3(hs, "diferenca") +
    " (condições restantes " + " / ".join(str(hs[a]["condicoes"]) for a in A) + ").",
    "0,69 a 0,80; sem colapsados 0,61 a 0,66", "Spearman entre A e AUC das médias de 185 pipelines contra o dos desvios em relação à média do pipeline; IC por bootstrap (analise_h3/resumo.json).", "confere")

g = o["gradcam_auprc_x_auc"]
sec("Grad-CAM: AUPRC contra AUC",
    "Spearman entre pipelines " + f(g, "entre_spearman") + "; entre treinos (desvios) " + f(g, "dentro_spearman") +
    ". (Pearson entre pipelines " + f(g, "entre_pearson") + "; entre treinos " + f(g, "dentro_pearson") + ".)",
    "0,83 a 0,87 entre pipelines; 0,02 a 0,10 entre treinos", "CORRELAÇÃO DE SPEARMAN (a mesma de H3 e S3), AUPRC do Grad-CAM na camada interpretada de cada rede "
    "(V2S, V2B2 e ResNet-50: 2x; InceptionV3: final), média de 524 imagens por treino (secundarias_fase1/por_execucao.csv). Pearson dá 0,85 a 0,89, fora da faixa do artigo.",
    "confere se o texto disser Spearman")

L.append("""## Estudo anterior (ERAMIA): condições, treinos e correlação
Encontrado:
- Artigo submetido ao ERAMIA/RS: **495 condições** de pré-processamento (as que tinham 10/10 repetições na data), EfficientNetV2-S, 10 treinos por condição (4.950 treinos); correlação de Pearson AUC × Dice do Grad-CAM **r = 0,865** (R² = 0,749); AUC × IoU 0,862 (experiments/paper_auc_xai_correlacao/relatorio_completo.md).
- A campanha foi completada depois: **576 condições × 10 repetições = 5.760 treinos** (de 2026-10-02), e a reanálise (experiments/analise_final_576/resumo.json) dá **Pearson AUC × Dice = 0,859** (p < 1e-160) e AUC × Pointing Game 0,825. O baseline sem filtro tem AUC 0,912 e posto 3; o melhor é o LABNorm (0,917, p = 0,23), nenhum acima do baseline após Holm; 466 abaixo.
- Portanto o "0,86" do ESANN corresponde às 576 condições (0,859) e o do artigo do ERAMIA às 495 (0,865). Os slides dizem 576 e 9 ou 10 treinos: 9/10 vem da mini-campanha de 10 filtros (alguns com 9 treinos), não da campanha principal (10/10 em todas as 576).
Esperado: r = 0,86; 576 condições e 9 ou 10 treinos; outra fonte falava em 495.
Método: leitura dos relatórios do próprio repositório; sem recomputar (o arquivo por execução das 5.760 fica em analise_final_576/execucoes_reps0-9.csv).
Situação: as duas contagens existem e as duas estão certas para estudos diferentes; o artigo deve citar 495 para o artigo do ERAMIA e 576 só se for o estudo expandido.
""")

L.append("""## Orçamento de fila do cluster (PCAD) como motivo de não treinar as 576 nas 4 redes
Encontrado: não há nenhum registro no repositório de um "orçamento de fila" formal do PCAD. O que está registrado, e é citável, é: (1) os nós de GPU do contêiner são só grace1 e grace2 (arm64), compartilhados com outros usuários; (2) a prioridade de fila do usuário é baixa (fairshare), então os jobs esperam até dias por um nó (CICLO_METODOLOGIA.md, 2026-10-15 e 2026-10-21); (3) limite de 24 h por job e de 10 jobs submetidos por usuário (QOS). Conta do próprio estudo (não é limite do PCAD): 576 condições × 4 redes × 3 treinos = 6.912 treinos de ~8 min (V2S) a ~19 min (ResNet-50) mais avaliação com protocolo de explicabilidade, contra os 2.220 treinos feitos em 185 pipelines (~15 dias com 1 a 2 GPUs).
Frase sugerida (a ser confirmada pelo usuário): "As GPUs disponíveis eram dois nós compartilhados, com fila longa e limite de 24 h por job; por isso o desenho de 185 pipelines (D-ótimo) substituiu a grade completa de 576 nas quatro redes."
Se o limite exato de horas-GPU for exigido pelo artigo, ele não está nos arquivos: só a administração do PCAD pode informar.
""")

c2 = c.set_index("arch")
L.append("## Acurácia (contagens e testes pareados)\nEncontrado (pipelines filtrados, n = 184 por rede):\n" +
         "\n".join(f"- {N[i]}: AUC média < sem filtro − 0,02 em {int(c2.loc[a].n_auc_below_base_minus_0p02)}; > sem filtro em {int(c2.loc[a].n_auc_above_base)}; "
                   f"melhor: {c2.loc[a].best_filtered_pipeline} {c2.loc[a].best_filtered_auc:.3f} (+{c2.loc[a].best_minus_base:.3f}); "
                   f"significativamente melhores após Holm (184 comparações): {int(c2.loc[a].n_signif_better_holm184)}; piores: {int(c2.loc[a].n_signif_worse_holm184)}; "
                   f"menor p bruto unilateral de melhora: {t[t.arch == a].p_melhor_unilateral.min():.3f}; "
                   f"filtros únicos com IC de ΔAUC todo acima de 0: {int(c2.loc[a].single_filters_ci_all_above_0)}, todo abaixo de 0: {int(c2.loc[a].single_filters_ci_all_below_0)} (de 17)"
                   for i, a in enumerate(A)) +
         "\nEsperado: 155 / 115 / 101 / 87 abaixo; melhores +0,002 / +0,012 / +0,007 / +0,013; 0 filtros únicos acima de zero.\n"
         "Método: ΔAUC = AUC média dos 3 treinos do pipeline − a do sem filtro. IC 95% e p por bootstrap hierárquico pareado (20.000): "
         "imagens de teste (553; 459 referáveis e 94 não, sorteio estratificado, o mesmo para pipeline e sem filtro) e seeds (3, com reposição, independentes entre as duas condições); "
         "p unilateral de 'melhor', Holm entre os 184 pipelines de cada rede. Variante só de imagens (seeds fixas) nas colunas ic_img_* de accuracy_tests_all_pipelines.csv.\n"
         "Situação: contagens e melhores diferenças conferem. NENHUM pipeline é significativamente melhor que o sem filtro em nenhuma rede. "
         "Filtros únicos com IC todo abaixo de zero (hierárquico; só imagens): " +
         " / ".join(f"{int(c2.loc[a].single_filters_ci_all_below_0)} ({int(c2.loc[a].single_filters_ci_img_only_below_0)})" for a in A) +
         ". A cautela é a mesma da fase 1: com 3 treinos o IC hierárquico é largo.\n")
(AQUI / "verification.txt").write_text("\n".join(L))
print("verification.txt gerado")
