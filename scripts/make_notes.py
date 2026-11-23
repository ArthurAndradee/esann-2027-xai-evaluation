#!/usr/bin/env python3
"""Gera ddr_notes.txt: fatos sobre a validação externa no DDR (nada de texto de artigo; só registro para o usuário).
Números vêm de ddr_results.csv (make_ddr.py) e dos documentos do repositório."""
import json
import re
from pathlib import Path

import pandas as pd

AQUI = Path(__file__).resolve().parent
REPO = AQUI.parent
d = pd.read_csv(AQUI / "ddr_results.csv").set_index("arch")
cong = json.load(open(REPO / "experiments/analise_fase2b/resumo.json"))
logit = json.load(open(REPO / "experiments/analise_fase2b_logit/resumo.json"))
t2b = pd.read_csv(REPO / "experiments/analise_fase2b/testes_por_arquitetura.csv")
interp = json.load(open(REPO / "experiments/diagnostico_ddr/interpolacao.json"))
pre = (REPO / "experiments/PREREGISTRO_FASE2.md").read_text()
h = {k: re.search(rf"\*\*{k} · [^\n]*", pre).group(0) for k in ("H4", "H5a", "H5b")}
N = {"efficientnetv2s": "EfficientNetV2-S", "efficientnetv2b2": "EfficientNetV2-B2", "inceptionv3": "InceptionV3", "resnet50": "ResNet-50"}
F = {"CLAHE4.0": "CLAHE", "GreenChannel": "Green channel", "Grayscale": "Grayscale"}

L = ["# Validação externa no DDR (H4, H5a, H5b): registro para o usuário. Texto do artigo é seu.\n"]
L.append("## O que foi feito (e um aviso sobre o enunciado)\n"
         "Modelos TREINADOS NO FGADR (as 4 redes, 4 condições: sem filtro, CLAHE, Green channel, Grayscale; 10 seeds; 160 treinos) e AVALIADOS no DDR, sem nenhum ajuste. "
         "Este é a 'fase 2b' (repetições 70-79, 170-179, 270-279, 370-379), que repete a fase 2 original (repetições 40-49) depois da correção D5 (interpolação do DDR). "
         "O DDR nunca entrou em treino neste estudo até aqui. Treinar no próprio DDR é uma fase 3 SEPARADA, pré-registrada e EM EXECUÇÃO (360 treinos; ~metade concluída em 16/11/2026); "
         "NÃO há resultado dela para o artigo ainda e ela não deve ser citada como resultado.\n")
L.append("## Resultado\n"
         "Pré-condição pré-registrada: AUC do sem filtro no DDR ≥ 0,70 (e DP de p(RD) ≥ 0,05), em ≥ 3 das 4 redes. "
         "Resultado: só a InceptionV3 passa; logo H4, H5a e H5b ficam INCONCLUSIVAS (nem confirmadas nem refutadas), na escala de probabilidade e na escala logit (sensibilidade D7).")
L.append("rede | treinos (4 cond.) | AUC sem filtro no DDR (IC 95%) | atinge 0,70? | AUC sem filtro no FGADR")
for a in d.index:
    r = d.loc[a]
    L.append(f"{N[a]} | {int(r.n_trainings_total)} | {r.auc_unfiltered_ddr:.3f} [{r.auc_ci95_low:.3f}; {r.auc_ci95_high:.3f}] | {'sim' if r.meets_threshold else 'não'} | {r.auc_unfiltered_fgadr:.3f}")
L.append("\nVeredito geral (regra pré-registrada): H4 " + cong["hipoteses"]["H4"]["veredito"] + "; H5a " + cong["hipoteses"]["H5a"]["veredito"] + "; H5b " + cong["hipoteses"]["H5b"]["veredito"] +
         f". (Logit: H4 {logit['hipoteses']['H4']['veredito']}; H5a {logit['hipoteses']['H5a']['veredito']}; H5b {logit['hipoteses']['H5b']['veredito']}.)")
