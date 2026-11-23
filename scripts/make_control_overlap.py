#!/usr/bin/env python3
"""
Sobreposição do controle com as lesões anotadas (ESANN 2027) e análise de sensibilidade de H2 e H3.
O controle de cada imagem é o MESMO em todas as execuções da campanha (protocolo: rng(0) percorrendo as 524 imagens de teste com lesão,
alvo "todas"; máscara e FOV vêm da imagem original). As frações vêm de esann_figs/fig1_candidates.csv, calculadas com as mesmas funções.
Saídas em esann_materiais/dados/: control_overlap_per_image.csv, control_overlap_resumo.txt, control_overlap_sensibilidade.csv e
a coluna ctrl_overlap_pct em ablation_per_image.csv.
"""
import sys
from itertools import combinations
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import spearmanr

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
DADOS = AQUI / "dados"
RES = Path.home() / "resultados"
sys.path.insert(0, str(REPO / "experiments"))
import analise_h3 as h3  # noqa: E402  (reaproveita testar(): bootstrap de condições, regra pré-registrada)

ARCHS = ["efficientnetv2s", "efficientnetv2b2", "inceptionv3", "resnet50"]
OFF = dict(zip(ARCHS, (0, 100, 200, 300)))
SINGLE = ["AHE40.0", "CLAHE4.0", "MaxGreen2.0", "Unsharp1.5", "Gamma0.8", "GreenChannel", "HistogramEq", "BenGraham", "LABNorm", "Morpho", "Median", "Retinex", "Gaussian", "Grayscale", "Frangi", "Canny", "Otsu"]
rng = np.random.default_rng(20261117)

# ------------------------------------------------------------------ 1. sobreposição por imagem
c = pd.read_csv(REPO / "esann_figs/fig1_candidates.csv")
assert len(c) == 524
ov = pd.DataFrame(dict(image_id=c.imagem, area_mascara_pct=100 * c.area_mascara_px / (299 * 299),
                       controle_sobre_lesao_pct=100 * c.controle_sobre_lesao, controle_fora_do_FOV_pct=100 * c.controle_fora_fov))
ov.to_csv(DADOS / "control_overlap_per_image.csv", index=False)
o = ov.controle_sobre_lesao_pct
q = lambda s: f"mediana {s.median():.2f}%; Q1 {s.quantile(.25):.2f}%; Q3 {s.quantile(.75):.2f}%; mín {s.min():.2f}%; máx {s.max():.2f}%"
L = ["CONTROLE DESLOCADO: SOBREPOSIÇÃO COM AS LESÕES ANOTADAS (524 imagens de teste com lesão)",
     "Definições: controle_sobre_lesao_pct = % da área do controle que cai sobre lesão anotada (união das máscaras originais, sem dilatar); controle_fora_do_FOV_pct = % da área do controle fora do campo de visão;",
     "area_mascara_pct = área da máscara dilatada 3x3 (a que é borrada) em % da imagem de 299 x 299 px. O controle é o mesmo em todas as execuções (rng(0), mesma ordem de imagens).", "",
     "Sobreposição do controle com lesão anotada: " + q(o),
     f"  % das imagens com sobreposição 0: {100 * (o == 0).mean():.1f}% ({int((o == 0).sum())}); ≤ 5%: {100 * (o <= 5).mean():.1f}% ({int((o <= 5).sum())}); > 20%: {100 * (o > 20).mean():.1f}% ({int((o > 20).sum())})",
     "Controle fora do FOV: " + q(ov.controle_fora_do_FOV_pct), f"  % das imagens com 0% fora do FOV: {100 * (ov.controle_fora_do_FOV_pct == 0).mean():.1f}%; > 5%: {100 * (ov.controle_fora_do_FOV_pct > 5).mean():.1f}%",
     "Área da máscara dilatada: " + q(ov.area_mascara_pct),
     f"Controle com a mesma forma (nenhum pixel cortado ao deslocar): {100 * c.controle_mesma_forma.mean():.1f}% das imagens.",
     f"Correlação de Spearman entre a área da máscara e a sobreposição: {spearmanr(ov.area_mascara_pct, o).correlation:.2f} (imagens com muita lesão têm menos área livre para o controle).", ""]

# ------------------------------------------------------------------ 2. coluna ctrl_overlap_pct em ablation_per_image.csv
ab = pd.read_csv(DADOS / "ablation_per_image.csv")
ab = ab.drop(columns=[x for x in ("ctrl_overlap_pct",) if x in ab.columns])
ab["ctrl_overlap_pct"] = ab.image_id.map(ov.set_index("image_id").controle_sobre_lesao_pct)
assert ab.ctrl_overlap_pct.notna().all()
ab.to_csv(DADOS / "ablation_per_image.csv", index=False)

# ------------------------------------------------------------------ 3. sensibilidade: só imagens com sobreposição <= 5%
base = pd.read_csv(REPO / "experiments/analise_h3/por_execucao.csv")
conds = sorted(base.condicao.unique())
img_ok = set(ov.image_id[o <= 5]); n_ok = len(img_ok)
rows = []
for a in ARCHS:
    for cd in conds:
        for s in (20, 21, 22):
            x = pd.read_csv(RES / "xai_protocolo" / f"{cd}_{OFF[a] + s}_ablacao.csv"); x = x[x.alvo == "todas"]
            d = x.queda_lesao - x.queda_deslocada
            rows.append(dict(arch=a, condicao=cd, seed=s, A_all=d.mean(), A_sub=d[x.imagem.isin(img_ok)].mean(), n_sub=int(x.imagem.isin(img_ok).sum())))
