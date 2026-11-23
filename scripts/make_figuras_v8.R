# Rodada 8 (feedback): só as figuras 1, 2, 4, 5 e 6, com texto e imagens MAIORES (>= 7 pt), fig 5 em cores pastel com retas e
# marcadores geométricos (quadrado, círculo, triângulo, estrela), "= 576 combinations" fora da linha dos fatores na fig 2.
# Uso (na pasta esann_materiais/): Rscript make_figuras_v8.R   (PREVIEW=pasta grava PNG de conferência fora do repositório)
v5 <- readLines("make_figuras_v5.R"); k5 <- grep("^# -+ Figura 2 \\(F\\)", v5)[1]
eval(parse(text = v5[1:(k5 - 1)]))                   # helpers (v3 + sg/sgrid em PDF + rrect, hl); OUTD = escolhidas
STAGE <- c("Illumination", "Color", "Local contrast", "Refinement")
STG <- c(BenGraham = 1, Gamma0.8 = 1, Retinex = 1, HistogramEq = 1, LABNorm = 1, GreenChannel = 2, MaxGreen2.0 = 2, Grayscale = 2, AHE40.0 = 3, CLAHE4.0 = 3, Unsharp1.5 = 4, Median = 4, Gaussian = 4, Morpho = 4, Frangi = 4, Canny = 4, Otsu = 4)
LEGD <- 1.0
TX <- 7.8                                             # tamanho base do texto nos gráficos (pt)
tema8 <- function() tema() + theme(axis.text = element_text(size = TX, colour = "black"), axis.title = element_text(size = TX + 0.4), strip.text = element_text(size = TX + 0.2),
                                   legend.text = element_text(size = TX - 0.4), plot.title = element_text(size = TX + 0.6, face = "bold"))

# ------------------------------------------------------------------------------ Figura 1 (B): faixa de 5 painéis, maior
fig1B <- function() {
  e <- PRINC; i <- exi(e)
  sgrid(1, "B", 2.95, function() {
    grid.newpage(); s <- 2.28; g <- 0.15; x0 <- 0.1; t0 <- 0.5
    nm <- c("A_exame", "B_mascara", "C_gradcam_contorno", "D_lesoes_borradas", "E_controle_borrado"); rot <- c("Exam", "Lesion mask", "Grad-CAM", "Lesions blurred", "Control blurred")
    for (k in 1:5) { x <- x0 + (k - 1) * (s + g); txt(LETTERS[k], x, 0.22, 8.5, "left", face = "bold"); txt(rot[k], x + 0.33, 0.22, 7.6, "left", maxw = s - 0.33, minsize = 6.8); img(pnl(e, nm[k]), x, t0, s) }
    pbox(fmt(i$p_lesoes_borradas), x0 + 3 * (s + g) + s / 2, t0 + s - 0.2, 1.4, 7.5); pbox(fmt(i$p_controle_borrado), x0 + 4 * (s + g) + s / 2, t0 + s - 0.2, 1.4, 7.5)
  })
}

# ------------------------------------------------------------------------------ Figura 2 (I): maior; "= 576 combinations" em linha própria
fig2I <- function() sgrid(2, "I", 3.9, function() {
  grid.newpage(); cad <- "Retinex_GreenChannel_CLAHE4.0_Gaussian"; pas <- function(j) readPNG(sprintf("paineis/cadeias/%s__passo%d.png", cad, j))
  iw <- 1.85; gp <- (12.0 - 5 * iw) / 4; xl <- 0.1 + (0:4) * (iw + gp); cx <- xl + iw / 2; ti <- 0.55
  imgs <- list(readPNG("paineis/cadeias/exame_original.png"), pas(1), pas(2), pas(3), pas(4))
  for (k in 1:5) {
    if (is.null(imgs[[k]])) { rrect(xl[k], ti, iw, iw, "white", "grey50", 0.7, 2); txt("—", cx[k], ti + iw / 2, 8.5, col = "grey40") } else img(imgs[[k]], xl[k], ti, iw)
    if (k > 1) { grid.rect(x = cm(cx[k]), y = Y(ti + iw - 0.19), width = cm(iw - 0.2), height = cm(0.3), gp = gpar(fill = "black", col = NA, alpha = 0.72)); txt(c("Retinex", "Green channel", "CLAHE", "Gaussian")[k - 1], cx[k], ti + iw - 0.19, 8.0, col = "white", maxw = iw - 0.3, minsize = 7.0) }
    if (k > 1) seta(xl[k - 1] + iw + 0.07, ti + iw / 2, xl[k] - 0.07, ti + iw / 2, 0.9)
    if (k > 1) txt(STAGE[k - 1], cx[k], 0.24, 9.0, face = "bold", maxw = iw + gp - 0.1, minsize = 7.5)
  }
  f <- c("(5+1)", "(3+1)", "(2+1)", "(7+1)"); ty <- ti + iw + 0.38
  for (k in 1:4) txt(f[k], cx[k + 1], ty, 9.0)
  for (k in 2:4) txt("×", (cx[k] + cx[k + 1]) / 2, ty, 9.0)
  txt("= 576 combinations", 6.1, ty + 0.55, 9.6, face = "bold")
})

