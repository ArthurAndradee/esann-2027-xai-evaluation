#!/usr/bin/env python3
"""
Dados do prompt v3 (ESANN 2027), só a partir de resultados já gravados; nada é treinado nem inventado.
Saídas em esann_materiais/dados/. Reaproveita esann_figs/ (v2) quando o arquivo já existe.
Uso: python3 esann_materiais/make_dados_v3.py   (CPU; ~5 min sem o DDR; o DDR vem de esann_figs/make_ddr.py)
"""
import json
import re
import shutil
from pathlib import Path

import cv2
import numpy as np
import pandas as pd
from scipy.stats import spearmanr

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
V2 = REPO / "esann_figs"
OUT = AQUI / "dados"; OUT.mkdir(exist_ok=True)
RES = Path.home() / "resultados"
A4 = ["efficientnetv2s", "efficientnetv2b2", "inceptionv3", "resnet50"]
OFF = dict(zip(A4, (0, 100, 200, 300)))
SINGLE = ["AHE40.0", "CLAHE4.0", "MaxGreen2.0", "Unsharp1.5", "Gamma0.8", "GreenChannel", "HistogramEq", "BenGraham",
          "LABNorm", "Morpho", "Median", "Retinex", "Gaussian", "Grayscale", "Frangi", "Canny", "Otsu"]
rng = np.random.default_rng(20261117)
cadeia = lambda c: "unfiltered" if c == "baseline" else " > ".join(c.split("_"))

d = pd.read_csv(REPO / "experiments/analise_h3/por_execucao.csv")
d["A_points"] = d.A * 100

# ---------------------------------------------------------------- pipelines_long / summary / similar
pl = d.rename(columns={"AUC": "AUC", "degenerado": "collapsed"})
pl = pl.assign(chain=pl.condicao.map(cadeia))[["chain", "condicao", "arch", "seed", "AUC", "A_points", "collapsed"]]
pl.to_csv(OUT / "pipelines_long.csv", index=False)
for f in ("pipelines_summary.csv", "chains_similar_auc.csv", "chains_similar_auc_por_rede.csv"):
    shutil.copy(V2 / f, OUT / f)

# ---------------------------------------------------------------- filter_effects_wide (17 filtros x 4 redes)
f1a = pd.read_csv(REPO / "experiments/analise_fase1a/efeitos_por_filtro.csv").set_index(["arch", "filtro"])
tests = pd.read_csv(V2 / "accuracy_tests_all_pipelines.csv")
m = d.groupby(["arch", "condicao"])[["A", "AUC"]].mean()
rows = []
for f in SINGLE:
    r = dict(filter=f)
    for a in A4:
        e = f1a.loc[(a, f)]
        t = tests[(tests.arch == a) & (tests.condicao_id == f)].iloc[0]
        r[f"kept_pct_{a}"] = 100 * m.loc[(a, f)].A / m.loc[(a, "baseline")].A
        r[f"dA_points_{a}"] = 100 * e.dA; r[f"dA_ci95_low_{a}"] = 100 * e.dA_ic_inf; r[f"dA_ci95_high_{a}"] = 100 * e.dA_ic_sup
        r[f"auc_{a}"] = m.loc[(a, f)].AUC
        r[f"dAUC_{a}"] = t.dAUC; r[f"dAUC_ci95_low_{a}"] = t.ic_inf; r[f"dAUC_ci95_high_{a}"] = t.ic_sup
    r["kept_pct_mean"] = np.mean([r[f"kept_pct_{a}"] for a in A4]); r["auc_mean"] = np.mean([r[f"auc_{a}"] for a in A4])
    r["dAUC_mean"] = np.mean([r[f"dAUC_{a}"] for a in A4])
    r["kept_pct_min"] = min(r[f"kept_pct_{a}"] for a in A4); r["kept_pct_max"] = max(r[f"kept_pct_{a}"] for a in A4)
    r["dAUC_min"] = min(r[f"dAUC_{a}"] for a in A4); r["dAUC_max"] = max(r[f"dAUC_{a}"] for a in A4)
    rows.append(r)
