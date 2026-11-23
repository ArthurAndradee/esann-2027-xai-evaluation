#!/usr/bin/env python3
"""Gera LEIAME.txt e RELATORIO.txt de esann_materiais/ (lista de arquivos, divergências, escolhas, alturas, pendências)."""
from pathlib import Path
import pandas as pd
AQUI = Path(__file__).resolve().parent; FIG = AQUI / "figuras"
pdfs = sorted(p.name for p in FIG.glob("fig*_v*_h*cm.pdf"))
exec_rep = (FIG / "relatorio_execucao.txt").read_text() if (FIG / "relatorio_execucao.txt").exists() else "(sem relatório de execução)"
erros = [l for l in exec_rep.splitlines() if "ERRO" in l]
ddr = (AQUI / "dados/ddr_resumo.txt").read_text() if (AQUI / "dados/ddr_resumo.txt").exists() else "DDR: dados/ddr_resumo.txt NÃO foi gerado (ver logs/esann_dados_*.log)."
div = (AQUI / "dados/divergencias_dados.txt").read_text() if (AQUI / "dados/divergencias_dados.txt").exists() else ""
L = ["LEIAME: esann_materiais/ (gerado automaticamente; tudo vem de resultados já gravados, nada treinado nem inventado)\n",
 "dados/        CSVs e textos (ddr_results.csv, ddr_resumo.txt, filter_effects_wide.csv, pipelines_long.csv, pipelines_summary.csv, lesion_type.csv,",
 "              chains_similar_auc.csv, correlations_ladder.csv, design_185.csv, ablation_per_image.csv, networks.csv, chains_exemplares.csv, exames_escolhidos.csv)",
 "paineis/      imagens (exames, Grad-CAM, borrões, filtros, cadeias passo a passo)",
 "figuras/      figN_vX_hY.Ycm.pdf (vetorial), .png (300 dpi), _gray.png (tons de cinza) e contact_figN.png (todas as versões lado a lado, mesma escala)",
 "exame_escolhido.txt  exame e modelo usados; relatorio_execucao.txt (erros e textos que não couberam); RELATORIO.txt (resumo final); FASE3_STATUS.txt",
 "Reproduzir: sbatch esann_materiais/rodar_dados.sh; depois, nesta pasta, Rscript make_figuras_v3.R (R em ~/Rlibs, fonte Liberation Serif em ~/.fonts).",
 "Verificações numéricas do v2: esann_figs/verification.txt e esann_figs/ddr_notes.txt.\n", f"{len(pdfs)} PDFs de figura:"] + ["  " + p for p in pdfs]
(AQUI / "LEIAME.txt").write_text("\n".join(L) + "\n")
R = ["RELATORIO (esann_materiais), gerado automaticamente\n",
 "== 1. Erros na geração das figuras ==", "\n".join(erros) if erros else "nenhum", "",
 "== 2. DDR (Parte 1) ==", ddr,
 "== 3. Divergências entre valores encontrados e esperados ==",
 "- Figura 4: todas as células conferidas com a tabela do prompt; diferenças ≤ 1 ponto (máximo 0,5; Grayscale na EfficientNetV2-B2 dá 139,5 contra 140).",
 "- Tipos de lesão (Figura 8): AHE e CLAHE em exsudatos −62% e −56% (confere), canal verde em hemorragias +66% (confere).",
 "- DDR: 756 imagens com máscara (esperado 757); validade falhou (só a InceptionV3 ≥ 0,70) → H4, H5a, H5b NÃO AVALIÁVEIS; por isso só a 7B foi feita (7A em extras_nao_pedidos/).",
 "- Spearman, H1, H2, H3, contagens de acurácia e cadeias de AUC parecida: iguais ao esperado (ver esann_figs/verification.txt). Desvio entre treinos ≈ 0,011 só vale para pipelines com AUC média ≥ 0,85.",
 "- Figura 3: sem FLOPs e sem tempo de treino por execução (não registrados); parâmetros são do backbone Keras sem topo. Recomendo TABELA, não figura.",
 div, "",
 "== 4. Escolhas ==",
 "- Exame principal 1172_1.png (teste, grau 2): o do ERAMIA (0361_1.png) foi descartado (controle 29% sobre lesão anotada, A = −29 pontos). Regra em exame_escolhido.txt.",
 "- Grade 1E: o principal + 1 exame por grau 2, 3 e 4 (regra relaxada em exame_escolhido.txt). Modelo dos painéis: baseline-0.keras (V2S sem filtro, treino 0); o gráfico pareado 1B e as médias vêm dos treinos da campanha (20-22).",
 "- Cadeias exemplares: BenGraham>CLAHE>Gaussian (A 4,2), LABNorm>GreenChannel>Median (A 12,7) e uma de 4 estágios de AUC parecida (A mediano); 6C usa as 2 menores e 2 maiores de AUC parecida.",
 "- Famílias de filtros (4E) e asterisco da Figura 8 (significativo em ≥ 3 de 4 redes) são decisões minhas.",
 "- dA e IC de dA na Figura 4 vêm da fase 1a (bootstrap só de imagens, como pré-registrado).", "",
 "== 5. Alturas recomendadas (orçamento de 6 páginas) ==",
 "Conjunto mínimo (18,4 cm): 1A 2,6 + 2A 3,2 + 4A 5,1 + 5A 4,3 + 7B 3,2. Conjunto confortável (26,2 cm): 1B 3,8 + 2A 3,2 + 4A 5,1 + 5A 4,3 + 6A 4,0 + 7B 3,2 + 8A 2,6.",
 "Figura 3: só tabela. Figura 6: 6A (4,0) ou 6C (4,5, mostra o exame após cada cadeia). Figura 8: 8A.", "",
 "== 6. O que não consegui ==",
 "- Conferir visualmente todas as versões depois do último ajuste: as folhas contact_figN.png foram vistas para as figuras 1, 2, 4, 5, 6 e 8; 3 e 7 não foram inspecionadas.",
 "- 6D: os rótulos das 4 cadeias extremas ficam próximos de pontos (legíveis, não ideais).",
 "- 7A e 7C (resultados não avaliáveis) e FLOPs/tempo de treino da Figura 3.", "",
 "== textos que não couberam nas caixas ==", exec_rep.split("AVISOS")[-1] if "AVISOS" in exec_rep else "nenhum"]
(AQUI / "RELATORIO.txt").write_text("\n".join(R) + "\n"); print("relatorio ok")