# ------------------------------------------------------------------------------ Figura 4 (J): filtros por etapa, texto maior
fig4J <- function() {
  fe <- rd("filter_effects_wide.csv"); fe$nm <- LAB[fe$filter]; fe$stage <- factor(STAGE[STG[fe$filter]], STAGE)
  fe <- fe[order(fe$stage, fe$kept_pct_mean), ]; fe$nm <- factor(fe$nm, rev(fe$nm))
  L <- do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(nm = fe$nm, stage = fe$stage, kept = fe[[paste0("kept_pct_", ARCH[j])]], rede = factor(NOME[j], NOME))))
  g <- ggplot(L, aes(kept, nm)) + geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.4, colour = "grey40") +
    geom_segment(aes(x = 100, xend = kept, yend = nm), linewidth = 1.3, colour = "#1f5fa8", lineend = "butt") +
    facet_grid(stage ~ rede, scales = "free_y", space = "free_y", switch = "y") +
    scale_x_continuous(breaks = c(0, 100, 200), limits = c(-5, 225), expand = c(0, 0)) + labs(x = "Lesion reliance kept (%)", y = NULL) + tema8() +
    theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0, hjust = 1, size = TX + 0.2, face = "bold"), strip.text.x = element_text(size = TX - 0.4, face = "bold"), strip.background = element_blank(),
          panel.spacing.x = unit(0.4, "cm"), panel.spacing.y = unit(0.2, "cm"), axis.text.y = element_text(size = TX), axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.line.x = element_blank(),
          panel.grid.major.x = element_line(colour = "grey91", linewidth = 0.25), panel.border = element_rect(colour = "grey70", fill = NA, linewidth = 0.3), plot.margin = margin(3, 6, 2, 3))
  sg(g, 4, "J", 8.8)
}

