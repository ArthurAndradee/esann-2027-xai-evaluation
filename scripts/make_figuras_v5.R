# Rodada 5 (revisão do usuário): só PDFs, direto em escolhidas/. Sem texto explicativo (vai no .tex), sem cor onde não pedida.
# Figuras: 2 (fluxo compacto), 3 (tabela padrão), 4 (dot plot em grupos, sem cor), 5 (E sem rótulos sobre os dados), 6 (sem texto extra), 8 (heatmap divergente).
# Uso (na pasta esann_materiais/): Rscript make_figuras_v5.R
lines <- readLines("make_figuras_v3.R"); k <- grep("^# =+ FIGURA 1", lines)[1]
eval(parse(text = lines[1:(k - 1)]))                 # helpers: tema, txt, img, seta, caixa, rd, LAB, NOME, ARCH, HEAD...
OUTD <- "escolhidas"; dir.create(OUTD, showWarnings = FALSE)
PREV <- Sys.getenv("PREVIEW")                        # se definido, grava também um PNG de conferência FORA do repositório
sg <- function(g, fig, v, h) { ggsave(file.path(OUTD, paste0(nome_arq(fig, v, h), ".pdf")), g, width = 12.2, height = h, units = "cm", device = cairo_pdf)
  if (nzchar(PREV)) ggsave(file.path(PREV, paste0(nome_arq(fig, v, h), ".png")), g, width = 12.2, height = h, units = "cm", dpi = 200, type = "cairo") }
sgrid <- function(fig, v, h, fun) { HT <<- h; cairo_pdf(file.path(OUTD, paste0(nome_arq(fig, v, h), ".pdf")), width = W, height = h / 2.54, family = FONTE); fun(); dev.off()
  if (nzchar(PREV)) { png(file.path(PREV, paste0(nome_arq(fig, v, h), ".png")), width = 12.2, height = h, units = "cm", res = 200, type = "cairo", family = FONTE); fun(); dev.off() } }
rrect <- function(x, t, w, h, fill, col, lwd = 0.8, lty = 1, r = 0.1) grid.roundrect(x = cm(x), y = Y(t), width = cm(w), height = cm(h), just = c("left", "top"), r = unit(r, "cm"), gp = gpar(fill = fill, col = col, lwd = lwd, lty = lty))
hl <- function(x1, x2, t, lwd = 0.8) grid.lines(x = cm(c(x1, x2)), y = Y(c(t, t)), gp = gpar(lwd = lwd))

# ------------------------------------------------------------------------------------------------ Figura 2 (F): fluxo compacto
fig2F <- function() sgrid(2, "F", 3.3, function() {
  grid.newpage(); cad <- "BenGraham_CLAHE4.0_Gaussian"; pas <- function(j) readPNG(sprintf("paineis/cadeias/%s__passo%d.png", cad, j))
  st <- list(c("1", "Illumination", "5 options"), c("2", "Color", "3 options"), c("3", "Local contrast", "2 options"), c("4", "Refinement", "7 options"))
  bw <- 2.35; bx <- function(k) 1.7 + (k - 1) * 2.6; iw <- 0.95; ti <- 0.1; tb <- 1.32
  img(readPNG("paineis/cadeias/exame_original.png"), 0.1, ti, iw)
  imgs <- list(pas(1), NULL, pas(2), pas(3))
  for (k in 1:4) {
    xi <- bx(k) + (bw - iw) / 2; xp <- if (k == 1) 0.1 + iw else bx(k - 1) + (bw - iw) / 2 + iw
    seta(xp + 0.05, ti + iw / 2, xi - 0.05, ti + iw / 2, 0.8)
    if (is.null(imgs[[k]])) { rrect(xi, ti, iw, iw, "white", "grey50", 0.6, 2); txt("—", xi + iw / 2, ti + iw / 2, 7, col = "grey40") } else img(imgs[[k]], xi, ti, iw)
    grid.lines(x = cm(rep(xi + iw / 2, 2)), y = Y(c(ti + iw + 0.03, tb - 0.03)), gp = gpar(lty = 3, lwd = 0.7, col = "grey45"))
    S <- st[[k]]; rrect(bx(k), tb, bw, 0.82, "grey95", "grey30", 0.8)
    grid.circle(x = cm(bx(k) + 0.24), y = Y(tb + 0.41), r = cm(0.15), gp = gpar(fill = "grey25", col = NA)); txt(S[1], bx(k) + 0.24, tb + 0.41, 6.5, col = "white", face = "bold")
    txt(S[2], bx(k) + 0.47, tb + 0.28, 6.6, "left", face = "bold", maxw = bw - 0.55, minsize = 6.0); txt(S[3], bx(k) + 0.47, tb + 0.56, 6.3, "left", "grey25", maxw = bw - 0.55)
    if (k < 4) seta(bx(k) + bw + 0.03, tb + 0.41, bx(k + 1) - 0.03, tb + 0.41, 0.9)
  }
  pill <- function(x, w, a, b, fill) { rrect(x, 2.5, w, 0.66, fill, "grey40", 0.7, 1, 0.3); txt(a, x + w / 2, 2.5 + 0.2, 6.8, face = "bold", maxw = w - 0.3); txt(b, x + w / 2, 2.5 + 0.46, 6.3, col = "grey20", maxw = w - 0.3) }
  pill(0.1, 3.7, "576 pipelines", "(5+1) × (3+1) × (2+1) × (7+1)", "grey97"); pill(4.2, 3.5, "185 trained", "18 + 150 D-optimal + 20 random", "grey92"); pill(8.1, 3.9, "2,220 models", "185 × 4 networks × 3 runs", "grey87")
  seta(3.83, 2.83, 4.17, 2.83, 1.0); seta(7.73, 2.83, 8.07, 2.83, 1.0)
})