fe = pd.DataFrame(rows)
fam = {"Frangi": "destructive", "Canny": "destructive", "Otsu": "destructive", "AHE40.0": "contrast equalization",
       "CLAHE4.0": "contrast equalization", "HistogramEq": "contrast equalization", "Unsharp1.5": "smoothing / sharpening",
       "Gaussian": "smoothing / sharpening", "Median": "smoothing / sharpening", "GreenChannel": "color", "Grayscale": "color",
       "MaxGreen2.0": "color", "BenGraham": "illumination", "Gamma0.8": "neutral", "Morpho": "neutral", "LABNorm": "neutral", "Retinex": "illumination"}
fe["family"] = fe["filter"].map(fam)
fe.to_csv(OUT / "filter_effects_wide.csv", index=False)
(OUT / "filter_effects_nota.txt").write_text(
    "dA e IC 95% de dA: bootstrap de IMAGENS sobre a média das 3 seeds (analise_fase1a, como pré-registrado; não inclui a variação entre seeds). "
    "dAUC e IC: bootstrap hierárquico (seeds e imagens, 20.000) de esann_figs/accuracy_tests_all_pipelines.csv. "
    "A mantido = 100 x A_filtro / A_sem_filtro (média dos 3 treinos). Famílias dos filtros: decisão do Claude (destrutivos = AUC média < 0,85).\n")
exp = {"CLAHE4.0": [40, 44, 65, 45], "AHE40.0": [27, 43, 73, 34], "GreenChannel": [119, 162, 210, 191], "Grayscale": [105, 140, 168, 159], "Frangi": [3, 9, 0, 0]}
dif = [(f, a, round(fe.set_index("filter").loc[f, f"kept_pct_{a}"], 1), e) for f, v in exp.items() for a, e in zip(A4, v)
       if abs(fe.set_index("filter").loc[f, f"kept_pct_{a}"] - e) > 1]

# ---------------------------------------------------------------- correlações em escada (5D)
def boot_corr(x, y, B=2000):
    n = len(x); out = np.empty(B)
    for b in range(B):
        i = rng.integers(0, n, n); out[b] = spearmanr(x[i], y[i]).correlation
    return np.quantile(out, [.025, .975])
lad = []
for a in A4:
    ga = d[d.arch == a]
    pm = ga.groupby("condicao").agg(A=("A", "mean"), AUC=("AUC", "mean"), deg=("degenerado", "any"))
    r1 = spearmanr(pm.A, pm.AUC).correlation; ci1 = boot_corr(pm.A.to_numpy(), pm.AUC.to_numpy())
    k = pm[(~pm.deg) & (pm.AUC >= 0.89) & (pm.AUC <= 0.915)]
    r2 = spearmanr(k.A, k.AUC).correlation; ci2 = boot_corr(k.A.to_numpy(), k.AUC.to_numpy())
    dev = ga[["A", "AUC"]] - ga.groupby("condicao")[["A", "AUC"]].transform("mean")
    r3 = spearmanr(dev.A, dev.AUC).correlation
    conds = ga.condicao.unique(); B = 1000; bs = np.empty(B)
    idx = {c: np.flatnonzero((ga.condicao == c).to_numpy()) for c in conds}
    for b in range(B):
        sel = np.concatenate([idx[c] for c in rng.choice(conds, len(conds))])
        bs[b] = spearmanr(dev.A.to_numpy()[sel], dev.AUC.to_numpy()[sel]).correlation
    ci3 = np.quantile(bs, [.025, .975])
    for nome, r, ci, n in (("between pipelines", r1, ci1, len(pm)), ("between, AUC in [0.89, 0.915]", r2, ci2, len(k)), ("between runs of one pipeline", r3, ci3, len(ga))):
        lad.append(dict(arch=a, tipo=nome, rho=r, ci95_low=ci[0], ci95_high=ci[1], n=n))
pd.DataFrame(lad).to_csv(OUT / "correlations_ladder.csv", index=False)

# ---------------------------------------------------------------- lesion_type com significância
def tipo_df(a, c):
    fr = []
    for s in (20, 21, 22):
        x = pd.read_csv(RES / "xai_protocolo" / f"{c}_{OFF[a] + s}_ablacao.csv"); x["A"] = x.queda_lesao - x.queda_deslocada
        fr.append(x.pivot_table(index=["alvo", "imagem"], values="A"))
    return pd.concat(fr, axis=1).mean(axis=1)