# ------------------------------------------------------------------------------ Figura 4 (K): barras divergentes por rede, etapa na vertical
fig4K <- function() {
  fe <- rd("filter_effects_wide.csv"); fe$nm <- LAB[fe$filter]; fe$stage <- factor(c("Illumination", "Color", "Local\ncontrast", "Refinement")[STG[fe$filter]], c("Illumination", "Color", "Local\ncontrast", "Refinement"))
  fe <- fe[order(fe$stage, fe$kept_pct_mean), ]; fe$nm <- factor(fe$nm, c(" ", rev(as.character(fe$nm))))
  L <- do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(nm = fe$nm, stage = fe$stage, delta = fe[[paste0("kept_pct_", ARCH[j])]] - 100, rede = factor(NOME[j], NOME))))
  L$lab <- paste0(ifelse(L$delta < 0, "\u2212", "+"), abs(round(L$delta)), "%"); L$neg <- L$delta < 0
  vazio <- do.call(rbind, lapply(NOME, function(n) data.frame(nm = factor(" ", levels(L$nm)), stage = factor("Local\ncontrast", levels(L$stage)), delta = NA_real_, rede = factor(n, NOME), lab = NA_character_, neg = NA)))
  L <- rbind(L, vazio)   # linha em branco: dá altura ao painel de 2 filtros para caber o nome da etapa na vertical
  g <- ggplot(L, aes(delta, nm)) + geom_col(aes(fill = neg), width = 0.62, show.legend = FALSE, na.rm = TRUE) + geom_vline(xintercept = 0, linewidth = 0.4, colour = "grey30") +
    geom_text(aes(x = 116, label = lab), hjust = 0, na.rm = TRUE, size = (TX - 0.6) * PT, family = FONTE) +
    scale_fill_manual(values = c(`TRUE` = "#e0804f", `FALSE` = "#79b5e3")) +
    facet_grid(stage ~ rede, scales = "free_y", space = "free_y", switch = "y") +
    scale_x_continuous(breaks = c(-100, 0, 100), limits = c(-105, 245), expand = c(0, 0)) + labs(x = "Change in lesion reliance (%)", y = NULL) + tema8() +
    theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 90, hjust = 0.5, size = TX, face = "bold", lineheight = 0.9), strip.text.x = element_text(size = TX - 0.4, face = "bold"), strip.background = element_blank(),
          panel.spacing.x = unit(0.3, "cm"), panel.spacing.y = unit(0.2, "cm"), axis.text.y = element_text(size = TX), axis.text.x = element_text(size = TX - 0.4), axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.line.x = element_blank(),
          panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.25), panel.border = element_rect(colour = "grey75", fill = NA, linewidth = 0.3), plot.margin = margin(3, 5, 2, 3))
  sg(g, 4, "K", 9.0)
}

# ------------------------------------------------------------------------------ Figura 4 (L): + 3 execuções por barra, A0 na rede, filtros destrutivos em cinza
fig4L <- function() {
  fe <- rd("filter_effects_wide.csv"); fe$nm0 <- LAB[fe$filter]; destr <- fe$auc_mean < 0.85
  fe$nm0 <- ifelse(destr, paste0(fe$nm0, "\u2020"), fe$nm0); fe$destr <- destr
  ET <- c("Illumination", "Color", "Local\ncontrast", "Refinement"); fe$stage <- factor(ET[STG[fe$filter]], ET)
  fe <- fe[order(fe$stage, fe$kept_pct_mean), ]; niveis <- c(" ", rev(fe$nm0)); fe$nm <- factor(fe$nm0, niveis)
  pl <- rd("pipelines_long.csv"); A0 <- tapply(pl$A_points[pl$condicao == "baseline"], pl$arch[pl$condicao == "baseline"], mean)
  rede_l <- factor(sprintf("%s\nA\u2080 = %.1f", NOME, A0[ARCH]), sprintf("%s\nA\u2080 = %.1f", NOME, A0[ARCH]))
  L <- do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(nm = fe$nm, stage = fe$stage, destr = fe$destr, delta = fe[[paste0("kept_pct_", ARCH[j])]] - 100, rede = rede_l[j])))
  L$lab <- paste0(ifelse(L$delta < 0, "\u2212", "+"), abs(round(L$delta)), "%"); L$cor <- ifelse(L$destr, "dest", ifelse(L$delta < 0, "neg", "pos"))
  R <- do.call(rbind, lapply(seq_along(ARCH), function(j) { x <- pl[pl$arch == ARCH[j] & pl$condicao %in% fe$filter, ]; x$nm <- factor(fe$nm0[match(x$condicao, fe$filter)], niveis)
    data.frame(nm = x$nm, stage = fe$stage[match(x$condicao, fe$filter)], delta = 100 * x$A_points / A0[ARCH[j]] - 100, rede = rede_l[j]) }))
  vazio <- do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(nm = factor(" ", niveis), stage = factor("Local\ncontrast", ET), destr = NA, delta = NA_real_, rede = rede_l[j], lab = NA_character_, cor = NA_character_)))
  L <- rbind(L, vazio)
  g <- ggplot(L, aes(delta, nm)) + geom_col(aes(fill = cor), width = 0.62, show.legend = FALSE, na.rm = TRUE) + geom_vline(xintercept = 0, linewidth = 0.4, colour = "grey30") +
    geom_point(data = R, aes(delta, nm), size = 0.75, colour = "grey15", alpha = 0.85, position = position_jitter(height = 0.13, width = 0, seed = 1), inherit.aes = FALSE) +
    geom_text(aes(x = 168, label = lab), hjust = 0, na.rm = TRUE, size = (TX - 0.6) * PT, family = FONTE) +
    scale_fill_manual(values = c(neg = "#e0804f", pos = "#79b5e3", dest = "#b5b5b5")) +
    facet_grid(stage ~ rede, scales = "free_y", space = "free_y", switch = "y") +
    scale_x_continuous(breaks = c(-100, 0, 100), limits = c(-110, 330), expand = c(0, 0)) + labs(x = "Change in lesion reliance (%)", y = NULL) + tema8() +
    theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 90, hjust = 0.5, size = TX, face = "bold", lineheight = 0.9), strip.text.x = element_text(size = TX - 0.6, face = "bold", lineheight = 1.0), strip.background = element_blank(),
          panel.spacing.x = unit(0.3, "cm"), panel.spacing.y = unit(0.2, "cm"), axis.text.y = element_text(size = TX), axis.text.x = element_text(size = TX - 0.4), axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.line.x = element_blank(),
          panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.25), panel.border = element_rect(colour = "grey75", fill = NA, linewidth = 0.3), plot.margin = margin(3, 5, 2, 3))
  sg(g, 4, "L", 9.2)
}