# ------------------------------------------------------------------------------------------------ Figura 3 (D): tabela padrão (estilo booktabs)
fig3D <- function() {
  nt <- rd("networks.csv"); nt$nome <- NOME[match(nt$arch, ARCH)]
  sgrid(3, "D", 2.7, function() {
    grid.newpage(); X <- c(0.3, 3.4, 7.1, 9.9, 11.8)
    hl(0.1, 12.1, 0.12, 1.1)
    txt("Network", X[1], 0.42, 7, "left", face = "bold"); txt("Family", X[2], 0.42, 7, "left", face = "bold"); txt("Parameters (M)", X[3], 0.42, 7, "right", face = "bold")
    txt("AUC", X[4], 0.42, 7, "right", face = "bold"); txt("A (points)", X[5], 0.42, 7, "right", face = "bold")
    hl(0.1, 12.1, 0.7, 0.6)
    for (r in 1:4) { x <- nt[r, ]; t <- 0.98 + (r - 1) * 0.38
      txt(x$nome, X[1], t, 7, "left"); txt(x$family, X[2], t, 7, "left"); txt(sprintf("%.1f", x$params_millions_backbone), X[3], t, 7, "right")
      txt(sprintf("%.3f ± %.3f", x$auc_unfiltered_mean, x$auc_unfiltered_sd), X[4], t, 7, "right"); txt(sprintf("%.1f", x$A_unfiltered_points), X[5], t, 7, "right") }
    hl(0.1, 12.1, 2.5, 1.1)
  })
}

# ------------------------------------------------------------------------------------------------ Figura 4 (H): dot plot em grupos, sem cor
fig4H <- function() {
  fe <- rd("filter_effects_wide.csv"); fe$nm <- LAB[fe$filter]
  FAM <- c("destructive", "contrast equalization", "smoothing / sharpening", "illumination", "neutral", "color")
  FL <- c(destructive = "Destructive", `contrast equalization` = "Contrast\nequalization", `smoothing / sharpening` = "Smoothing /\nsharpening", illumination = "Illumination", neutral = "Neutral", color = "Color")
  fe$family <- factor(fe$family, FAM); fe <- fe[order(fe$family, fe$kept_pct_mean), ]; fe$nm <- factor(fe$nm, rev(fe$nm))
  L <- do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(nm = fe$nm, family = fe$family, kept = fe[[paste0("kept_pct_", ARCH[j])]], rede = factor(NOME[j], NOME))))
  g <- ggplot(L, aes(kept, nm)) + geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.35, colour = "grey40") +
    geom_segment(aes(x = 100, xend = kept, yend = nm), linewidth = 0.45, colour = "grey55") + geom_point(size = 1.7, colour = "black") +
    facet_grid(family ~ rede, scales = "free_y", space = "free_y", switch = "y", labeller = labeller(family = FL)) +
    scale_x_continuous(breaks = c(0, 100, 200), limits = c(-5, 225), expand = c(0, 0)) +
    labs(x = "Lesion reliance kept (%)", y = NULL) + tema() +
    theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0, hjust = 1, size = 6.4, face = "bold", lineheight = 0.9), strip.text.x = element_text(size = 7, face = "bold"),
          strip.background = element_blank(), panel.spacing.x = unit(0.45, "cm"), panel.spacing.y = unit(0.14, "cm"), axis.text.y = element_text(size = 6.6), axis.line.y = element_blank(),
          axis.ticks.y = element_blank(), panel.grid.major.x = element_line(colour = "grey91", linewidth = 0.25), panel.border = element_rect(colour = "grey70", fill = NA, linewidth = 0.3), axis.line.x = element_blank(),
          plot.margin = margin(3, 6, 2, 3))
  sg(g, 4, "H", 7.4)
}

