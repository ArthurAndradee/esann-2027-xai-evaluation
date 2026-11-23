# Prompt v4: novas versões. Numeração do PROMPT: fig4 = AUC x lesion reliance (versões A-D); fig3 = efeito dos filtros (versões B-C).
# Estilo limpo (SSCAD/ERAD/CBMS): P&B, no máximo 1 cor de destaque, sem nuvens sobrepostas, legenda com <= 4 entradas, séries por forma e luminância.
# Uso (na pasta esann_materiais/): Rscript make_figuras_v7.R   -> novas_v4/ (PDF, PNG 300 dpi, _gray.png, contact_fig3.png, contact_fig4.png)
lines <- readLines("make_figuras_v3.R"); k <- grep("^# =+ FIGURA 1", lines)[1]; kc <- grep("^# =+ folhas de contato", lines)[1]; ka <- grep("^args <- commandArgs", lines)[1]
eval(parse(text = lines[1:(k - 1)])); eval(parse(text = lines[kc:(ka - 1)]))      # helpers (tema, sg, nome_arq, ...) e contato()
FIG <- "novas_v4"; dir.create(FIG, showWarnings = FALSE)
ACC <- "#1f5fa8"; CUR <- c("EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50"); SHP <- c(16, 15, 17, 18); GRY <- c("black", "grey25", "grey45", "grey60")
STAGE <- c("Illumination", "Color", "Local contrast", "Refinement")
STG <- c(BenGraham = 1, Gamma0.8 = 1, Retinex = 1, HistogramEq = 1, LABNorm = 1, GreenChannel = 2, MaxGreen2.0 = 2, Grayscale = 2, AHE40.0 = 3, CLAHE4.0 = 3, Unsharp1.5 = 4, Median = 4, Gaussian = 4, Morpho = 4, Frangi = 4, Canny = 4, Otsu = 4)
lad <- rd("correlations_ladder.csv"); lad$rede <- factor(CUR[match(lad$arch, ARCH)], CUR)
TIPO <- c("between pipelines", "between, AUC in [0.89, 0.915]", "between runs of one pipeline")
tlim <- function() theme(panel.grid.major = element_line(colour = "grey92", linewidth = 0.25))

# ---- barras agrupadas (estilo ERAD): rho entre pipelines x rho entre os 3 treinos, IC 95%
barras <- function(legenda = TRUE, ytxt = 6.4) {
  d <- lad[lad$tipo %in% TIPO[c(1, 3)], ]; d$grupo <- factor(ifelse(d$tipo == TIPO[1], "between pipelines", "between the 3 runs of a pipeline"), c("between pipelines", "between the 3 runs of a pipeline"))
  pd <- position_dodge(0.75)
  ggplot(d, aes(rede, rho, fill = grupo)) + geom_col(position = pd, width = 0.68, colour = "grey15", linewidth = 0.3) +
    geom_errorbar(aes(ymin = ci95_low, ymax = ci95_high), position = pd, width = 0.18, linewidth = 0.35) +
    geom_text(aes(y = pmax(ci95_high, rho) + 0.085, label = sprintf("%.2f", rho)), position = pd, size = 6.4 * PT, family = FONTE) +
    scale_fill_manual(values = c(ACC, "grey85")) + scale_y_continuous(limits = c(-0.1, 1.2), breaks = c(0, 0.5, 1), expand = c(0, 0)) +
    labs(x = NULL, y = "Spearman ρ (AUC, A)") + geom_hline(yintercept = 0, linewidth = 0.3) + tema() + tlim() +
    theme(legend.position = if (legenda) "bottom" else "none", legend.title = element_blank(), legend.text = element_text(size = 6.4), legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -3))
}
versao(4, "A", 3.2, sg(barras(), 4, "A", 3.2))