# ------------------------------------------------------------------------------ Figura 5 (L): pastel, retas, quadrado/círculo/triângulo/estrela
fig5L <- function() {
  pl <- rd("pipelines_long.csv"); lad <- rd("correlations_ladder.csv"); pl$rede <- factor(NOME[match(pl$arch, ARCH)], NOME)
  pm <- aggregate(cbind(AUC, A_points) ~ chain + rede, pl, mean)
  pl$mAUC <- ave(pl$AUC, pl$chain, pl$arch); pl$mA <- ave(pl$A_points, pl$chain, pl$arch); pl$dAUC <- pl$AUC - pl$mAUC; pl$dA100 <- pl$A_points - pl$mA
  bet <- lad[lad$tipo == "between pipelines", ]$rho; wit <- lad[lad$tipo == "between runs of one pipeline", ]$rho
  cols <- c("#3f7fc4", "#e57f2e", "#2f9d70", "#a05cc9"); glifos <- c("■", "●", "▲", "★"); curto <- c("EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50")
  mk <- function(d, x, y, rho, tag, xl, yl) {
    lab <- curto; d$lab <- factor(lab[as.integer(d$rede)], lab)
    ggplot(d, aes(.data[[x]], .data[[y]], colour = lab, shape = lab)) +
      geom_point(size = 1.9, alpha = 0.32, stroke = 0) +
      geom_smooth(aes(group = lab, linetype = lab), data = function(z) if (x == "dAUC") z[abs(z$dAUC) <= 0.05, ] else z, method = "lm", se = FALSE, formula = y ~ x, linewidth = 1.5, show.legend = FALSE) +
      scale_linetype_manual(values = setNames(if (x == "dAUC") c("solid", "22", "44", "1343") else rep("solid", 4), lab), guide = "none") +
      scale_colour_manual(values = setNames(cols, lab)) + scale_shape_manual(values = setNames(glifos, lab)) +
      labs(x = xl, y = yl, title = tag) + tema8() + guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 3.2, alpha = 1)), shape = guide_legend(nrow = 2, byrow = TRUE)) +
      theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.42, "cm"), legend.margin = margin(t = 0), legend.spacing.x = unit(0.1, "cm"),
            panel.grid.major = element_line(colour = "grey92", linewidth = 0.25), plot.title.position = "panel", plot.title = element_text(size = TX + 0.8, face = "bold", hjust = 0, margin = margin(b = 3)), plot.margin = margin(3, 6, 2, 3))
  }
  a <- mk(pm, "AUC", "A_points", bet, "(a)", "AUC (mean of 3 runs)", "Lesion reliance A (points)") + scale_x_continuous(breaks = c(0.5, 0.7, 0.9), limits = c(0.45, 0.95), expand = c(0, 0)) + scale_y_continuous(limits = c(-2, 21), breaks = c(0, 10, 20), expand = c(0, 0))
  b <- mk(pl, "dAUC", "dA100", wit, "(b)", "AUC − pipeline mean", "A − pipeline mean (points)") + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey55") + geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey55") +
    scale_x_continuous(breaks = c(-0.04, 0, 0.04)) + coord_cartesian(xlim = c(-0.05, 0.05), ylim = c(-8, 9), expand = FALSE)
  sg(suppressMessages(a + b + plot_layout(widths = c(1.05, 1))), 5, "M", 6.8)
}