# ------------------------------------------------------------------------------------------------ Figura 5 (G): E sem rótulos sobre os dados
fig5G <- function() {
  pl <- rd("pipelines_long.csv"); lad <- rd("correlations_ladder.csv"); pl$rede <- factor(NOME[match(pl$arch, ARCH)], NOME)
  pm <- aggregate(cbind(AUC, A_points) ~ chain + rede, pl, mean)
  pl$mAUC <- ave(pl$AUC, pl$chain, pl$arch); pl$mA <- ave(pl$A_points, pl$chain, pl$arch); pl$dAUC <- pl$AUC - pl$mAUC; pl$dA <- pl$A_points - pl$mA
  bet <- lad[lad$tipo == "between pipelines", ]$rho; wit <- lad[lad$tipo == "between runs of one pipeline", ]$rho
  cols <- c("#0072b2", "#d55e00", "#009e73", "#cc79a7"); shp <- c(16, 15, 17, 18)
  mk <- function(d, x, y, rho, smooth, tag, xl, yl) {
    lab <- sprintf("%s  ρ = %.2f", c("EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50"), rho); d$lab <- factor(lab[as.integer(d$rede)], lab)
    g <- ggplot(d, aes(.data[[x]], .data[[y]], colour = lab, shape = lab, linetype = lab)) +
      geom_point(size = if (smooth) 1.1 else 0.8, alpha = if (smooth) 0.7 else 0.4, stroke = 0.4) +
      (if (smooth) geom_smooth(method = "loess", se = FALSE, linewidth = 0.6, formula = y ~ x) else geom_blank()) +
      scale_colour_manual(values = setNames(cols, lab)) + scale_shape_manual(values = setNames(shp, lab)) + scale_linetype_manual(values = setNames(rep("solid", 4), lab)) +
      labs(x = xl, y = yl, tag = tag) + tema() + guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 1.8, alpha = 1)), shape = guide_legend(nrow = 2, byrow = TRUE), linetype = guide_legend(nrow = 2, byrow = TRUE)) +
      theme(legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 6.4), legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = 0), legend.spacing.x = unit(0.1, "cm"),
            panel.grid.major = element_line(colour = "grey92", linewidth = 0.25), plot.tag = element_text(size = 7.5, face = "bold"), plot.tag.position = c(0.0, 1.0), plot.margin = margin(9, 6, 2, 3))
    g
  }
  a <- mk(pm, "AUC", "A_points", bet, TRUE, "(a)", "AUC (mean of the 3 runs of a pipeline)", "Lesion reliance A (points)") +
    scale_x_continuous(breaks = c(0.5, 0.6, 0.7, 0.8, 0.9), limits = c(0.45, 0.95), expand = c(0, 0)) + scale_y_continuous(limits = c(-2, 21), breaks = c(0, 5, 10, 15, 20), expand = c(0, 0))
  pl$dA100 <- pl$dA * 100
  b <- mk(pl, "dAUC", "dA100", wit, FALSE, "(b)", "AUC − mean of its pipeline", "A − mean of its pipeline (points)") +
    geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey55") + geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey55") +
    scale_x_continuous(breaks = c(-0.04, 0, 0.04)) + coord_cartesian(xlim = c(-0.05, 0.05), ylim = c(-8, 9), expand = FALSE)
  sg(suppressMessages(a + b + plot_layout(widths = c(1.05, 1))), 5, "G", 6.0)
}