L.append("\nSó a InceptionV3 foi testada (regra pré-registrada); os números das outras 3 redes são DESCRITIVOS (marcador vazado na Figura 4):")
for a in d.index:
    r = d.loc[a]
    L.append(f"- {N[a]} (A sem filtro {r.A_unfiltered_points:.1f} pontos): " + "; ".join(
        f"{F[f]}: A {r[f'A_{f}_points']:.1f}, mantém {r[f'kept_{f}_percent']:.0f}% [{r[f'kept_{f}_ci95_low']:.0f}; {r[f'kept_{f}_ci95_high']:.0f}], ΔA {r[f'dA_{f}_points']:+.1f} [{r[f'dA_{f}_ci95_low']:+.1f}; {r[f'dA_{f}_ci95_high']:+.1f}], ΔAUC {r[f'dAUC_{f}']:+.3f}" for f in F))
ic = t2b[(t2b.arch == "inceptionv3")]
L.append("\nInceptionV3 (única apta), teste pré-registrado (dA em probabilidade; IC hierárquico; Holm entre os 3 testes): " + "; ".join(
    f"{r.hipotese} {r.filtro}: ΔA {100*r.dA:+.1f} pontos [{100*r.dA_ic_inf:+.1f}; {100*r.dA_ic_sup:+.1f}], p Holm {r.p_holm:.4f}, vale = {bool(r.vale)}" for r in ic.itertuples()) +
         ". Ou seja, no DDR o CLAHE reduz como no FGADR, mas Green channel e Grayscale TAMBÉM reduzem (no FGADR aumentam), com perda grande de AUC (ΔAUC −0,088 e −0,142 nessa rede).")
L.append("\n## Números de imagens\n"
         "AUC: 3.759 imagens de teste da graduação do DDR (grau 5 excluído; graus 0-1 → não referável 2.069, 2-4 → referável 1.690) ✓ (esperado 3.759).\n"
         "Ablação (A): **756** imagens com máscara (EX, HE, MA ou SE), NÃO 757: das 757 imagens de segmentação do DDR, uma não tem nenhuma máscara desses 4 tipos. "
         "(O DDR não tem máscaras de IRMA nem de neovasos; no FGADR há 6 tipos.) Diverge do 757 esperado em 1 imagem.")
L.append("\n## Texto exato de H4 e H5 (PREREGISTRO_FASE2.md, congelado em 2026-11-01)")
L += [h[k] for k in ("H4", "H5a", "H5b")]
m = re.search(r"Regras exatas \(fixadas antes dos dados\):\n(.*?)\n\n- \*\*H4", pre, re.S)
L.append("Regra de validade e inferência (resumo fiel do documento): ΔA = A(filtro) − A(sem filtro) no DDR (A = ablação pós-filtro, média nas imagens com lesão; média das seeds). "
         "Bootstrap hierárquico, 10.000 reamostragens, seeds de cada condição sorteadas com reposição de forma independente e imagens pareadas; teste unilateral, α = 0,05, Holm entre os 3 testes de cada rede. "
         "Vale na rede se o sinal pontual é o previsto E p ajustado < 0,05. Hipótese confirmada se vale em ≥ 3 das 4 redes; inconclusiva se < 3 redes passam a pré-condição.")
L.append("\n## Por que CLAHE e a remoção de cor foram os casos de teste (registro)\n"
         "Foram escolhidos DEPOIS de ver a fase 1a no FGADR, não antes: o pré-registro da fase 1 previa testar no DDR só os filtros que 'dissociassem' (H1), e nenhum dissociou. "
         "Então as hipóteses H4/H5 são NOVAS e geradas pelos dados da 1a: (i) o CLAHE reduziu o uso das lesões (nas 4 redes na estimativa pontual; em 3 das 4 depois de incluir a variação entre seeds) com custo de AUC pequeno; "
         "(ii) Green channel e Grayscale AUMENTARAM o uso das lesões (achado exploratório não previsto; 3 das 4 redes). Por isso foram testados só em dados que não participaram de nada (modelos novos, seeds novas, DDR). "
         "As 5 condições de maior AUC média, previstas na seção 7 do pré-registro da fase 1, foram dispensadas por decisão do usuário (2026-11-01): diferenças menores que o ruído entre seeds.")