# ------------------------------------------------------------------------------ Figura 6 (F): tabela com miniaturas, maior
fig6F <- function() {
  s <- rd("chains_similar_auc.csv"); b <- rd("networks.csv"); A0 <- mean(b$A_unfiltered_points); auc0 <- mean(b$auc_unfiltered_mean)
  nm <- function(x) { p <- strsplit(x, " > ")[[1]]; paste(sapply(p, function(z) if (z %in% names(LAB)) LAB[[z]] else z), collapse = "  →  ") }
  ex <- read.csv("dados/chains_extremas.csv"); linhas <- c(ex$chain[1:2], "Unfiltered", ex$chain[3:4])
  sgrid(6, "F", 6.4, function() {
    grid.newpage(); txt("Pipeline", 1.4, 0.28, 9.2, "left", face = "bold"); txt("AUC", 8.9, 0.28, 9.2, "left", face = "bold"); txt("A (points)", 10.0, 0.28, 9.2, "left", face = "bold"); hl(0.1, 12.1, 0.58, 0.7)
    for (r in 1:5) { ch <- linhas[r]; t <- 0.75 + (r - 1) * 1.07
      f <- if (ch == "Unfiltered") "paineis/cadeias/exame_original.png" else file.path("paineis/extremas", paste0(gsub(" > ", "_", ch), ".png")); img(readPNG(f), 0.1, t, 0.95)
      if (ch == "Unfiltered") { auc <- auc0; a <- A0; n <- "Unfiltered" } else { row <- s[s$pipeline == ch, ]; auc <- row$AUC_mean4; a <- row$A_points_mean4; n <- nm(ch) }
      txt(n, 1.4, t + 0.475, 9.2, "left", maxw = 7.7, minsize = 7.4); txt(sprintf("%.3f", auc), 8.9, t + 0.475, 9.2, "left"); txt(sprintf("%.1f", a), 10.0, t + 0.475, 9.2, "left") }
    hl(0.1, 12.1, 6.3, 0.7)
  })
}

