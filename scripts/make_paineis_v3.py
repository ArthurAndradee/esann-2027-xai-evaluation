#!/usr/bin/env python3
"""
Imagens do prompt v3 (ESANN 2027): painéis de exames (1A-1E), cadeias passo a passo (2C), redes (3). Nada inventado.
Modelo: experiments/diagnostico_auprc/modelos/baseline-0.keras (EfficientNetV2-S sem filtro, treino 0), Grad-CAM 2x.
As probabilidades vêm de esann_figs/fig1_candidates.csv (mesmo modelo, controle do protocolo: rng(0) sobre as 524 imagens).
Saídas: esann_materiais/paineis/<exame>/*.png, paineis/cadeias/*.png, dados/networks.csv, exame_escolhido.txt.
Uso (TF 2.13 CPU): ~/.venvs/tf213-cpu/bin/python esann_materiais/make_paineis_v3.py
"""
import json
import sys
from pathlib import Path

import cv2
import numpy as np
import pandas as pd

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
sys.path.insert(0, str(REPO / "pipeline"))
import utils_protocolo_xai as px  # noqa: E402
from utils_common import carregar_modelo_float32, get_paths  # noqa: E402
from utils_preprocessing import get_filter, parse_filter_name  # noqa: E402
from matplotlib import colormaps  # noqa: E402

SZ = px.SZ
OUT = AQUI / "paineis"; OUT.mkdir(exist_ok=True)
DADOS = AQUI / "dados"; DADOS.mkdir(exist_ok=True)
paths = get_paths(str(REPO))
cand = pd.read_csv(REPO / "esann_figs/fig1_candidates.csv")
split = json.load(open(REPO / "experiments/split.json"))
rd = lambda p: cv2.resize(cv2.cvtColor(cv2.imread(str(p)), cv2.COLOR_BGR2RGB), (SZ, SZ))
salva = lambda f, rgb: cv2.imwrite(str(f), cv2.cvtColor(np.ascontiguousarray(rgb), cv2.COLOR_RGB2BGR))

# ---- exames: o principal do v2 (1172_1) + 3 para a grade 1E (um por grau 2, 3, 4, pela regra relaxada)
principal = json.load(open(REPO / "esann_figs/fig1_info.json"))["imagem"]
pool = cand[(cand.grau >= 2) & (cand.p_original > 0.5) & (cand.controle_sobre_lesao <= 0.05) & (cand.controle_fora_fov <= 0.05)
            & (cand.n_componentes >= 3) & (cand.controle_mesma_forma)]
med = cand.A.median()
escolhidos = [principal]
for g in (2, 3, 4):
    sub = pool[(pool.grau == g) & (pool.imagem != principal)]
    if len(sub):
        escolhidos.append(sub.iloc[(sub.A - med).abs().argsort()].iloc[0].imagem)
for e in pool.sort_values("n_componentes", ascending=False).imagem:     # completa até 4 exames, se faltou um grau
    if len(escolhidos) >= 4: break
    if e not in escolhidos: escolhidos.append(e)

# ---- reconstrói máscaras, controle (mesma sequência do protocolo) e borrões
nomes, x, gts = [], [], []
for f in sorted(split["test"]):
    u = np.zeros((SZ, SZ), bool)
    for dd in paths["mask_dirs"].values():
        p = dd / f
        if p.exists():
            u |= cv2.resize((cv2.imread(str(p), cv2.IMREAD_GRAYSCALE) > 127).astype(np.uint8), (SZ, SZ), interpolation=cv2.INTER_NEAREST).astype(bool)
    if u.any(): nomes.append(f); gts.append(u); x.append(rd(paths["original_images"] / f))