# ---- linhas com marcadores (estilo SSCAD): queda da correlação entre as 3 categorias
d <- lad; d$x <- match(d$tipo, TIPO); pdg <- position_dodge(0.2)
g4b <- ggplot(d, aes(x, rho, shape = rede, colour = rede, group = rede)) + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey50") +
  geom_line(position = pdg, linewidth = 0.4) + geom_errorbar(aes(ymin = ci95_low, ymax = ci95_high), position = pdg, width = 0, linewidth = 0.3) + geom_point(position = pdg, size = 1.7, fill = "white") +
  scale_shape_manual(values = SHP) + scale_colour_manual(values = GRY) +
  scale_x_continuous(breaks = 1:3, labels = c("between pipelines", "between pipelines,\nAUC 0.89–0.915", "between runs of\nthe same pipeline"), expand = expansion(add = 0.3)) +
  scale_y_continuous(breaks = c(0, 0.5, 1), limits = c(-0.25, 1.0)) + labs(x = NULL, y = "Spearman ρ (AUC, A)") + tema() + tlim() +
  theme(legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 6.4), legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -3), axis.text.x = element_text(lineheight = 0.9)) +
  guides(shape = guide_legend(nrow = 1), colour = guide_legend(nrow = 1))
versao(4, "B", 3.4, sg(g4b, 4, "B", 3.4))

# ---- dois painéis: (a) uma rede, (b) as barras
ps2 <- read.csv("../esann_figs/fig3_pipelines_v2s.csv"); ps2 <- ps2[as.character(ps2$deg) %in% c("False", "FALSE"), ]
rr <- read.csv("../esann_figs/fig3_runs_destacados.csv"); mA <- tapply(rr$Apts, rr$condicao, mean); sel <- names(sort(mA))[c(1, 3, 5)]; rr <- rr[rr$condicao %in% sel, ]
pa <- ggplot(ps2, aes(AUC, A)) + annotate("rect", xmin = 0.89, xmax = 0.915, ymin = -Inf, ymax = Inf, fill = "grey90") + geom_point(size = 0.6, colour = "grey65", stroke = 0) +
  geom_smooth(method = "loess", se = FALSE, colour = "black", linewidth = 0.5, formula = y ~ x) +
  geom_path(data = rr, aes(AUC, Apts, group = condicao), colour = ACC, linewidth = 0.6) + geom_point(data = rr, aes(AUC, Apts), colour = ACC, size = 1.4) +
  scale_x_continuous(breaks = c(0.75, 0.85, 0.90)) + coord_cartesian(xlim = c(0.7, 0.93)) + labs(x = "AUC", y = "Lesion reliance A (points)", title = "(a) EfficientNetV2-S") + tema() + tlim() +
  theme(plot.title.position = "panel", plot.title = element_text(face = "bold", size = 7.2))
pb <- barras(legenda = TRUE) + labs(title = "(b)") + theme(plot.title.position = "panel", plot.title = element_text(face = "bold", size = 7.2), axis.text.x = element_text(size = 5.9)) + scale_x_discrete(labels = c("EffNetV2\nS", "EffNetV2\nB2", "Inception\nV3", "ResNet\n50"))
versao(4, "C", 4.6, sg(suppressMessages(pa + pb + plot_layout(widths = c(1, 1.15))), 4, "C", 4.6))

# ---- quatro mini dispersões
pl <- rd("pipelines_long.csv"); pm <- aggregate(cbind(AUC, A_points) ~ chain + arch, pl, mean); pm$rede <- factor(CUR[match(pm$arch, ARCH)], CUR)
bet <- lad[lad$tipo == TIPO[1], ]; wit <- lad[lad$tipo == TIPO[3], ]
ann <- data.frame(rede = factor(CUR, CUR), lab = sprintf("ρ pipelines = %.2f\nρ runs = %.2f", bet$rho, wit$rho))
g4d <- ggplot(pm, aes(AUC, A_points)) + geom_point(size = 0.55, colour = "grey70", stroke = 0) + geom_smooth(method = "loess", se = FALSE, colour = "black", linewidth = 0.5, formula = y ~ x) +
  geom_text(data = ann, aes(label = lab), x = 0.46, y = Inf, hjust = 0, vjust = 1.25, size = 6.3 * PT, family = FONTE, lineheight = 0.95, inherit.aes = FALSE) +
  facet_wrap(~rede, nrow = 1) + scale_x_continuous(breaks = c(0.5, 0.7, 0.9)) + coord_cartesian(xlim = c(0.45, 0.95)) + labs(x = "AUC (pipeline mean)", y = "A (points)") + tema() + tlim() + theme(panel.spacing = unit(0.2, "cm"))