# ------------------------------------------------------------------------------ Figura 4 (M): barras divergentes (como a K) + desvio padrão das 3 execuções (linha com chão e teto)
fig4M <- function() {
  TX <<- 8.8
  CURTO4 <- c("EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50")
  fe <- rd("filter_effects_wide.csv"); fe$nm0 <- LAB[fe$filter]
  ET <- c("Illumination", "Color", "Local\ncontrast", "Refinement"); fe$stage <- factor(ET[STG[fe$filter]], ET)
  fe <- fe[order(fe$stage, fe$kept_pct_mean), ]; niveis <- c(" ", rev(fe$nm0)); fe$nm <- factor(fe$nm0, niveis)
  pl <- rd("pipelines_long.csv"); A0 <- tapply(pl$A_points[pl$condicao == "baseline"], pl$arch[pl$condicao == "baseline"], mean)
  L <- do.call(rbind, lapply(seq_along(ARCH), function(j) {
    x <- pl[pl$arch == ARCH[j] & pl$condicao %in% fe$filter, ]; x$d <- 100 * x$A_points / A0[ARCH[j]] - 100          # % de mudança por execução (A0 = média do sem filtro)
    m <- aggregate(d ~ condicao, x, mean); sd <- aggregate(d ~ condicao, x, sd)
    data.frame(nm = factor(fe$nm0[match(m$condicao, fe$filter)], niveis), stage = fe$stage[match(m$condicao, fe$filter)], delta = m$d, sd = sd$d, rede = factor(CURTO4[j], CURTO4)) }))
  L$lab <- paste0(ifelse(L$delta < 0, "\u2212", "+"), abs(round(L$delta)), "%"); L$neg <- L$delta < 0
  vazio <- do.call(rbind, lapply(CURTO4, function(n) data.frame(nm = factor(" ", niveis), stage = factor("Local\ncontrast", ET), delta = NA_real_, sd = NA_real_, rede = factor(n, CURTO4), lab = NA_character_, neg = NA)))
  L <- rbind(L, vazio)
  g <- ggplot(L, aes(delta, nm)) + geom_col(aes(fill = neg), width = 0.62, alpha = 0.65, show.legend = FALSE, na.rm = TRUE) + geom_vline(xintercept = 0, linewidth = 0.4, colour = "grey30") +
    geom_errorbar(aes(xmin = delta - sd, xmax = delta + sd), orientation = "y", width = 0.3, linewidth = 0.35, colour = "grey10", na.rm = TRUE) +
    geom_text(aes(x = 172, label = lab), hjust = 0, na.rm = TRUE, size = (TX - 0.6) * PT, family = FONTE) +
    scale_fill_manual(values = c(`TRUE` = "#b03a2e", `FALSE` = "#1f4e8c")) +
    facet_grid(stage ~ rede, scales = "free_y", space = "free_y", switch = "y") +
    scale_x_continuous(breaks = c(-100, 0, 100), limits = c(-115, 420), expand = c(0, 0)) + labs(x = "Change in lesion reliance (%)", y = NULL) + tema8() +
    theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 90, hjust = 0.5, size = TX, face = "bold", lineheight = 0.9), strip.text.x = element_text(size = TX - 0.4, face = "bold"), strip.background = element_blank(),
          panel.spacing.x = unit(0.3, "cm"), panel.spacing.y = unit(0.2, "cm"), axis.text.y = element_text(size = TX), axis.text.x = element_text(size = TX - 1.4), axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.line.x = element_blank(),
          panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.25), panel.border = element_rect(colour = "grey75", fill = NA, linewidth = 0.3), plot.margin = margin(3, 5, 2, 3))
  sg(g, 4, "M", 10.2)
}