lt = []
for a in A4:
    base = tipo_df(a, "baseline")
    for c in ("AHE40.0", "CLAHE4.0", "GreenChannel", "Grayscale"):
        dd = tipo_df(a, c)
        for tipo in ("MA", "HE", "EX", "SE"):
            b_ = base.xs(tipo, level="alvo"); f_ = dd.xs(tipo, level="alvo"); idx = b_.index.intersection(f_.index)
            diff = (f_.loc[idx] - b_.loc[idx]).to_numpy(); Ab = b_.loc[idx].mean()
            bs = np.array([diff[rng.integers(0, len(diff), len(diff))].mean() for _ in range(2000)])
            lo, hi = np.quantile(bs, [.025, .975])
            lt.append(dict(arch=a, filter=c, lesion=tipo, n_images=len(idx), A_unfiltered_points=100 * Ab, dA_points=100 * diff.mean(),
                           dA_pct_of_unfiltered=100 * diff.mean() / Ab, ci95_low_pct=100 * lo / Ab, ci95_high_pct=100 * hi / Ab,
                           significant=bool(lo > 0 or hi < 0)))
lt = pd.DataFrame(lt); lt.to_csv(OUT / "lesion_type.csv", index=False)
med = lt.groupby(["filter", "lesion"]).dA_pct_of_unfiltered.mean().unstack()
med.to_csv(OUT / "lesion_type_media_redes.csv")

# ---------------------------------------------------------------- design_185
des = json.load(open(REPO / "experiments/selecao_condicoes/desenho_final.json"))["condicoes"]
dz = pd.DataFrame([dict(chain=cadeia(c), condicao_id=c, n_filtros=0 if c == "baseline" else len(c.split("_")),
                        group="; ".join(g)) for c, g in des.items()])
dz["group_main"] = np.where(dz.group.str.contains("validacao"), "random validation (20)",
                    np.where(dz.condicao_id == "baseline", "unfiltered (1)",
                    np.where(dz.n_filtros == 1, "single filter (17)", "D-optimal (150 incl. 3 overlaps with the E1 arm)")))
dz.to_csv(OUT / "design_185.csv", index=False)

# ---------------------------------------------------------------- ablation_per_image
paths_labels = pd.read_csv(REPO / "data/Seg-set/DR_Seg_Grading_Label.csv", header=None).set_index(0)[1]
mask_dirs = [REPO / "data/Seg-set" / f"{n}_Masks" for n in ("HardExudate", "Hemohedge", "IRMA", "Microaneurysms", "Neovascularization", "SoftExudate")]
nreg = {}
for img in pd.read_csv(RES / "xai_protocolo/baseline_20_ablacao.csv").query("alvo == 'todas'").imagem:
    u = None
    for md in mask_dirs:
        p = md / img
        if p.exists():
            mk = cv2.resize((cv2.imread(str(p), cv2.IMREAD_GRAYSCALE) > 127).astype(np.uint8), (299, 299), interpolation=cv2.INTER_NEAREST)
            u = mk if u is None else np.maximum(u, mk)
    nreg[img] = int(cv2.connectedComponents(u)[0] - 1) if u is not None else 0
ab = []
for a in A4:
    for s in (20, 21, 22):
        x = pd.read_csv(RES / "xai_protocolo" / f"baseline_{OFF[a] + s}_ablacao.csv").query("alvo == 'todas'")
        ab.append(pd.DataFrame(dict(arch=a, seed=s, image_id=x.imagem, grade=x.imagem.map(paths_labels), p_orig=x.p_original,
                                    p_les=x.p_original - x.queda_lesao, p_ctrl=x.p_original - x.queda_deslocada,
                                    lesion_area_pct=100 * x.area, n_lesion_regions=x.imagem.map(nreg),
                                    class_orig=(x.p_original > .5).astype(int), class_les=((x.p_original - x.queda_lesao) > .5).astype(int),
                                    class_ctrl=((x.p_original - x.queda_deslocada) > .5).astype(int))))
pd.concat(ab).to_csv(OUT / "ablation_per_image.csv", index=False)

# ---------------------------------------------------------------- redes (parâmetros via Keras fica em make_paineis_v3.py)
(OUT / "divergencias_dados.txt").write_text(
    "Diferencas > 1 ponto na Figura 4 (A mantido): " + (str(dif) if dif else "nenhuma (maximo 0,5 ponto)") + "\n"
    "Tipos de lesao (AHE/CLAHE na media das redes, % do sem filtro): " + med.round(1).to_string() + "\n")
print("dados v3 ok;", len(dif), "divergencias na Fig 4")
