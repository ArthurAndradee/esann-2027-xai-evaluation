#!/usr/bin/env python3
"""ddr_results.csv (formato do prompt v3) e ddr_resumo.txt a partir de esann_figs/ddr_results.csv (make_ddr.py, fase 2b)."""
import json
from pathlib import Path
import numpy as np, pandas as pd
AQUI = Path(__file__).resolve().parent; REPO = AQUI.parent; OUT = AQUI / "dados"
r = pd.read_csv(REPO / "esann_figs/ddr_results.csv").set_index("arch")
cong = json.load(open(REPO / "experiments/analise_fase2b/resumo.json"))
def holm(p):
    p = np.asarray(p, float); o = np.argsort(p); aj = np.empty_like(p); ac = 0.0
    for k, i in enumerate(o): ac = max(ac, (len(p) - k) * p[i]); aj[i] = min(1.0, ac)
    return aj
F = {"clahe": ("CLAHE4.0", -1, "H4"), "green": ("GreenChannel", 1, "H5a"), "gray": ("Grayscale", 1, "H5b")}
rows = []
for a, x in r.iterrows():
    ph = holm([x[f"p_unilateral_{f}"] for f, _, _ in F.values()])
    row = dict(arch=a, n_treinos=int(x.n_trainings_total), auc_baseline_media=x.auc_unfiltered_ddr, auc_baseline_ic95_inf=x.auc_ci95_low,
               auc_baseline_ic95_sup=x.auc_ci95_high, **{"atinge_0.70": "sim" if x.meets_threshold else "não"}, A_baseline=x.A_unfiltered_points)
    for (k, (f, sg, h)), p_ in zip(F.items(), ph):
        row[f"A_{k}"] = x[f"A_{f}_points"]; row[f"mantido_{k}_pct"] = x[f"kept_{f}_percent"]
        row[f"dA_{k}"] = x[f"dA_{f}_points"]; row[f"dA_{k}_ic95_inf"] = x[f"dA_{f}_ci95_low"]; row[f"dA_{k}_ic95_sup"] = x[f"dA_{f}_ci95_high"]
        row[f"dA_{k}_p_holm"] = p_
        ok = np.sign(x[f"dA_{f}_points"]) == sg and p_ < 0.05
        row[f"cumpre_{h}"] = ("sim" if ok else "não") if x.meets_threshold else ("não avaliável (AUC < 0,70)" + ("; descritivo: " + ("sim" if ok else "não")))
    rows.append(row)
df = pd.DataFrame(rows); df.to_csv(OUT / "ddr_results.csv", index=False)
n_ok = int(r.meets_threshold.sum())
v = {h: ("não avaliável (validade: só %d de 4 redes com AUC ≥ 0,70)" % n_ok if n_ok < 3 else cong["hipoteses"][h]["veredito"]) for h in ("H4", "H5a", "H5b")}
L = ["# DDR (validação externa, fase 2b: modelos treinados no FGADR e avaliados no DDR; reps 70-79 etc.)",
     "Veredito geral (regras pré-registradas): " + "; ".join(f"{h}: {x}" for h, x in v.items()),
     f"Redes com AUC do sem filtro ≥ 0,70: {n_ok} de 4 ({', '.join(a for a in r.index if r.loc[a,'meets_threshold'])}).",
     "AUC sem filtro no DDR: " + "; ".join(f"{a} {x.auc_unfiltered_ddr:.3f}" for a, x in r.iterrows()),
     "Imagens: AUC 3.759 (esperado 3.759). A: 756 (esperado 757; uma das 757 imagens de segmentação do DDR não tem nenhuma máscara EX/HE/MA/SE).",
     "Desvios do protocolo (uma linha cada): D5 interpolação do DDR (INTER_LINEAR→INTER_AREA) corrigida, refazendo os 160 treinos (fase 2b, decidida depois de ver a pré-condição falhar); "
     "D6 bug do vigia (só execução); D7 sensibilidade em escala logit (sem divergência); D8 análise rodada à mão por falha de portão de checksum (scripts congelados intactos).",
     "Rodada anterior (fase 2, interpolação errada, reps 40-49): AUC no DDR 0,652 a 0,682, nenhuma rede ≥ 0,70. Fase 2b: 0,603 a 0,717, só a InceptionV3 ≥ 0,70. O veredito não mudou (inconclusivo).",
     "Aviso: o treino no próprio DDR (fase 3, 360 treinos) é outro experimento, ainda em execução quando este material foi gerado; não entra aqui. Ver esann_materiais/FASE3_STATUS.txt.",
     "Só a InceptionV3 foi testada pela regra pré-registrada; as demais redes têm números descritivos (marcador vazado nas figuras)."]
(OUT / "ddr_resumo.txt").write_text("\n".join(L) + "\n"); print("ddr v3 ok")