# ------------------------------------------------------------------------------ Figura 5 (N): curvas suaves, paleta sóbria, painel (c) com o rho restrito
fig5O <- function() {
  pl <- rd("pipelines_long.csv"); lad <- rd("correlations_ladder.csv"); pl$rede <- factor(NOME[match(pl$arch, ARCH)], NOME)
  pm <- aggregate(cbind(AUC, A_points) ~ chain + rede, pl, mean)
  pl$mAUC <- ave(pl$AUC, pl$chain, pl$arch); pl$mA <- ave(pl$A_points, pl$chain, pl$arch); pl$dAUC <- pl$AUC - pl$mAUC; pl$dA100 <- pl$A_points - pl$mA
  g_ <- function(t) lad[lad$tipo == t, ]; bet <- g_("between pipelines")$rho; wit <- g_("between runs of one pipeline")$rho
  cols <- c("#1f4e8c", "#b03a2e", "#1e7a4c", "#6a3d9a"); glifos <- c("\u25a0", "\u25cf", "\u25b2", "\u2605"); curto <- c("EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50")
  mk <- function(d, x, y, rho, tag, xl, yl, suave, lt) {
    lab <- sprintf("%s \u03c1=%.2f", curto, rho); d$lab <- factor(lab[as.integer(d$rede)], lab)
    ggplot(d, aes(.data[[x]], .data[[y]], colour = lab, shape = lab)) +
      geom_point(size = 1.6, alpha = 0.6, stroke = 0) +
      geom_smooth(aes(group = lab, linetype = lab), data = function(z) if (x == "dAUC") z[abs(z$dAUC) <= 0.05, ] else z, method = suave$m, formula = suave$f, se = FALSE, linewidth = 1.1, show.legend = FALSE, span = suave$span) +
      scale_linetype_manual(values = setNames(lt, lab), guide = "none") +
      scale_colour_manual(values = setNames(cols, lab)) + scale_shape_manual(values = setNames(glifos, lab)) +
      labs(x = xl, y = yl, title = tag) + tema8() + guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 3.2, alpha = 1)), shape = guide_legend(nrow = 2, byrow = TRUE)) +
      theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.4, "cm"), legend.margin = margin(t = 0), legend.spacing.x = unit(0.05, "cm"), legend.text = element_text(size = TX - 1.0, margin = margin(r = 4)),
            panel.grid.major = element_line(colour = "grey92", linewidth = 0.25), plot.title.position = "panel", plot.title = element_text(size = TX + 0.8, face = "bold", hjust = 0, margin = margin(b = 3)), plot.margin = margin(3, 6, 2, 3))
  }
  a <- mk(pm, "AUC", "A_points", bet, "(a)", "AUC (mean of 3 runs)", "Lesion reliance A (points)", list(m = "loess", f = y ~ x, span = 0.9), rep("solid", 4)) +
    scale_x_continuous(breaks = c(0.5, 0.7, 0.9), limits = c(0.45, 0.95), expand = c(0, 0)) + scale_y_continuous(limits = c(-2, 21), breaks = c(0, 10, 20), expand = c(0, 0))
  b <- mk(pl, "dAUC", "dA100", wit, "(b)", "AUC \u2212 pipeline mean", "A \u2212 pipeline mean (points)", list(m = "gam", f = y ~ s(x, k = 4), span = NULL), c("solid", "22", "44", "1343")) +
    geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey55") + geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey55") +
    scale_x_continuous(breaks = c(-0.04, 0, 0.04)) + coord_cartesian(xlim = c(-0.05, 0.05), ylim = c(-8, 9), expand = FALSE)
  sg(suppressMessages(a + b + plot_layout(widths = c(1.05, 1))), 5, "O", 6.8)
}

