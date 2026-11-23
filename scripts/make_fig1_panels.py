#!/usr/bin/env python3
"""
Painéis da Figura 1 do artigo ESANN 2027 (a imagem de exame é a mesma em todos). Nada é inventado:
  - imagem: 0361_1.png, a mesma da Figura 1 do ERAMIA e dos slides (divisão de teste);
  - modelo: EfficientNetV2-S sem filtro, seed 0 (experiments/diagnostico_auprc/modelos/baseline-0.keras);
  - Grad-CAM na camada interpretada da V2S (2x, block6a_expand_activation, 19x19; camadas_escolhidas_emenda4.json),
    com as funções do protocolo (pipeline/utils_protocolo_xai.py);
  - borrão (gaussiano, sigma 10 a 299 px), máscara dilatada 3x3 e controle deslocado: as mesmas funções do
    protocolo. O controle usa a MESMA sequência aleatória da campanha: rng(0) percorrendo as 524 imagens de teste
    com lesão em ordem alfabética (utils_protocolo_xai.avaliar, alvo "todas"), e pega-se o da imagem 0361_1.
  - filtros: get_filter sobre a original RGB em 1280 px (como script1_cria_dataset.py), depois 299 x 299
    (cv2.resize linear, como o carregamento do modelo): o que a rede vê.
Saída: esann_figs/fig1_panels/*.png (299 x 299) e fig1_info.txt / fig1_info.json.
Uso (ambiente com TF 2.13 CPU): ~/.venvs/tf213-cpu/bin/python esann_figs/make_fig1_panels.py
"""
import json
import sys
from pathlib import Path

import cv2
import numpy as np

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
sys.path.insert(0, str(REPO / "pipeline"))
import utils_protocolo_xai as px  # noqa: E402
from utils_common import carregar_modelo_float32, get_paths  # noqa: E402
from utils_preprocessing import get_filter, parse_filter_name  # noqa: E402

NOME = "0361_1.png"
SZ = px.SZ
OUT = AQUI / "fig1_panels"
OUT.mkdir(exist_ok=True)
FILTROS = ["Unfiltered", "BenGraham", "Gamma0.8", "Retinex", "HistogramEq", "LABNorm", "GreenChannel", "MaxGreen2.0",
           "Grayscale", "AHE40.0", "CLAHE4.0", "Unsharp1.5", "Median", "Gaussian", "Morpho", "Frangi", "Canny", "Otsu"]


def salva(nome, rgb):
    cv2.imwrite(str(OUT / nome), cv2.cvtColor(np.ascontiguousarray(rgb), cv2.COLOR_RGB2BGR))


