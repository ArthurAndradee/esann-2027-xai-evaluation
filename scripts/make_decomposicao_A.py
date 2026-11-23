#!/usr/bin/env python3
"""
Decomposição de A (ESANN 2027): queda de p(RD referível) ao borrar as lesões, queda ao borrar o controle deslocado, A = diferença,
e A recalculado em logit (robustez à escala de probabilidade). Fonte: ~/resultados/xai_protocolo/{condicao}_{semente}_ablacao.csv (alvo "todas", 524 imagens),
3 treinos (sementes 20-22) por condição e rede; média dos treinos. Saídas em dados/: A_decomposicao.csv, A_decomposicao_resumo.txt.
Logit: p é limitado a [1e-4, 1-1e-4]; p_borrada = p_original − queda.
"""
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import spearmanr
AQUI = Path(__file__).resolve().parent; RES = Path.home() / "resultados" / "xai_protocolo"
OFF = {"efficientnetv2s": 0, "efficientnetv2b2": 100, "inceptionv3": 200, "resnet50": 300}
FILT = ["AHE40.0", "CLAHE4.0", "MaxGreen2.0", "Unsharp1.5", "Gamma0.8", "GreenChannel", "HistogramEq", "BenGraham", "LABNorm", "Morpho", "Median", "Retinex", "Gaussian", "Grayscale", "Frangi", "Canny", "Otsu"]
DEST = ["Frangi", "Canny", "Otsu"]
lg = lambda p: np.log(np.clip(p, 1e-4, 1 - 1e-4) / (1 - np.clip(p, 1e-4, 1 - 1e-4)))
rows = []
for a, o in OFF.items():
    for c in ["baseline"] + FILT:
        L = []
        for s in (20, 21, 22):
            x = pd.read_csv(RES / f"{c}_{o + s}_ablacao.csv"); x = x[x.alvo == "todas"]; assert len(x) == 524
            p = x.p_original; pl = p - x.queda_lesao; pc = p - x.queda_deslocada
            L.append([p.mean(), 100 * x.queda_lesao.mean(), 100 * x.queda_deslocada.mean(), 100 * (x.queda_lesao - x.queda_deslocada).mean(), (lg(pc) - lg(pl)).mean()])
        m = np.mean(L, 0); rows.append(dict(arch=a, condicao=c, p_original_medio=m[0], queda_lesao_pontos=m[1], queda_controle_pontos=m[2], A_pontos=m[3], A_logit=m[4], n_treinos=3))
D = pd.DataFrame(rows).round(4); D.to_csv(AQUI / "dados" / "A_decomposicao.csv", index=False)
T = ["DECOMPOSIÇÃO DE A: queda pelas lesões, queda pelo controle e A (524 imagens de teste com lesão; média de 3 treinos)",
     "queda_lesao_pontos e queda_controle_pontos: queda média de p(RD referível) em pontos (1 ponto = 0,01); A_pontos = queda_lesao − queda_controle; A_logit = média de [logit p(controle borrado) − logit p(lesões borradas)] (unidades de logit).", ""]
for a in OFF:
    d = D[D.arch == a]; f = d[d.condicao != "baseline"]
    T.append(f"{a}: sem filtro lesão {d[d.condicao=='baseline'].queda_lesao_pontos.iloc[0]:.1f}, controle {d[d.condicao=='baseline'].queda_controle_pontos.iloc[0]:.1f}, A {d[d.condicao=='baseline'].A_pontos.iloc[0]:.1f} pontos; "
             f"controle entre {f.queda_controle_pontos.min():.1f} e {f.queda_controle_pontos.max():.1f} nos 17 filtros ({f[~f.condicao.isin(DEST)].queda_controle_pontos.min():.1f} a {f[~f.condicao.isin(DEST)].queda_controle_pontos.max():.1f} sem Frangi/Canny/Otsu); ρ de Spearman entre A (pontos) e A (logit) nos 17 filtros = {spearmanr(f.A_pontos, f.A_logit).correlation:.2f}; "
             f"p original médio entre filtros {f.p_original_medio.min():.2f}–{f.p_original_medio.max():.2f} ({f[~f.condicao.isin(DEST)].p_original_medio.min():.2f}–{f[~f.condicao.isin(DEST)].p_original_medio.max():.2f} sem os destrutivos)")
    T.append("   queda das lesões (CLAHE / AHE / canal verde): " + " / ".join(f"{d[d.condicao==k].queda_lesao_pontos.iloc[0]:.1f}" for k in ("CLAHE4.0", "AHE40.0", "GreenChannel")))
T += ["", "Leitura: o efeito dos filtros em A vem da queda causada pelas lesões; a queda do controle costuma ser pequena e negativa (borrar o controle sobe p um pouco, o que soma pontos a A): de −6 a +0,6 nos filtros não destrutivos (até −13 no EfficientNetV2-S com Canny), maior no EfficientNetV2-S e -B2 do que no InceptionV3 e ResNet-50.",
      "A ordem dos filtros é praticamente a mesma em probabilidade e em logit."]
(AQUI / "dados" / "A_decomposicao_resumo.txt").write_text("\n".join(T) + "\n"); print("\n".join(T))
