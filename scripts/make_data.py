#!/usr/bin/env python3
"""
Números e tabelas do artigo ESANN 2027, só a partir de resultados já gravados (nada é treinado nem inventado).
Entradas (todas existentes): experiments/analise_h3/por_execucao.csv, experiments/secundarias_fase1/por_execucao.csv,
~/resultados/{predicoes,xai_protocolo}/*, experiments/analise_fase1a/*, analise_h3/resumo.json.
Saídas em esann_figs/: fig2_data.csv, fig3_data.csv, pipelines_summary.csv, chains_similar_auc.csv,
chains_similar_auc_por_rede.csv, lesion_type.csv, accuracy_counts.csv, accuracy_tests_all_pipelines.csv,
verification_numbers.json (lido por make_verification.py).
Uso: python3 esann_figs/make_data.py [--sem-bootstrap]
"""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import spearmanr

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
RES = Path.home() / "resultados"
ARCHS = ["efficientnetv2s", "efficientnetv2b2", "inceptionv3", "resnet50"]
OFF = {"efficientnetv2s": 0, "efficientnetv2b2": 100, "inceptionv3": 200, "resnet50": 300}
SEEDS = (20, 21, 22)
SINGLE = ["AHE40.0", "CLAHE4.0", "MaxGreen2.0", "Unsharp1.5", "Gamma0.8", "GreenChannel", "HistogramEq", "BenGraham",
          "LABNorm", "Morpho", "Median", "Retinex", "Gaussian", "Grayscale", "Frangi", "Canny", "Otsu"]
B = 20_000
SEMENTE = 20261116


def holm(p):
    p = np.asarray(p, float)
    o = np.argsort(p)
    aj = np.empty_like(p)
    acum = 0.0
    for k, i in enumerate(o):
        acum = max(acum, (len(p) - k) * p[i])
        aj[i] = min(1.0, acum)
    return aj


def cadeia(c):
    return " > ".join(c.split("_")) if c != "baseline" else "unfiltered"