versao(4, "D", 3.6, sg(suppressMessages(g4d), 4, "D", 3.6))

# ---- Figura 3 (filtros): barras a partir de 0 (B) e pontos (C)
fe <- rd("filter_effects_wide.csv"); fe$nm <- LAB[fe$filter]; fe$stage <- factor(STAGE[STG[fe$filter]], STAGE); fe <- fe[order(fe$stage, fe$kept_pct_mean), ]; fe$nm <- factor(fe$nm, rev(fe$nm))
L <- do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(nm = fe$nm, stage = fe$stage, kept = fe[[paste0("kept_pct_", ARCH[j])]], rede = factor(CUR[j], CUR))))
base <- theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0, hjust = 1, size = 6.6, face = "bold"), strip.background = element_blank(), panel.spacing.y = unit(0.14, "cm"),
              axis.text.y = element_text(size = 6.6), axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.line.x = element_blank(), panel.border = element_rect(colour = "grey70", fill = NA, linewidth = 0.3), plot.margin = margin(3, 6, 2, 3))
g3b <- ggplot(L, aes(kept, nm)) + geom_col(fill = "grey55", width = 0.7) + geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.35) +
  geom_text(data = data.frame(rede = factor(CUR, CUR), stage = factor(STAGE[1], STAGE), nm = levels(L$nm)[length(levels(L$nm))]), aes(x = 100, y = nm, label = "unfiltered"), vjust = -1.0, size = 6.2 * PT, family = FONTE, inherit.aes = FALSE) +
  facet_grid(stage ~ rede, scales = "free_y", space = "free_y", switch = "y") + scale_x_continuous(breaks = c(0, 100, 200), limits = c(0, 225), expand = c(0, 0)) + scale_y_discrete(expand = expansion(add = c(0.6, 1.0))) +
  labs(x = "Lesion reliance kept (%)", y = NULL) + tema() + base + theme(strip.text.x = element_text(size = 6.6, face = "bold"), panel.spacing.x = unit(0.4, "cm"), panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.25))
versao(3, "B", 7.0, sg(g3b, 3, "B", 7.0))
g3c <- ggplot(L, aes(kept, nm, shape = rede, colour = rede)) + geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.35, colour = "grey30") +
  geom_point(size = 1.8, fill = "white", position = position_dodge(0.0)) + scale_shape_manual(values = SHP) + scale_colour_manual(values = GRY) +
  facet_grid(stage ~ ., scales = "free_y", space = "free_y", switch = "y") + scale_x_continuous(breaks = c(0, 50, 100, 150, 200), limits = c(-5, 225), expand = c(0, 0)) +
  labs(x = "Lesion reliance kept (%); dashed line = unfiltered", y = NULL) + tema() + base + theme(legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 6.4), legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -3),
        panel.grid.major = element_line(colour = "grey92", linewidth = 0.25)) + guides(shape = guide_legend(nrow = 1), colour = guide_legend(nrow = 1))
versao(3, "C", 6.0, sg(g3c, 3, "C", 6.0))

for (n in c(3, 4)) tryCatch(contato(n), error = function(e) cat("contato", n, conditionMessage(e), "\n"))
cat(unlist(lapply(LOG, identity)), sep = "\n"); cat("\nrho esperados: entre 0.77/0.73/0.81/0.84; treinos 0.08/0.03/0.05/0.04; restrito -0.04/0.32/0.20/0.30\nencontrado:\n")
for (t in TIPO) cat(sprintf("%-32s", t), paste(sprintf("%.2f", lad$rho[lad$tipo == t]), collapse = " / "), "\n"); cat("feito\n")