# ------------------------------------------------------------------------------------------------ Figura 6 (E): tabela com miniaturas, sem texto extra
fig6E <- function() {
  s <- rd("chains_similar_auc.csv"); s <- s[order(s$A_points_mean4), ]; b <- rd("networks.csv"); A0 <- mean(b$A_unfiltered_points); auc0 <- mean(b$auc_unfiltered_mean)
  nm <- function(x) { p <- strsplit(x, " > ")[[1]]; paste(sapply(p, function(z) if (z %in% names(LAB)) LAB[[z]] else z), collapse = "  →  ") }
  ex <- read.csv("dados/chains_extremas.csv"); linhas <- c(ex$chain[1:2], "unfiltered", ex$chain[3:4])
  sgrid(6, "E", 4.2, function() {
    grid.newpage(); txt("Pipeline", 1.0, 0.22, 6.8, "left", face = "bold"); txt("AUC", 9.1, 0.22, 6.8, "left", face = "bold"); txt("A (points)", 10.4, 0.22, 6.8, "left", face = "bold")
    hl(0.1, 12.1, 0.42, 0.6)
    for (r in 1:5) { ch <- linhas[r]; t <- 0.55 + (r - 1) * 0.72
      f <- if (ch == "unfiltered") "paineis/cadeias/exame_original.png" else file.path("paineis/extremas", paste0(gsub(" > ", "_", ch), ".png")); img(readPNG(f), 0.1, t, 0.64)
      if (ch == "unfiltered") { auc <- auc0; a <- A0; n <- "unfiltered" } else { row <- s[s$pipeline == ch, ]; auc <- row$AUC_mean4; a <- row$A_points_mean4; n <- nm(ch) }
      txt(n, 1.0, t + 0.32, 6.8, "left", maxw = 7.9); txt(sprintf("%.3f", auc), 9.1, t + 0.32, 6.8, "left"); txt(sprintf("%.1f", a), 10.4, t + 0.32, 6.8, "left") }
    hl(0.1, 12.1, 4.17, 0.6)
  })
}

# ------------------------------------------------------------------------------------------------ Figura 8 (D): heatmap divergente por rede
fig8D <- function() {
  lt <- rd("lesion_type.csv"); lt$rede <- factor(NOME[match(lt$arch, ARCH)], NOME)
  lt$f <- factor(c(AHE40.0 = "AHE", CLAHE4.0 = "CLAHE", GreenChannel = "Green channel", Grayscale = "Grayscale")[lt$filter], c("AHE", "CLAHE", "Green channel", "Grayscale"))
  lt$tipo <- factor(lt$lesion, c("MA", "HE", "EX", "SE")); lt$lab <- sprintf("%+.0f%s", lt$dA_pct_of_unfiltered, ifelse(as.logical(lt$significant), "*", ""))
  g <- ggplot(lt, aes(tipo, f, fill = dA_pct_of_unfiltered)) + geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = lab, colour = abs(dA_pct_of_unfiltered) > 65), size = 6.4 * PT, family = FONTE) + scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "black")) +
    scale_fill_distiller(palette = "RdBu", direction = -1, limits = c(-100, 100), oob = scales::squish) + scale_y_discrete(limits = rev(levels(lt$f))) + scale_x_discrete(position = "top") +
    facet_wrap(~rede, nrow = 1) + labs(x = NULL, y = NULL) + tema() +
    theme(axis.line = element_blank(), axis.ticks = element_blank(), axis.text = element_text(size = 6.5), panel.spacing = unit(0.15, "cm"), strip.text = element_text(size = 6.6), legend.position = "none")
  sg(g, 8, "D", 4.2)
}

for (f in list(fig2F, fig3D, fig4H, fig5G, fig6E, fig8D)) { r <- tryCatch({ suppressMessages(f()); "ok" }, error = function(e) paste("ERRO:", conditionMessage(e))); cat(r, "\n") }
cat(unique(AVISOS), sep = "\n"); cat("feito\n")