def main(bootstrap=True):
    d = pd.read_csv(REPO / "experiments" / "analise_h3" / "por_execucao.csv")
    s = pd.read_csv(REPO / "experiments" / "secundarias_fase1" / "por_execucao.csv")
    assert d.condicao.nunique() == 185 and len(d) == 2220
    d["Apts"] = d.A * 100
    out = {}
    m = d.groupby(["arch", "condicao"])[["A", "AUC"]].mean()
    sd = d.groupby(["arch", "condicao"])[["A", "AUC"]].std(ddof=1)
    base_auc = {a: m.loc[(a, "baseline")].AUC for a in ARCHS}
    base_A = {a: m.loc[(a, "baseline")].A for a in ARCHS}

    # ---- fig2_data.csv (17 filtros únicos)
    f2 = []
    for f in SINGLE:
        r = dict(filtro=f)
        for a in ARCHS:
            r[f"kept_{a}"] = 100 * m.loc[(a, f)].A / base_A[a]
            r[f"auc_{a}"] = m.loc[(a, f)].AUC
        r["kept_mean"] = np.mean([r[f"kept_{a}"] for a in ARCHS])
        r["auc_mean4"] = np.mean([r[f"auc_{a}"] for a in ARCHS])
        f2.append(r)
    f2 = pd.DataFrame(f2).sort_values("kept_mean")
    f2.to_csv(AQUI / "fig2_data.csv", index=False)
    pd.DataFrame([dict(arch=a, A_unfiltered_points=100 * base_A[a], auc_unfiltered=base_auc[a]) for a in ARCHS]
                 + [dict(arch="mean4", A_unfiltered_points=100 * np.mean(list(base_A.values())),
                         auc_unfiltered=np.mean(list(base_auc.values())))]).to_csv(AQUI / "fig2_baseline.csv", index=False)

    # ---- fig3: V2S, pontos por pipeline e 3 treinos de 5 pipelines
    g = d[d.arch == "efficientnetv2s"]
    pm = g.groupby("condicao").agg(A=("Apts", "mean"), AUC=("AUC", "mean"), deg=("degenerado", "any"))
    cand = pm[(~pm.deg) & (pm.AUC > 0.89)].sort_values("A")
    pick = list(cand.index[np.linspace(2, len(cand) - 3, 5).astype(int)])
    pm.reset_index().to_csv(AQUI / "fig3_pipelines_v2s.csv", index=False)
    g[g.condicao.isin(pick)][["condicao", "seed", "AUC", "Apts"]].to_csv(AQUI / "fig3_runs_destacados.csv", index=False)
    bet, wit = {}, {}
    for a in ARCHS:
        ga = d[d.arch == a]
        mm = ga.groupby("condicao")[["A", "AUC"]].mean()
        dev = ga[["A", "AUC"]] - ga.groupby("condicao")[["A", "AUC"]].transform("mean")
        bet[a] = spearmanr(mm.A, mm.AUC).correlation
        wit[a] = spearmanr(dev.A, dev.AUC).correlation
    pd.DataFrame(dict(arch=ARCHS, between=[bet[a] for a in ARCHS], within=[wit[a] for a in ARCHS])).to_csv(
        AQUI / "fig3_correlations.csv", index=False)
    (AQUI / "fig3_info.txt").write_text(
        "Painel (a): EfficientNetV2-S, pipelines nao colapsados (flag degenerado em nenhum dos 3 treinos), AUC media > 0,89;\n"
        "5 destacados = indices np.linspace(2, n-3, 5) do ranking crescente de A entre os candidatos (n=%d):\n" % len(cand)
        + "\n".join(f"  {cadeia(c)}  AUC {pm.loc[c].AUC:.3f}  A {pm.loc[c].A:.2f} pontos" for c in pick)
        + "\nPainel (b): Spearman (scipy.stats.spearmanr); entre pipelines = AUC x A das medias dos pipelines (185);\n"
          "entre treinos = desvios em relacao a media do pipeline (2220 treinos).\n")

    # ---- pipelines_summary.csv
    linhas = []
    for c in sorted(d.condicao.unique(), key=lambda c: (c != "baseline", len(c.split("_")), c)):
        r = dict(pipeline=cadeia(c), condicao_id=c, n_filtros=0 if c == "baseline" else len(c.split("_")))
        for a in ARCHS:
            x = d[(d.arch == a) & (d.condicao == c)]
            r[f"{a}_AUC_mean"], r[f"{a}_AUC_sd"] = x.AUC.mean(), x.AUC.std(ddof=1)
            r[f"{a}_A_points_mean"], r[f"{a}_A_points_sd"] = x.Apts.mean(), x.Apts.std(ddof=1)
            r[f"{a}_collapsed_runs"] = "".join("1" if v else "0" for v in x.sort_values("seed").degenerado)
        r["AUC_mean4"] = np.mean([r[f"{a}_AUC_mean"] for a in ARCHS])
        r["A_points_mean4"] = np.mean([r[f"{a}_A_points_mean"] for a in ARCHS])
        linhas.append(r)
    ps = pd.DataFrame(linhas)
    ps.to_csv(AQUI / "pipelines_summary.csv", index=False)

    # ---- chains_similar_auc (média das 4 redes a ±0,01 do sem filtro)
    b4 = ps[ps.pipeline == "unfiltered"].iloc[0]
    sim = ps[(ps.pipeline != "unfiltered") & ((ps.AUC_mean4 - b4.AUC_mean4).abs() <= 0.01)]
    sim[["pipeline", "n_filtros", "AUC_mean4", "A_points_mean4"] + [f"{a}_{k}" for a in ARCHS for k in ("AUC_mean", "A_points_mean")]] \
        .sort_values("A_points_mean4").to_csv(AQUI / "chains_similar_auc.csv", index=False)
    por_rede = []
    for a in ARCHS:
        sa = ps[(ps.pipeline != "unfiltered") & ((ps[f"{a}_AUC_mean"] - b4[f"{a}_AUC_mean"]).abs() <= 0.01)]
        for _, r in sa.iterrows():
            por_rede.append(dict(arch=a, pipeline=r.pipeline, AUC=r[f"{a}_AUC_mean"], A_points=r[f"{a}_A_points_mean"]))
    pr = pd.DataFrame(por_rede)
    pr.to_csv(AQUI / "chains_similar_auc_por_rede.csv", index=False)
    out["similar_auc"] = dict(
        n=int(len(sim)), A_min=float(sim.A_points_mean4.min()), A_max=float(sim.A_points_mean4.max()),
        base_auc4=float(b4.AUC_mean4), base_A4=float(b4.A_points_mean4),
        por_rede={a: dict(n=int((pr.arch == a).sum()), A_min=float(pr[pr.arch == a].A_points.min()),
                          A_max=float(pr[pr.arch == a].A_points.max()), base_A=float(100 * base_A[a]),
                          base_AUC=float(base_auc[a])) for a in ARCHS},
        exemplos={p: [float(sim[sim.pipeline == p].AUC_mean4.iloc[0]), float(sim[sim.pipeline == p].A_points_mean4.iloc[0])]
                  for p in ["BenGraham > CLAHE4.0 > Gaussian", "AHE40.0 > Gaussian", "LABNorm > GreenChannel > Median",
                            "LABNorm > Grayscale"] if (sim.pipeline == p).any()})

    # ---- lesion_type.csv (ablação por tipo; A = queda_lesao - queda_deslocada, média nas imagens e nos 3 treinos)
    conds = ["baseline", "CLAHE4.0", "AHE40.0", "GreenChannel", "Grayscale"]
    cache = {}
    for a in ARCHS:
        for c in conds:
            frames = []
            for sd_ in SEEDS:
                x = pd.read_csv(RES / "xai_protocolo" / f"{c}_{OFF[a] + sd_}_ablacao.csv")
                x["A"] = x.queda_lesao - x.queda_deslocada
                frames.append(x.assign(seed=sd_))
            cache[(a, c)] = pd.concat(frames)
    lt = []
    for a in ARCHS:
        for tipo in ["todas", "MA", "HE", "EX", "SE"]:
            Ab = cache[(a, "baseline")]; Ab = Ab[Ab.alvo == tipo].A.mean()
            for c in conds[1:]:
                x = cache[(a, c)]; x = x[x.alvo == tipo]
                lt.append(dict(arch=a, lesion=tipo, filter=c, n_images=int(x.imagem.nunique()), A_unfiltered_points=100 * Ab,
                               A_filter_points=100 * x.A.mean(), kept_percent=100 * x.A.mean() / Ab,
                               drop_percent=100 - 100 * x.A.mean() / Ab))
    lt = pd.DataFrame(lt)
    lt.to_csv(AQUI / "lesion_type.csv", index=False)
    ex = lt[(lt.lesion == "EX") & (lt["filter"] == "CLAHE4.0")]
    out["lesion_type_EX_CLAHE_drop_percent"] = {r.arch: float(r.drop_percent) for r in ex.itertuples()}

    # ---- desvios padrão (verificação)
    within = {a: float(np.sqrt(d[d.arch == a].groupby("condicao").AUC.var(ddof=1).mean())) for a in ARCHS}
    between = {a: float(d[d.arch == a].groupby("condicao").AUC.mean().std(ddof=1)) for a in ARCHS}
    # sem pipelines colapsados (nenhum dos 3 treinos com a flag), a definição que reproduz 0,026–0,053 entre pipelines
    w_nc, b_nc, w_big = {}, {}, {}
    for a in ARCHS:
        ga = d[d.arch == a]
        ok = ga.groupby("condicao").degenerado.any()
        ga_nc = ga[ga.condicao.isin(ok[~ok].index)]
        w_nc[a] = float(np.sqrt(ga_nc.groupby("condicao").AUC.var(ddof=1).mean()))
        b_nc[a] = float(ga_nc.groupby("condicao").AUC.mean().std(ddof=1))
        pm_ = ga.groupby("condicao").AUC.mean()
        gb = ga[ga.condicao.isin(pm_[pm_ >= 0.85].index)]
        w_big[a] = float(np.sqrt(gb.groupby("condicao").AUC.var(ddof=1).mean()))
    out["sd_auc_within_pooled"] = within
    out["sd_auc_between_pipelines"] = between
    out["sd_auc_within_pooled_sem_colapsados"] = w_nc
    out["sd_auc_between_pipelines_sem_colapsados"] = b_nc
    out["sd_auc_within_pooled_pipelines_auc_ge_085"] = w_big
    out["sd_auc_within_pooled_all"] = float(np.sqrt(np.mean([v ** 2 for v in within.values()])))

    # ---- correlação restrita
    restr = {}
    for a in ARCHS:
        ga = d[d.arch == a]
        pa = ga.groupby("condicao").agg(A=("A", "mean"), AUC=("AUC", "mean"), deg=("degenerado", "any"))
        k = pa[(~pa.deg) & (pa.AUC >= 0.89) & (pa.AUC <= 0.915)]
        restr[a] = dict(n=int(len(k)), spearman=float(spearmanr(k.A, k.AUC).correlation),
                        pearson=float(np.corrcoef(k.A, k.AUC)[0, 1]))
        # variante: só o critério de AUC (sem excluir colapsados; colapsado quase não ocorre nessa faixa)
        k2 = pa[(pa.AUC >= 0.89) & (pa.AUC <= 0.915)]
        restr[a]["n_sem_excluir_colapsados"] = int(len(k2))
        restr[a]["spearman_sem_excluir_colapsados"] = float(spearmanr(k2.A, k2.AUC).correlation)
    out["corr_restrita_890_915"] = restr

    # ---- Grad-CAM AUPRC x AUC (tipo de correlação) — recomputa
    gc = {}
    for a in ARCHS:
        sa = s[s.arch == a]
        mm = sa.groupby("condicao")[["auprc", "AUC", "A"]].mean()
        dev = sa[["auprc", "AUC"]] - sa.groupby("condicao")[["auprc", "AUC"]].transform("mean")
        gc[a] = dict(entre_spearman=float(spearmanr(mm.auprc, mm.AUC).correlation),
                     entre_pearson=float(np.corrcoef(mm.auprc, mm.AUC)[0, 1]),
                     dentro_spearman=float(spearmanr(dev.auprc, dev.AUC).correlation),
                     dentro_pearson=float(np.corrcoef(dev.auprc, dev.AUC)[0, 1]))
    out["gradcam_auprc_x_auc"] = gc

    # ---- acurácia: contagens e testes pareados (hierárquico) -----------------------------------------
    filt = [c for c in sorted(d.condicao.unique()) if c != "baseline"]
    assert len(filt) == 184
    cont = []
    for a in ARCHS:
        dm = pd.Series({c: m.loc[(a, c)].AUC for c in filt}) - base_auc[a]
        best = dm.idxmax()
        cont.append(dict(arch=a, n_filtered=184, n_auc_below_base_minus_0p02=int((dm < -0.02).sum()),
                         n_auc_above_base=int((dm > 0).sum()), best_filtered_pipeline=cadeia(best),
                         best_filtered_auc=float(m.loc[(a, best)].AUC), base_auc=float(base_auc[a]),
                         best_minus_base=float(dm.max())))
    cont = pd.DataFrame(cont)
    if bootstrap:
        rng = np.random.default_rng(SEMENTE)
        testes = []
        for a in ARCHS:
            # imagens de teste e rótulos (mesmos em todas as execuções)
            p0 = pd.read_csv(RES / "predicoes" / f"baseline_{OFF[a] + 20}.csv").set_index("imagem")
            y = p0.rotulo.to_numpy().astype(int)
            pos, neg = np.flatnonzero(y == 1), np.flatnonzero(y == 0)
            Wp = rng.multinomial(len(pos), np.full(len(pos), 1 / len(pos)), size=B).astype(np.float32)
            Wn = rng.multinomial(len(neg), np.full(len(neg), 1 / len(neg)), size=B).astype(np.float32)

            def aucs(c):
                boots, pts = [], []
                for sd_ in SEEDS:
                    pr_ = pd.read_csv(RES / "predicoes" / f"{c}_{OFF[a] + sd_}.csv").set_index("imagem").loc[p0.index].p_rd.to_numpy()
                    H = (pr_[pos][:, None] > pr_[neg][None, :]).astype(np.float32) + 0.5 * (pr_[pos][:, None] == pr_[neg][None, :])
                    boots.append(((Wp @ H) * Wn).sum(1) / (len(pos) * len(neg)))
                    pts.append(float(H.sum() / (len(pos) * len(neg))))
                return np.stack(boots), np.array(pts)

            def pesos():
                return rng.multinomial(3, np.full(3, 1 / 3), size=B) / 3.0
            ab, pb = aucs("baseline")
            for c in filt:
                af, pf = aucs(c)
                diff = (pesos() * af.T).sum(1) - (pesos() * ab.T).sum(1)
                dimg = af.mean(0) - ab.mean(0)                # só imagens (seeds fixas)
                testes.append(dict(arch=a, pipeline=cadeia(c), condicao_id=c, n_filtros=len(c.split("_")),
                                   dAUC=float(pf.mean() - pb.mean()),
                                   ic_inf=float(np.quantile(diff, .025)), ic_sup=float(np.quantile(diff, .975)),
                                   ic_img_inf=float(np.quantile(dimg, .025)), ic_img_sup=float(np.quantile(dimg, .975)),
                                   p_melhor_unilateral=float((1 + (diff <= 0).sum()) / (B + 1)),
                                   p_pior_unilateral=float((1 + (diff >= 0).sum()) / (B + 1))))
            print(a, "ok", flush=True)
        te = pd.DataFrame(testes)
        te["p_holm_melhor"] = te.groupby("arch").p_melhor_unilateral.transform(holm)
        te["p_holm_pior"] = te.groupby("arch").p_pior_unilateral.transform(holm)
        te["signif_melhor"] = te.p_holm_melhor < 0.05
        te["signif_pior"] = te.p_holm_pior < 0.05
        te.to_csv(AQUI / "accuracy_tests_all_pipelines.csv", index=False)
        sing = te[te.condicao_id.isin(SINGLE)]
        cont["n_signif_better_holm184"] = [int(te[(te.arch == a)].signif_melhor.sum()) for a in ARCHS]
        cont["n_signif_worse_holm184"] = [int(te[(te.arch == a)].signif_pior.sum()) for a in ARCHS]
        cont["min_p_holm_better"] = [float(te[te.arch == a].p_holm_melhor.min()) for a in ARCHS]
        cont["single_filters_ci_all_above_0"] = [int((sing[sing.arch == a].ic_inf > 0).sum()) for a in ARCHS]
        cont["single_filters_ci_all_below_0"] = [int((sing[sing.arch == a].ic_sup < 0).sum()) for a in ARCHS]
        cont["single_filters_ci_img_only_above_0"] = [int((sing[sing.arch == a].ic_img_inf > 0).sum()) for a in ARCHS]
        cont["single_filters_ci_img_only_below_0"] = [int((sing[sing.arch == a].ic_img_sup < 0).sum()) for a in ARCHS]
    cont.to_csv(AQUI / "accuracy_counts.csv", index=False)
    (AQUI / "verification_numbers.json").write_text(json.dumps(out, indent=1, ensure_ascii=False))
    print(cont.to_string())
    print(json.dumps({k: out[k] for k in ("similar_auc", "sd_auc_within_pooled", "sd_auc_between_pipelines", "corr_restrita_890_915",
                                         "gradcam_auprc_x_auc", "lesion_type_EX_CLAHE_drop_percent")}, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    main(bootstrap="--sem-bootstrap" not in sys.argv)