# ------------------------------------------------------------------------------ Figura 5 parametrizada (comparação de estilos de linha)
fig5_obj <- function(reta = FALSE, lw = 1.6, lt = list(a = rep("solid", 4), b = rep("solid", 4)), alfa = 0.35, tam = 1.4, xmin = 0.45, casing = 0, escuro = 1, xmax = 0.95, xbreaks = c(0.5, 0.7, 0.9)) {
  pl <- rd("pipelines_long.csv"); lad <- rd("correlations_ladder.csv"); pl$rede <- factor(NOME[match(pl$arch, ARCH)], NOME)
  pm <- aggregate(cbind(AUC, A_points) ~ chain + rede, pl, mean)
  pl$mAUC <- ave(pl$AUC, pl$chain, pl$arch); pl$mA <- ave(pl$A_points, pl$chain, pl$arch); pl$dAUC <- pl$AUC - pl$mAUC; pl$dA100 <- pl$A_points - pl$mA
  bet <- lad[lad$tipo == "between pipelines", ]$rho; wit <- lad[lad$tipo == "between runs of one pipeline", ]$rho
  cols <- c("#1f4e8c", "#b03a2e", "#1e7a4c", "#6a3d9a"); glifos <- c("\u25a0", "\u25cf", "\u25b2", "\u2605"); curto <- c("EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50")
  mk <- function(d, x, y, rho, tag, xl, yl, suave, lt_p) {
    lab <- sprintf("%s \u03c1=%.2f", curto, rho); d$lab <- factor(lab[as.integer(d$rede)], lab)
    ggplot(d, aes(.data[[x]], .data[[y]], colour = lab, shape = lab)) +
      geom_point(size = tam, alpha = alfa, stroke = 0) +
      (if (casing > 0 && x == "AUC") geom_smooth(aes(group = lab), colour = "white", data = function(z) if (x == "dAUC") z[abs(z$dAUC) <= 0.05, ] else z, method = suave$m, formula = suave$f, se = FALSE, linewidth = lw + casing, show.legend = FALSE, span = suave$span) else NULL) +
      geom_smooth(aes(group = lab, linetype = lab, colour = stage(lab, after_scale = rgb(t(col2rgb(colour)) * escuro, maxColorValue = 255))), data = function(z) if (x == "dAUC") z[abs(z$dAUC) <= 0.05, ] else z, method = suave$m, formula = suave$f, se = FALSE, linewidth = lw, show.legend = FALSE, span = suave$span) +
      scale_linetype_manual(values = setNames(lt_p, lab), guide = "none") +
      scale_colour_manual(values = setNames(cols, lab)) + scale_shape_manual(values = setNames(glifos, lab)) +
      labs(x = xl, y = yl, title = tag) + tema8() +
      guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 3.0, alpha = 1)), shape = guide_legend(nrow = 2, byrow = TRUE)) +
      theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.4, "cm"), legend.margin = margin(t = 0), legend.spacing.x = unit(0.03, "cm"), legend.text = element_text(size = TX - LEGD, margin = margin(r = 4)),
            panel.grid.major = element_line(colour = "grey92", linewidth = 0.25), plot.title.position = "panel", plot.title = element_text(size = TX + 0.8, face = "bold", hjust = 0, margin = margin(b = 3)), plot.margin = margin(3, 6, 2, 3))
  }
  sa <- if (reta) list(m = "lm", f = y ~ x, span = NULL) else list(m = "loess", f = y ~ x, span = 0.9)
  sb <- if (reta) list(m = "lm", f = y ~ x, span = NULL) else list(m = "gam", f = y ~ s(x, k = 4), span = NULL)
  a <- mk(pm, "AUC", "A_points", bet, "(a)", "AUC", "Lesion reliance A (points)", sa, lt$a) + scale_x_continuous(breaks = xbreaks, labels = function(v) sprintf("%.2f", v), limits = c(xmin, xmax), expand = c(0, 0)) + scale_y_continuous(limits = c(-2, 21), breaks = c(0, 10, 20), expand = c(0, 0))
  b <- mk(pl, "dAUC", "dA100", wit, "(b)", "AUC \u2212 pipeline mean", "A \u2212 pipeline mean (points)", sb, lt$b) + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey55") + geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey55") +
    scale_x_continuous(breaks = c(-0.04, 0, 0.04)) + coord_cartesian(xlim = c(-0.05, 0.05), ylim = c(-8, 9), expand = FALSE)
  suppressMessages(a + b + plot_layout(widths = c(1.05, 1)))
}

fig5Q <- function() sg(fig5_obj(TRUE, 0.6, list(a = rep("solid", 4), b = rep("solid", 4)), 0.5, 1.4), 5, "Q", 6.8)
fig5R <- function() sg(fig5_obj(TRUE, 0.6, list(a = rep("solid", 4), b = rep("solid", 4)), 0.5, 1.4, xmin = 0), 5, "R", 6.8)
fig5S <- function() { for (v in list(list("1", 0.4, 1), list("4", 0.4, 0.8))) { f <- v; sg(fig5_obj(TRUE, 0.6, list(a = rep("solid", 4), b = rep("solid", 4)), 0.5, 1.4, casing = f[[2]], escuro = f[[3]], xmax = 1.0, xbreaks = c(0.5, 0.75, 1.0)), 5, paste0("S", f[[1]]), 6.8) } }
fig5T <- function() { for (v in list(list("2", 9.5, 2.1, 8.0, 2.7))) { TX <<- v[[2]]; LEGD <<- v[[5]]; sg(fig5_obj(TRUE, 0.6, list(a = rep("solid", 4), b = rep("solid", 4)), 0.5, v[[3]], casing = 0.4, xmax = 1.0, xbreaks = c(0.5, 0.75, 1.0)), 5, paste0("T", v[[1]]), v[[4]]) } }
if (Sys.getenv("SO_DEFS") == "") for (f in list(fig1B, fig2I, fig4M, fig5T, fig6F)) { r <- tryCatch({ suppressMessages(f()); "ok" }, error = function(e) paste("ERRO:", conditionMessage(e))); cat(r, "\n") }
cat(unique(AVISOS), sep = "\n"); cat("feito\n")