def main():
    paths = get_paths(str(REPO))
    split = json.load(open(REPO / "experiments" / "split.json"))
    assert NOME in split["test"] and NOME not in split["train"]
    rd = lambda p: cv2.resize(cv2.cvtColor(cv2.imread(str(p)), cv2.COLOR_BGR2RGB), (SZ, SZ))

    # imagens de teste com lesão, na ordem do protocolo (sorted), sem filtro
    nomes, x, orig, gts = [], [], [], []
    for f in sorted(split["test"]):
        uniao = np.zeros((SZ, SZ), bool)
        for d in paths["mask_dirs"].values():
            p = d / f
            if p.exists():
                uniao |= cv2.resize((cv2.imread(str(p), cv2.IMREAD_GRAYSCALE) > 127).astype(np.uint8), (SZ, SZ),
                                    interpolation=cv2.INTER_NEAREST).astype(bool)
        if uniao.any():
            nomes.append(f); gts.append(uniao); x.append(rd(paths["original_images"] / f))
    assert len(nomes) == 524, len(nomes)
    x = np.array(x, np.float32); gts = np.array(gts)
    fovs = np.array([px.fov_mask(a.astype(np.uint8)) for a in x])    # = FOV da original (sem filtro, mesma imagem)
    i = nomes.index(NOME)

    # controle deslocado: mesma sequência do protocolo (rng(0) sobre todas as imagens, alvo "todas")
    rng = np.random.default_rng(0)
    les = [cv2.dilate(m.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) for m in gts]
    ctl = [px.deslocar(les[k], fovs[k], gts[k], rng) for k in range(len(les))]
    modelo = carregar_modelo_float32(REPO / "experiments" / "diagnostico_auprc" / "modelos" / "baseline-0.keras")
    cams = px.camadas_por_estagio(__import__("utils_gradcam")._get_backbone_submodel(modelo))
    nome2x = cams["2x"][0]
    assert nome2x == "block6a_expand_activation", nome2x
    borr = np.array([cv2.GaussianBlur(a, (0, 0), 10) for a in x])
    p0 = px.prever(modelo, x)
    pl = px.prever(modelo, px.aplica(x, borr, les))
    pc = px.prever(modelo, px.aplica(x, borr, ctl))
    import pandas as pd
    grau_df = pd.read_csv(paths["labels_csv"], header=None).set_index(0)[1]
    tab = pd.DataFrame(dict(
        imagem=nomes, grau=[int(grau_df[n]) for n in nomes], p_original=p0, p_lesoes_borradas=pl, p_controle_borrado=pc,
        A=pc - pl, area_mascara_px=[int(m.sum()) for m in les], area_controle_px=[int(m.sum()) for m in ctl],
        controle_mesma_forma=[bool(a.sum() == b.sum()) for a, b in zip(les, ctl)],
        controle_sobre_lesao=[float((c & g).sum() / max(1, c.sum())) for c, g in zip(ctl, gts)],
        controle_fora_fov=[float((c & ~f).sum() / max(1, c.sum())) for c, f in zip(ctl, fovs)],
        n_componentes=[int(cv2.connectedComponents(g.astype(np.uint8))[0] - 1) for g in gts]))
    tab.to_csv(AQUI / "fig1_candidates.csv", index=False)
    A_med = float(tab.A.mean()); A_mediana = float(tab.A.median())
    # regra de escolha (fixada antes de olhar as imagens): teste (já), referável (grau >= 2), corretamente
    # classificada (p > 0,5), controle com a MESMA forma (sem corte), 0% sobre lesão anotada e 0% fora do FOV,
    # >= 5 componentes de lesão e área de máscara acima da mediana; entre elas, a de A mais próximo da MEDIANA de A.
    ok = tab[(tab.grau >= 2) & (tab.p_original > 0.5) & tab.controle_mesma_forma & (tab.controle_sobre_lesao == 0)
             & (tab.controle_fora_fov == 0) & (tab.n_componentes >= 5) & (tab.area_mascara_px > tab.area_mascara_px.median())]
    eramia = tab[tab.imagem == NOME].iloc[0]
    escolhida = ok.iloc[(ok.A - A_mediana).abs().argsort()].iloc[0].imagem
    i = nomes.index(escolhida)
    orig_rgb = cv2.cvtColor(cv2.imread(str(paths['original_images'] / escolhida)), cv2.COLOR_BGR2RGB)
    les_i, ctl_i = les[i], ctl[i]
    forma_igual = bool(les_i.sum() == ctl_i.sum())
    sobre_lesao = float((ctl_i & gts[i]).sum() / max(1, ctl_i.sum()))
    fora_fov = float((ctl_i & ~fovs[i]).sum() / max(1, ctl_i.sum()))
    comp_les, comp_ctl = x[i].copy(), x[i].copy()
    comp_les[les_i] = borr[i][les_i]; comp_ctl[ctl_i] = borr[i][ctl_i]
    p0, pl, pc = float(p0[i]), float(pl[i]), float(pc[i])
    cam = px.gradcam(modelo, x[i][None], nome2x)[0] * fovs[i]

    # painéis
    img = x[i].astype(np.uint8)
    salva("A_exame.png", img)
    m = np.zeros((SZ, SZ, 3), np.uint8); m[gts[i]] = 255
    salva("B_lesoes.png", m)
    h = np.clip(px._norm(cam), 0, 1).astype(np.float32)
    from matplotlib import colormaps
    cor = colormaps["inferno"](h)[..., :3]
    a = (0.15 + 0.7 * h)[..., None]
    c = (img / 255.0) * (1 - a) + cor * a
    c[~fovs[i]] = 0
    cont, _ = cv2.findContours(gts[i].astype(np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
    c8 = (c * 255).round().astype(np.uint8)
    cv2.drawContours(c8, cont, -1, (255, 255, 255), 1)
    salva("C_gradcam.png", c8)
    salva("D_lesoes_borradas.png", comp_les.astype(np.uint8))
    salva("E_controle_borrado.png", comp_ctl.astype(np.uint8))
    # máscaras de D e E sobre o exame (referência, não entram na figura)
    # galeria de filtros
    for f in FILTROS:
        if f == "Unfiltered":
            im = orig_rgb
        else:
            im = get_filter(f, parse_filter_name(f)[1]).apply(orig_rgb)
        salva(f"filtro_{f}.png", cv2.resize(im, (SZ, SZ)))

    A = (p0 - pl) - (p0 - pc)
    info = dict(imagem=escolhida, divisao="teste", grau=int(grau_df[escolhida]), rede="EfficientNetV2-S sem filtro", seed=0,
                modelo="experiments/diagnostico_auprc/modelos/baseline-0.keras",
                camada_gradcam=f"2x ({nome2x}, 19x19)", p_original=p0, p_lesoes_borradas=pl, p_controle_borrado=pc,
                queda_lesao=p0 - pl, queda_controle=p0 - pc, A_da_imagem=A, pixels_mascara=int(les_i.sum()),
                pixels_controle=int(ctl_i.sum()), mascara_e_controle_mesma_forma=forma_igual,
                fracao_do_controle_sobre_lesao_anotada=sobre_lesao, fracao_do_controle_fora_do_fov=fora_fov,
                borrao="gaussiano sigma 10 px a 299 px; mascara dilatada 3x3 (protocolo)",
                controle="mesma sequencia aleatoria da campanha (rng(0) sobre as 524 imagens, alvo todas)",
                A_medio_das_524_imagens_deste_modelo=A_med, A_mediana_das_524=A_mediana, n_candidatas=int(len(ok)),
                regra_de_escolha="teste; grau>=2; p>0,5; controle de mesma forma, 0% sobre lesao anotada e 0% fora do FOV; >=5 componentes; "
                                 "area de mascara > mediana; entre as candidatas, A mais proximo da mediana de A das 524",
                exame_do_ERAMIA=dict(imagem=NOME, p_original=float(eramia.p_original), p_lesoes_borradas=float(eramia.p_lesoes_borradas),
                                     p_controle_borrado=float(eramia.p_controle_borrado), A=float(eramia.A),
                                     controle_sobre_lesao=float(eramia.controle_sobre_lesao),
                                     controle_mesma_forma=bool(eramia.controle_mesma_forma),
                                     motivo_de_nao_usar="o controle cai " + f"{100*eramia.controle_sobre_lesao:.0f}% sobre lesao anotada e o A da imagem e negativo"))
    (AQUI / "fig1_info.json").write_text(json.dumps(info, indent=1, ensure_ascii=False))
    (AQUI / "fig1_info.txt").write_text("\n".join(f"{k}: {v}" for k, v in info.items()) + "\n")
    print(json.dumps(info, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    main()
