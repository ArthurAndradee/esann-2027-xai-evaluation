#!/usr/bin/env python3
"""
Resultados da validação externa no DDR (fase 2b: modelos treinados no FGADR e avaliados no DDR, 10 seeds, reps 70-79,
interpolação do DDR corrigida; PREREGISTRO_FASE2.md + PREREGISTRO_FASE2_DESVIOS.md) para o artigo ESANN 2027.
Usa as funções da análise congelada (experiments/analise_fase2b.py) sem alterá-las.
  - Veredito H4/H5a/H5b: o do resumo congelado (analise_fase2b/resumo.json), SÓ para redes que passam a pré-condição.
  - Para as redes que NÃO passam (AUC do sem filtro no DDR < 0,70), os números abaixo são DESCRITIVOS (não são teste).
  - confiança mantida = 100 x A(filtro) / A(sem filtro), com IC 95% do mesmo bootstrap hierárquico (seeds e imagens).
Saídas: ddr_results.csv, fig4_data.csv.
"""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
sys.path.insert(0, str(REPO / "experiments"))
import analise_fase2b as f2b  # noqa: E402
from utils_common import get_paths  # noqa: E402

ARCHS = f2b.ARCHS
HIP = f2b.HIPOTESES          # H4 CLAHE4.0 (-1), H5a GreenChannel (+1), H5b Grayscale (+1)
B = f2b.B
res = get_paths(str(REPO))["resultados"]
cong = json.load(open(REPO / "experiments" / "analise_fase2b" / "resumo.json"))
fg2 = pd.read_csv(AQUI / "fig2_data.csv").set_index("filtro")


def razao_boot(dados_f, dados_b, rng):
    """Confiança mantida (%) com IC 95%: razão das médias de A, reamostrando seeds e imagens (pareadas)."""
    sf, sb = sorted(dados_f), sorted(dados_b)
    imgs = sorted(set.intersection(*[set(dados_f[s][0].index) for s in sf] + [set(dados_b[s][0].index) for s in sb]))
    Af = np.stack([dados_f[s][0].loc[imgs].to_numpy() for s in sf]); Ab = np.stack([dados_b[s][0].loc[imgs].to_numpy() for s in sb])
    n = len(imgs)
    Mf, Mb = f2b.pesos_seeds(rng, len(sf)) @ Af, f2b.pesos_seeds(rng, len(sb)) @ Ab
    ci = rng.multinomial(n, np.full(n, 1 / n), size=B) / n
    num, den = (Mf * ci).sum(1), (Mb * ci).sum(1)
    r = 100 * num / den
    # se o denominador chega perto de 0 a razão explode: registra quantas vezes |den| < 0,005
    return float(100 * Af.mean() / Ab.mean()), float(np.quantile(r, .025)), float(np.quantile(r, .975)), float((np.abs(den) < 0.005).mean())


def auc_ic(base, rng, bb=4000):
    """AUC do sem filtro no DDR: média das seeds e IC 95% (seeds e imagens, estratificado por classe)."""
    seeds = sorted(base)
    gi = sorted(set.intersection(*[set(base[s][1].index) for s in seeds]))
    y = base[seeds[0]][1].loc[gi].rotulo.to_numpy().astype(int)
    pos, neg = np.flatnonzero(y == 1), np.flatnonzero(y == 0)
    pt = float(np.mean([f2b.auc_boot(y, base[s][1].loc[gi].p_rd.to_numpy(), np.arange(len(y))[None, :])[0] for s in seeds]))
    W = rng.multinomial(len(seeds), np.full(len(seeds), 1 / len(seeds)), size=bb) / len(seeds)
    boot = np.empty(bb)
    for i in range(0, bb, 500):
        k = min(500, bb - i)
        ix = np.concatenate([pos[rng.integers(0, len(pos), (k, len(pos)))], neg[rng.integers(0, len(neg), (k, len(neg)))]], axis=1)
        a = np.stack([f2b.auc_boot(y, base[s][1].loc[gi].p_rd.to_numpy(), ix) for s in seeds])
        boot[i:i + k] = (W[i:i + k] * a.T).sum(1)
    return pt, float(np.quantile(boot, .025)), float(np.quantile(boot, .975)), len(gi)