x = np.array(x, np.float32); gts = np.array(gts); fovs = np.array([px.fov_mask(a.astype(np.uint8)) for a in x])
r0 = np.random.default_rng(0)
les = [cv2.dilate(m.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) for m in gts]
ctl = [px.deslocar(les[k], fovs[k], gts[k], r0) for k in range(len(les))]
modelo = carregar_modelo_float32(REPO / "experiments/diagnostico_auprc/modelos/baseline-0.keras")
nome2x = px.camadas_por_estagio(__import__("utils_gradcam")._get_backbone_submodel(modelo))["2x"][0]
info = []
for e in escolhidos:
    i = nomes.index(e); d = OUT / e.replace(".png", ""); d.mkdir(exist_ok=True)
    img = x[i].astype(np.uint8); borr = cv2.GaussianBlur(x[i], (0, 0), 10)
    dl, dc = x[i].copy(), x[i].copy(); dl[les[i]] = borr[les[i]]; dc[ctl[i]] = borr[ctl[i]]
    cam = px.gradcam(modelo, x[i][None], nome2x)[0] * fovs[i]
    h = np.clip(px._norm(cam), 0, 1).astype(np.float32)
    cor = colormaps["inferno"](h)[..., :3]; a = (0.15 + 0.7 * h)[..., None]
    c = (img / 255.0) * (1 - a) + cor * a; c[~fovs[i]] = 0; c8 = (c * 255).round().astype(np.uint8)
    cont, _ = cv2.findContours(gts[i].astype(np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
    c_cont = c8.copy(); cv2.drawContours(c_cont, cont, -1, (255, 255, 255), 1)
    ex_cont = img.copy(); cv2.drawContours(ex_cont, cont, -1, (255, 255, 255), 1)
    m3 = np.zeros((SZ, SZ, 3), np.uint8); m3[gts[i]] = 255
    cm = np.zeros((SZ, SZ, 3), np.uint8); cm[ctl[i]] = 255
    salva(d / "A_exame.png", img); salva(d / "A_exame_contorno.png", ex_cont); salva(d / "B_mascara.png", m3)
    salva(d / "C_gradcam.png", c8); salva(d / "C_gradcam_contorno.png", c_cont)
    salva(d / "D_lesoes_borradas.png", dl.astype(np.uint8)); salva(d / "E_controle_borrado.png", dc.astype(np.uint8)); salva(d / "E_mascara_controle.png", cm)
    salva(d / "G_gradcam_mapa.png", (np.stack([h] * 3, -1) * 255).astype(np.uint8))
    r = cand[cand.imagem == e].iloc[0]
    info.append(dict(imagem=e, divisao="teste", grau=int(r.grau), rede="EfficientNetV2-S sem filtro", treino=0, camada_gradcam=f"2x ({nome2x}, 19x19)",
                     p_original=float(r.p_original), p_lesoes_borradas=float(r.p_lesoes_borradas), p_controle_borrado=float(r.p_controle_borrado),
                     A_da_imagem_pontos=float(100 * r.A), n_regioes=int(r.n_componentes), area_mascara_pct=float(100 * r.area_mascara_px / SZ / SZ),
                     controle_sobre_lesao=float(r.controle_sobre_lesao), papel="principal (1A-1D)" if e == principal else "grade 1E"))
(AQUI / "exame_escolhido.txt").write_text(
    "Exame principal (1A-1D e figuras com um exame): " + principal + "\nRegra: a do v2 (esann_figs/make_fig1_panels.py): teste; grau>=2; p>0,5; controle de mesma forma, 0% sobre lesao e 0% fora do FOV; "
    ">=5 componentes; area acima da mediana; A mais proximo da mediana de A (so 2 candidatas). O exame do ERAMIA (0361_1.png) foi descartado: controle 29% sobre lesao anotada, A negativo.\n"
    "Grade 1E: o principal + 1 exame por grau 2, 3 e 4 pela regra relaxada (p>0,5; controle <=5% sobre lesao e fora do FOV; mesma forma; >=3 regioes; A mais proximo da mediana de A das 524).\n\n"
    + pd.DataFrame(info).T.to_string() + "\n")
pd.DataFrame(info).to_csv(DADOS / "exames_escolhidos.csv", index=False)

# ---- galeria de filtros do exame principal
d = OUT / principal.replace(".png", ""); orig = cv2.cvtColor(cv2.imread(str(paths["original_images"] / principal)), cv2.COLOR_BGR2RGB)
FILT = ["BenGraham", "Gamma0.8", "Retinex", "HistogramEq", "LABNorm", "GreenChannel", "MaxGreen2.0", "Grayscale", "AHE40.0", "CLAHE4.0",
        "Unsharp1.5", "Median", "Gaussian", "Morpho", "Frangi", "Canny", "Otsu"]
salva(d / "filtro_Unfiltered.png", cv2.resize(orig, (SZ, SZ)))
for f in FILT:
    salva(d / f"filtro_{f}.png", cv2.resize(get_filter(f, parse_filter_name(f)[1]).apply(orig), (SZ, SZ)))

# ---- cadeias exemplares passo a passo
ps = pd.read_csv(DADOS / "pipelines_summary.csv") if (DADOS / "pipelines_summary.csv").exists() else pd.read_csv(REPO / "esann_figs/pipelines_summary.csv")
quatro = ps[(ps.n_filtros == 4) & ((ps.AUC_mean4 - ps[ps.pipeline == "unfiltered"].AUC_mean4.iloc[0]).abs() <= 0.01)].sort_values("A_points_mean4")
cadeias = ["BenGraham_CLAHE4.0_Gaussian", "AHE40.0_Gaussian", "LABNorm_Grayscale", "LABNorm_GreenChannel_Median"]
if len(quatro): cadeias.append(quatro.iloc[len(quatro) // 2].condicao_id)
(OUT / "cadeias").mkdir(exist_ok=True); linhas = []
for ch in cadeias:
    partes = ch.split("_")
    for j in range(1, len(partes) + 1):
        sub = "_".join(partes[:j])
        salva(OUT / "cadeias" / f"{ch}__passo{j}.png", cv2.resize(get_filter(sub, parse_filter_name(sub)[1]).apply(orig), (SZ, SZ)))
    r = ps[ps.condicao_id == ch].iloc[0]
    linhas.append(dict(condicao_id=ch, chain=r.pipeline, n_passos=len(partes), AUC_mean4=r.AUC_mean4, A_points_mean4=r.A_points_mean4))
pd.DataFrame(linhas).to_csv(DADOS / "chains_exemplares.csv", index=False)
salva(OUT / "cadeias" / "exame_original.png", cv2.resize(orig, (SZ, SZ)))
# miniaturas finais das 2 menores e 2 maiores cadeias de AUC parecida (Figura 6C)
sim = pd.read_csv(DADOS / "chains_similar_auc.csv").sort_values("A_points_mean4")
ext = list(sim.pipeline.iloc[:2]) + list(sim.pipeline.iloc[-2:])
(OUT / "extremas").mkdir(exist_ok=True)
for nome in ext:
    cid = "_".join(nome.split(" > "))
    salva(OUT / "extremas" / f"{cid}.png", cv2.resize(get_filter(cid, parse_filter_name(cid)[1]).apply(orig), (SZ, SZ)))
pd.DataFrame(dict(chain=ext)).to_csv(DADOS / "chains_extremas.csv", index=False)

# ---- redes: parâmetros (backbone sem topo, Keras), tamanho de entrada, épocas até a parada, AUC e A sem filtro
import tensorflow as tf  # noqa: E402
bk = {"efficientnetv2s": (tf.keras.applications.EfficientNetV2S, "EfficientNetV2", 20_000_000), "efficientnetv2b2": (tf.keras.applications.EfficientNetV2B2, "EfficientNetV2", 0),
      "inceptionv3": (tf.keras.applications.InceptionV3, "Inception", 0), "resnet50": (tf.keras.applications.ResNet50, "ResNet", 0)}
dd = pd.read_csv(REPO / "experiments/analise_h3/por_execucao.csv"); dd = dd[dd.condicao == "baseline"]
OFF = dict(zip(bk, (0, 100, 200, 300))); nets = []
for a, (fn, fam, _) in bk.items():
    m = fn(include_top=False, weights=None, input_shape=(299, 299, 3))
    ep = []
    for s in (20, 21, 22):
        n = 0
        for ph in ("phase1_warmup", "phase2_finetune"):
            f = Path.home() / "resultados" / f"baseline-{OFF[a] + s}-{ph}.csv"
            if f.exists(): n += len(pd.read_csv(f))
        if n: ep.append(n)
    g = dd[dd.arch == a]
    nets.append(dict(arch=a, family=fam, params_millions_backbone=m.count_params() / 1e6, input_size=299, flops="not recorded",
                     train_minutes="not recorded per run (V2S ~8, ResNet-50 ~19 in the DDR trial; phase 3 logs)", epochs_mean=float(np.mean(ep)) if ep else np.nan,
                     auc_unfiltered_mean=g.AUC.mean(), auc_unfiltered_sd=g.AUC.std(ddof=1), A_unfiltered_points=100 * g.A.mean()))
pd.DataFrame(nets).to_csv(DADOS / "networks.csv", index=False)
print("paineis ok; exames:", escolhidos)