R = pd.DataFrame(rows).merge(base[["arch", "condicao", "seed", "AUC", "dp_p", "degenerado"]], on=["arch", "condicao", "seed"])
chk = (R.A_all - base.set_index(["arch", "condicao", "seed"]).loc[list(zip(R.arch, R.condicao, R.seed))].A.to_numpy()).abs().max()
assert chk < 1e-9, chk                                           # reproduz o A da campanha nas 524 imagens

def h2(col):
    M = {}
    for a in ARCHS:
        g = R[R.arch == a].groupby("condicao")[col].mean()
        M[a] = np.array([100 * (g[f] - g["baseline"]) for f in SINGLE])
    X = np.column_stack([M[a] for a in ARCHS]); pairs = list(combinations(range(4), 2))
    r = [spearmanr(X[:, i], X[:, j]).correlation for i, j in pairs]; m = np.mean(r)
    nulo = np.empty(10000)
    for b in range(10000):
        P = X.copy()
        for j in range(1, 4): P[:, j] = rng.permutation(P[:, j])
        nulo[b] = np.mean([spearmanr(P[:, i], P[:, j]).correlation for i, j in pairs])
    p = (1 + (nulo >= m).sum()) / 10001
    return m, min(r), max(r), p, bool(m > 0 and p < 0.05 and all(v > 0 for v in r))

h3.B = 2000
def h3run(col, sem_deg):
    d = R[["arch", "condicao", "seed", "AUC", "dp_p", "degenerado"]].copy(); d["A"] = R[col]
    if sem_deg:
        ruim = d.groupby(["arch", "condicao"]).degenerado.any(); d = d[~d.set_index(["arch", "condicao"]).index.map(ruim)]
    return h3.testar(d, np.random.default_rng(20261117))

out = [("524 imagens", "A_all"), (f"{n_ok} imagens (sobreposição ≤ 5%)", "A_sub")]
L += [f"ANÁLISE DE SENSIBILIDADE: só as {n_ok} imagens com sobreposição ≤ 5%, contra as 524", "(a AUC usa sempre as 553 imagens de teste; os pipelines e os 3 treinos são os mesmos; bootstrap de condições com 2.000 reamostragens, não 10.000)", ""]
L.append("A médio, sem filtro (pontos): " + "; ".join(f"{a} " + " / ".join(f"{100 * R[(R.arch == a) & (R.condicao == 'baseline')][col].mean():.1f}" for _, col in out) for a in ARCHS) + "   [formato: 524 / subconjunto]")
L.append("A médio, média dos 185 pipelines (pontos): " + "; ".join(f"{a} " + " / ".join(f"{100 * R[R.arch == a][col].mean():.1f}" for _, col in out) for a in ARCHS))
res = []
for nome, col in out:
    m, lo, hi, p, ok = h2(col)
    res.append(("H2", nome, f"ρ médio entre redes {m:.3f} (pares {lo:.3f} a {hi:.3f}), p de permutação {p:.4f}", "confirmada" if ok else "NÃO confirmada"))
for nome, col in out:
    for sd in (False, True):
        t = h3run(col, sd); pa = t["por_arquitetura"]
        res.append(("H3" + (" sem colapsados" if sd else ""), nome, "diferença (ρ entre − ρ dentro): " + " / ".join(f"{pa[a]['diferenca']:.2f} [{pa[a]['ic_inf']:.2f}; {pa[a]['ic_sup']:.2f}]" for a in ARCHS) + f"; ρ entre " + " / ".join(f"{pa[a]['r_entre']:.2f}" for a in ARCHS) + "; ρ dentro " + " / ".join(f"{pa[a]['r_dentro']:.2f}" for a in ARCHS),
                    f"IC > 0 em {t['arquiteturas_com_ic_acima_de_zero']} de 4: " + ("confirmada" if t["confirmada"] else "NÃO confirmada")))
pd.DataFrame(res, columns=["hipotese", "conjunto", "estatistica", "veredito"]).to_csv(DADOS / "control_overlap_sensibilidade.csv", index=False)
L.append("")
for h, nome, est, v in res: L += [f"{h} | {nome}", f"  {est}", f"  veredito: {v}"]
conf = {(h, n): v for h, n, _, v in res}
mudou = any(conf[(h, out[0][0])] != conf[(h, out[1][0])] for h in ("H2", "H3", "H3 sem colapsados"))
L += ["", "CONCLUSÃO: " + ("o veredito de H2 ou H3 MUDA com o subconjunto (ver acima)." if mudou else "os vereditos de H2 e H3 (inclusive H3 sem colapsados) NÃO mudam ao restringir às imagens com sobreposição ≤ 5%."),
      "Observação: as imagens excluídas são as com mais lesão (menos área livre para o controle), então o A médio do subconjunto não é comparável em nível ao das 524; a comparação relevante é a ordem dos filtros e as correlações."]
(DADOS / "control_overlap_resumo.txt").write_text("\n".join(L) + "\n"); print("\n".join(L))