def main():
    linhas, fig4 = [], []
    for arch in ARCHS:
        rng = np.random.default_rng(20261116 + ARCHS.index(arch))
        base = f2b.carregar(res, "baseline", arch)
        pre = cong["precondicao"][arch]
        auc, lo, hi, n_auc = auc_ic(base, rng)
        Ab = np.mean([v[0].mean() for v in base.values()])
        r = dict(arch=arch, n_trainings_total=sum(len(f2b.carregar(res, c, arch)) for c in ["baseline"] + [h[0] for h in HIP.values()]),
                 seeds_per_condition=len(base), auc_unfiltered_ddr=auc, auc_ci95_low=lo, auc_ci95_high=hi, n_images_auc=n_auc,
                 auc_threshold=0.70, meets_threshold=bool(pre["apta"]), auc_unfiltered_fgadr=float(fg2[f"auc_{arch}"].iloc[0] * 0 + np.nan),
                 A_unfiltered_points=float(100 * Ab))
        for h, (filt, sinal) in HIP.items():
            dados = f2b.carregar(res, filt, arch)
            t = f2b.teste(dados, base, sinal, rng)
            kept, klo, khi, frac_inst = razao_boot(dados, base, rng)
            r.update({f"A_{filt}_points": float(100 * (Ab + t["dA"])), f"kept_{filt}_percent": kept,
                      f"kept_{filt}_ci95_low": klo, f"kept_{filt}_ci95_high": khi, f"kept_{filt}_unstable_denominator_share": frac_inst,
                      f"p_unilateral_{filt}": t["p_unilateral"], f"dA_{filt}_points": 100 * t["dA"], f"dA_{filt}_ci95_low": 100 * t["dA_ic_inf"], f"dA_{filt}_ci95_high": 100 * t["dA_ic_sup"],
                      f"dAUC_{filt}": t["dAUC"], f"dAUC_{filt}_ci95_low": t["dAUC_ic_inf"], f"dAUC_{filt}_ci95_high": t["dAUC_ic_sup"],
                      f"{h}_predicted_sign": "reduces" if sinal < 0 else "increases",
                      f"{h}_verdict_rule": cong["hipoteses"][h]["veredito"] if pre["apta"] else "not tested (precondition fails)",
                      f"{h}_n_images_A": t["n_imagens_A"]})
            kfg = float(fg2.loc[filt, f"kept_{arch}"]) if filt in fg2.index else np.nan
            fig4.append(dict(arch=arch, filter=filt, hypothesis=h, kept_ddr=kept, ci_low=klo, ci_high=khi, kept_fgadr=kfg,
                             meets_threshold=bool(pre["apta"]), auc_unfiltered_ddr=auc))
        linhas.append(r)
        print(arch, "ok", flush=True)
    df = pd.DataFrame(linhas)
    base_fgadr = pd.read_csv(AQUI / "fig2_baseline.csv").set_index("arch").auc_unfiltered
    df["auc_unfiltered_fgadr"] = [float(base_fgadr[a]) for a in df.arch]
    df["overall_verdict_H4"] = cong["hipoteses"]["H4"]["veredito"]
    df["overall_verdict_H5a"] = cong["hipoteses"]["H5a"]["veredito"]
    df["overall_verdict_H5b"] = cong["hipoteses"]["H5b"]["veredito"]
    df.to_csv(AQUI / "ddr_results.csv", index=False)
    pd.DataFrame(fig4).to_csv(AQUI / "fig4_data.csv", index=False)
    print(df.T.to_string())


if __name__ == "__main__":
    main()
