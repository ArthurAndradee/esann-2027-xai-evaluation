#!/usr/bin/env python3
"""Miniaturas finais das 2 menores e 2 maiores cadeias de AUC parecida (Figura 6C); mesmo exame principal. Só filtros (sem TF)."""
import sys, json
from pathlib import Path
import cv2, pandas as pd
AQUI = Path(__file__).resolve().parent; REPO = AQUI.parent
sys.path.insert(0, str(REPO / "pipeline"))
from utils_common import get_paths
from utils_preprocessing import get_filter, parse_filter_name
paths = get_paths(str(REPO)); e = json.load(open(REPO / "esann_figs/fig1_info.json"))["imagem"]
orig = cv2.cvtColor(cv2.imread(str(paths["original_images"] / e)), cv2.COLOR_BGR2RGB)
sim = pd.read_csv(AQUI / "dados/chains_similar_auc.csv").sort_values("A_points_mean4")
ext = list(sim.pipeline.iloc[:2]) + list(sim.pipeline.iloc[-2:])
(AQUI / "paineis/extremas").mkdir(exist_ok=True)
for nome in ext:
    cid = "_".join(nome.split(" > "))
    im = cv2.resize(get_filter(cid, parse_filter_name(cid)[1]).apply(orig), (299, 299))
    cv2.imwrite(str(AQUI / "paineis/extremas" / f"{cid}.png"), cv2.cvtColor(im, cv2.COLOR_RGB2BGR))
pd.DataFrame(dict(chain=ext)).to_csv(AQUI / "dados/chains_extremas.csv", index=False); print(ext)