L.append("\n## Desvios registrados (PREREGISTRO_FASE2_DESVIOS.md e correlatos)\n"
         "- Fase 2 original (reps 40-49): 160 treinos; pré-condição falhou nas 4 redes (AUC no DDR 0,652 a 0,682); H4/H5 inconclusivas.\n"
         "- D5: as imagens do DDR eram reduzidas a 299 px com INTER_LINEAR e o FGADR com INTER_AREA (contra a especificação 'exatamente como no FGADR'); corrigido e refeito como fase 2b (160 treinos novos). "
         "A fase 2b foi decidida DEPOIS de ver a pré-condição falhar; isso deve ser dito. A pré-condição não mudou.\n"
         "- D6: bug do vigia (só execução). D7: A também na escala logit, como sensibilidade (prevalência 83% no FGADR contra 45% no DDR); sem divergência entre escalas. "
         "D8: o vigia falhou o portão de checksum por um bug meu; a análise foi rodada à mão com os scripts congelados intactos.\n"
         "- Nenhuma regra de decisão foi alterada depois de ver dados da 2b.")
L.append("\n## Integridade do DDR (verificada em 2026-11-13)\n"
         "Os arquivos do DDR usados no estudo foram comparados por SHA-256 com o download OFICIAL dos autores (Google Drive, zip em 10 partes, 18.218 entradas): "
         "4.106 arquivos da graduação idênticos e 3.785 da segmentação (imagens e máscaras) idênticos pelo mesmo nome; 0 diferentes. "
         "Única ausência no oficial: o README.md do espelho (que, aliás, atribui o dataset a outros autores). O espelho (Hugging Face via Kaggle) só reorganiza as pastas "
         "(images/{test,train,val} → {test,train,valid}/image; annotations → label). Licença oficial CC BY-NC-SA 4.0 (o espelho diz CC BY 4.0, errado); citar Li et al., Information Sciences 501 (2019) 511-522. "
         "Detalhes: data/externo/DDR/LICENCA_E_ORIGEM.md; experiments/diagnostico_ddr/.")
L.append("\n## Por que o desempenho no DDR é baixo (o que foi testado e o que é hipótese)\n"
         f"- TESTADO e descartado: interpolação. V2S, AUC {interp['INTER_LINEAR']['auc']:.3f} (LINEAR) contra {interp['INTER_AREA']['auc']:.3f} (AREA).\n"
         f"- MEDIDO: AUC por grau (sem filtro, V2S, interpolação AREA): grau 0 contra 3 = {interp['INTER_AREA']['auc_0_vs_3']:.2f}; contra 2 = {interp['INTER_AREA']['auc_0_vs_2']:.2f}; contra 1 = {interp['INTER_AREA']['auc_0_vs_1']:.2f}; contra 4 = {interp['INTER_AREA']['auc_0_vs_4']:.2f}. "
         f"O modelo separa bem o grau 3, mas falha no grau 2, que é a maioria dos referáveis no DDR ({interp['n_por_grau']['2']} de {interp['referaveis']}; no teste: grau 0 {interp['n_por_grau']['0']}, 1 {interp['n_por_grau']['1']}, 2 {interp['n_por_grau']['2']}, 3 {interp['n_por_grau']['3']}, 4 {interp['n_por_grau']['4']}). "
         "Leitura registrada: domínio/critério de graduação, não pré-processamento.\n"
         "- HIPÓTESES NÃO TESTADAS: câmera e resolução diferentes (DDR ~1.700-2.000 px, várias câmeras; FGADR 1.280 px), prevalência (83% referável no FGADR contra 45% no DDR), critério de rotulagem do grau 2.")
L.append("\n## Figura 4 (decisão de desenho)\n"
         "Para cada filtro (CLAHE, Green channel, Grayscale) e rede: ponto = confiança mantida no DDR com IC 95% (bootstrap hierárquico de seeds e imagens), cruz = valor no FGADR; marcador vazado = rede com AUC do sem filtro < 0,70 no DDR (descritivo). "
         "Atenção: o IC da razão pode ser enorme quando o A do sem filtro no DDR é pequeno (denominador próximo de zero); a coluna *_unstable_denominator_share de ddr_results.csv informa.")
(AQUI / "ddr_notes.txt").write_text("\n".join(L) + "\n")
print("ddr_notes.txt gerado")
