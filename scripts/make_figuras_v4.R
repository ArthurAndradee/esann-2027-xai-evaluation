# Rodada 4 das figuras (feedback do usuário): redesenha 2D, 3A, 4B e 5C com mais espaço e mais cuidado visual.
# Mantém a 1A como está. Cada figura sai em versão COLORIDA (para slides) e, onde há cor, em versão para IMPRESSÃO (forma/cinza).
# Uso (na pasta esann_materiais/): Rscript make_figuras_v4.R
# Princípios (convenções de visualização usadas em artigos de IA para retinopatia diabética e de explicabilidade):
#  - fluxo de método com exemplo real embutido (imagem entrando e saindo de cada etapa), como nos diagramas de pipeline;
#  - "table-plot": linhas zebradas com barras/pontos alinhados por coluna e eixo próprio (Cleveland dot plot, Tufte);
#  - pirulitos (lollipop) saindo de uma referência (100%) para mostrar queda ou aumento, com faixas por família de filtro;
#  - correlações com a reta por rede e o rho escrito na própria figura, como em gráficos de fidelidade da explicação.
lines <- readLines("make_figuras_v3.R"); k <- grep("^# =+ FIGURA 1", lines)[1]
eval(parse(text = lines[1:(k - 1)]))                    # reaproveita helpers (tema, sg, sgrid, txt, img, seta, ...)
PAL <- c(destructive = "#8c8c8c", `contrast equalization` = "#d55e00", `smoothing / sharpening` = "#0072b2",
         illumination = "#cc79a7", neutral = "#009e73", color = "#e69f00")
FAMORD <- names(PAL); FAMSHAPE <- c(destructive = 4, `contrast equalization` = 17, `smoothing / sharpening` = 15, illumination = 18, neutral = 16, color = 3)
NETCOL <- c("#0072b2", "#d55e00", "#009e73", "#cc79a7"); NETSHP <- c(16, 15, 17, 18)
rrect <- function(x, t, w, h, fill, col, lwd = 0.8, lty = 1, r = 0.12) grid.roundrect(x = cm(x), y = Y(t), width = cm(w), height = cm(h), just = c("left", "top"), r = unit(r, "cm"), gp = gpar(fill = fill, col = col, lwd = lwd, lty = lty))
nm1 <- function(x) { p <- strsplit(x, " > ")[[1]]; paste(sapply(p, function(z) if (z %in% names(LAB)) LAB[[z]] else z), collapse = " > ") }

# ================================================================================ Figura 2, versão E: anatomia do pipeline com exemplo
fig2E <- function() {
  H <- 5.3
  sgrid(2, "E", H, function() {
    grid.newpage()
    cad <- "BenGraham_CLAHE4.0_Gaussian"; pas <- function(j) readPNG(sprintf("paineis/cadeias/%s__passo%d.png", cad, j))
    ex <- readPNG("paineis/cadeias/exame_original.png")
    st <- list(list("1", "Illumination", "5 options", c("Ben Graham", "Gamma", "Retinex", "Histogram eq.", "LAB norm.", "— omit —"), 1, "#dbe7f5", "#3b6ea8"),
               list("2", "Color", "3 options", c("Green channel", "MaxGreen", "Grayscale", "— omit —"), 4, "#dcefe0", "#3f8f55"),
               list("3", "Local contrast", "2 options", c("AHE", "CLAHE", "— omit —"), 2, "#fbe6d0", "#c4691f"),
               list("4", "Refinement", "7 options", c("Unsharp mask", "Median", "Gaussian", "Opening", "Frangi", "Canny", "Otsu", "— omit —"), 3, "#e8def2", "#7a56a6"))
    bx <- function(k) 1.85 + (k - 1) * 2.58; bw <- 2.4; iw <- 1.1
    # ---- linha do exemplo (imagens)
    txt("input", 0.1 + iw / 2, 0.2, 6.5, col = "grey25"); img(ex, 0.1, 0.33, iw)
    imgs <- list(pas(1), NULL, pas(2), pas(3))
    for (k in 1:4) {
      xi <- bx(k) + (bw - iw) / 2; xp <- if (k == 1) 0.1 + iw else bx(k - 1) + (bw - iw) / 2 + iw
      seta(xp + 0.05, 0.88, xi - 0.05, 0.88, 0.8)
      if (is.null(imgs[[k]])) { rrect(xi, 0.33, iw, iw, "white", "grey55", 0.6, 2); txt("skipped", xi + iw / 2, 0.88, 6.2, col = "grey35") } else img(imgs[[k]], xi, 0.33, iw)
      grid.lines(x = cm(rep(xi + iw / 2, 2)), y = Y(c(1.45, 1.78)), gp = gpar(lty = 3, lwd = 0.7, col = st[[k]][[7]]))
    }
    txt("example: Ben Graham → CLAHE → Gaussian", 12.1, 0.2, 6.3, "right", "grey25", maxw = 4.2)
    # ---- caixas de estágio
    for (k in 1:4) {
      S <- st[[k]]; x <- bx(k); t0 <- 1.8; h <- 2.62
      rrect(x, t0, bw, h, S[[6]], S[[7]], 1.0)
      grid.circle(x = cm(x + 0.27), y = Y(t0 + 0.27), r = cm(0.17), gp = gpar(fill = S[[7]], col = NA)); txt(S[[1]], x + 0.27, t0 + 0.27, 6.8, col = "white", face = "bold")
      txt(S[[2]], x + 0.55, t0 + 0.21, 6.7, "left", face = "bold", maxw = bw - 0.6); txt(S[[3]], x + 0.55, t0 + 0.42, 6.2, "left", "grey25", maxw = bw - 0.6)
      for (j in seq_along(S[[4]])) {
        t <- t0 + 0.76 + (j - 1) * 0.225
        if (j == S[[5]]) { rrect(x + 0.1, t - 0.1, bw - 0.2, 0.21, "white", S[[7]], 0.9, 1, 0.06); txt(S[[4]][j], x + 0.2, t, 6.3, "left", face = "bold", maxw = bw - 0.35) }
        else txt(S[[4]][j], x + 0.2, t, 6.3, "left", "grey15", maxw = bw - 0.35)
      }
      if (k < 4) seta(x + bw + 0.02, t0 + h / 2, x + bw + 0.18, t0 + h / 2, 1.0)
    }
    # ---- funil numérico
    pill <- function(x, w, a, b, fill) { rrect(x, 4.65, w, 0.55, fill, "grey40", 0.8, 1, 0.25); txt(a, x + w / 2, 4.8, 7.0, face = "bold", maxw = w - 0.2); txt(b, x + w / 2, 5.03, 6.2, col = "grey20", maxw = w - 0.2) }
    pill(0.1, 3.7, "576 pipelines", "(5+1) × (3+1) × (2+1) × (7+1)", "grey96")
    pill(4.2, 3.9, "185 trained", "18 + 150 D-optimal + 20 random", "grey91")
    pill(8.5, 3.6, "2,220 models", "185 pipelines × 4 networks × 3 runs", "grey86")
    seta(3.85, 4.92, 4.15, 4.92, 1.0); seta(8.15, 4.92, 8.45, 4.92, 1.0)
  })
}

# ================================================================================ Figura 3, versão C: table-plot espaçado
fig3C <- function() {
  nt <- rd("networks.csv"); nt$nome <- NOME[match(nt$arch, ARCH)]; H <- 4.4
  fam <- c(EfficientNetV2 = "#dbe7f5", Inception = "#fbe6d0", ResNet = "#e2f0d9")
  sgrid(3, "C", H, function() {
    grid.newpage()
    cx <- list(nome = 0.15, fam = 2.55, par = c(4.15, 6.15), auc = c(7.55, 9.35), A = c(10.4, 11.5))
    hdr <- function(s, x, w) txt(s, x, 0.38, 6.6, "left", face = "bold", maxw = w, minsize = 6.2)
    hdr("Network", cx$nome, 2.3); hdr("Family", cx$fam, 1.4); hdr("Backbone\nparams (M)", cx$par[1], 2.4); hdr("AUC, unfiltered\n(mean ± SD)", cx$auc[1] - 0.3, 2.6); hdr("A, unfiltered\n(points)", cx$A[1] - 0.2, 1.7)
    grid.lines(x = cm(c(0.1, 12.1)), y = Y(c(0.78, 0.78)), gp = gpar(lwd = 0.7))
    t0 <- 0.95; pit <- 0.6
    sc <- function(v, lim, ax) ax[1] + (v - lim[1]) / (lim[2] - lim[1]) * (ax[2] - ax[1])
    for (r in 1:4) {
      x <- nt[r, ]; t <- t0 + (r - 1) * pit
      if (r %% 2 == 1) grid.rect(x = cm(0.1), y = Y(t - 0.04), width = cm(12.0), height = cm(pit - 0.02), just = c("left", "top"), gp = gpar(fill = "grey95", col = NA))
      tm <- t + pit / 2 - 0.03
      txt(x$nome, cx$nome, tm, 6.9, "left", maxw = 2.3, minsize = 6.3)
      rrect(cx$fam, tm - 0.13 + 0.0, 1.45, 0.27, fam[[x$family]], "grey55", 0.5, 1, 0.12); txt(x$family, cx$fam + 0.725, tm, 6.3, maxw = 1.35, minsize = 6.0)
      xp <- sc(x$params_millions_backbone, c(0, 25), cx$par); grid.lines(x = cm(c(cx$par[1], xp)), y = Y(c(tm, tm)), gp = gpar(lwd = 1.1, col = "grey40")); grid.points(x = cm(xp), y = Y(tm), pch = 16, size = unit(4.2, "pt"), gp = gpar(col = "grey15"))
      txt(sprintf("%.1f", x$params_millions_backbone), xp + 0.12, tm, 6.6, "left")
      xa <- sc(x$auc_unfiltered_mean, c(0.89, 0.93), cx$auc); xs <- (x$auc_unfiltered_sd / 0.04) * (cx$auc[2] - cx$auc[1])
      grid.lines(x = cm(c(xa - xs, xa + xs)), y = Y(c(tm, tm)), gp = gpar(lwd = 1.2, col = "grey30")); grid.points(x = cm(xa), y = Y(tm), pch = 21, size = unit(4.6, "pt"), gp = gpar(col = "grey15", fill = "white", lwd = 1.2))
      txt(sprintf("%.3f", x$auc_unfiltered_mean), cx$auc[2] + 0.15, tm, 6.6, "left")
      xv <- sc(x$A_unfiltered_points, c(0, 13), cx$A); grid.lines(x = cm(c(cx$A[1], xv)), y = Y(c(tm, tm)), gp = gpar(lwd = 1.1, col = "grey40")); grid.points(x = cm(xv), y = Y(tm), pch = 16, size = unit(4.2, "pt"), gp = gpar(col = "grey15"))
      txt(sprintf("%.1f", x$A_unfiltered_points), xv + 0.12, tm, 6.6, "left")
    }
    ya <- t0 + 4 * pit + 0.1
    axis_col <- function(ax, lim, ticks, labs) { grid.lines(x = cm(ax), y = Y(c(ya, ya)), gp = gpar(lwd = 0.5, col = "grey50"))
      for (i in seq_along(ticks)) { xx <- sc(ticks[i], lim, ax); grid.lines(x = cm(c(xx, xx)), y = Y(c(ya, ya + 0.07)), gp = gpar(lwd = 0.5, col = "grey50")); txt(labs[i], xx, ya + 0.2, 6.3, col = "grey25") } }
    axis_col(cx$par, c(0, 25), c(0, 10, 20), c("0", "10", "20")); axis_col(cx$auc, c(0.89, 0.93), c(0.89, 0.91, 0.93), c("0.89", "0.91", "0.93")); axis_col(cx$A, c(0, 13), c(0, 5, 10), c("0", "5", "10"))
    txt("backbone without the classification head; A = lesion reliance (probability points)", 0.15, H - 0.2, 6.3, "left", "grey35", maxw = 11.8)
  })
}

# ================================================================================ Figura 4, versões F (slides, colorida) e G (impressão)
fig4FG <- function() {
  fe <- rd("filter_effects_wide.csv"); fe$nm <- LAB[fe$filter]
  fe$family <- factor(fe$family, FAMORD)
  ord <- fe[order(fe$family, fe$kept_pct_mean), ]; ord$y <- seq_len(nrow(ord))
  L <- do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(filter = ord$filter, nm = ord$nm, family = ord$family, y = ord$y, kept = ord[[paste0("kept_pct_", ARCH[j])]], rede = factor(NOME[j], NOME))))
  bands <- do.call(rbind, lapply(seq_along(FAMORD), function(i) { yy <- ord$y[ord$family == FAMORD[i]]; data.frame(fam = FAMORD[i], ymin = min(yy) - 0.5, ymax = max(yy) + 0.5, odd = i %% 2 == 1) }))
  mk <- function(colored) {
    g <- ggplot(L, aes(kept, y)) +
      geom_rect(data = bands, aes(xmin = -Inf, xmax = Inf, ymin = ymin, ymax = ymax, fill = odd), inherit.aes = FALSE, show.legend = FALSE) +
      scale_fill_manual(values = c(`TRUE` = "grey94", `FALSE` = "white")) +
      geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.35, colour = "grey35") +
      geom_segment(aes(x = 100, xend = kept, yend = y, colour = if (colored) family else NULL), linewidth = 0.55, alpha = 0.85, show.legend = FALSE)
    g <- g + (if (colored) geom_point(aes(colour = family, shape = family), size = 2.0, stroke = 0.6) else geom_point(aes(shape = family), size = 2.0, stroke = 0.6, colour = "grey10"))
    g <- g + (if (colored) scale_colour_manual(values = PAL) else scale_colour_manual(values = rep("grey10", 6))) + scale_shape_manual(values = FAMSHAPE)
    g + facet_wrap(~rede, nrow = 1) + scale_y_reverse(breaks = ord$y, labels = ord$nm, expand = expansion(add = 0.6)) +
      scale_x_continuous(breaks = c(0, 100, 200), limits = c(-5, 225), expand = c(0, 0)) +
      labs(x = "Lesion reliance kept, % of the unfiltered model", y = NULL) + tema() +
      theme(axis.text.y = element_text(size = 6.8), axis.text.x = element_text(size = 6.6), strip.text = element_text(size = 7.2, face = "bold"), panel.spacing = unit(0.5, "cm"),
            axis.line.y = element_blank(), axis.ticks.y = element_blank(), panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.25),
            legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 6.6), legend.key.size = unit(0.34, "cm"), legend.margin = margin(t = 0),
            plot.margin = margin(3, 6, 2, 3)) + guides(shape = guide_legend(nrow = 2, override.aes = list(size = 2.2)), colour = guide_legend(nrow = 2))
  }
  versao(4, "F", 7.9, sg(mk(TRUE), 4, "F", 7.9)); versao(4, "G", 7.9, sg(mk(FALSE), 4, "G", 7.9))
}

# ================================================================================ Figura 5, versões E (colorida) e F (impressão)
fig5EF <- function() {
  pl <- rd("pipelines_long.csv"); lad <- rd("correlations_ladder.csv"); pl$rede <- factor(NOME[match(pl$arch, ARCH)], NOME)
  pm <- aggregate(cbind(AUC, A_points) ~ chain + rede, pl, mean)
  pl$mAUC <- ave(pl$AUC, pl$chain, pl$arch); pl$mA <- ave(pl$A_points, pl$chain, pl$arch); pl$dAUC <- pl$AUC - pl$mAUC; pl$dA <- pl$A_points - pl$mA
  bet <- lad[lad$tipo == "between pipelines", ]; wit <- lad[lad$tipo == "between runs of one pipeline", ]
  mk <- function(colored) {
    cols <- if (colored) NETCOL else c("black", "grey30", "grey50", "grey65"); lt <- if (colored) rep("solid", 4) else c("solid", "dashed", "dotted", "dotdash")
    leg <- function(rho, y0, x0, dx, xt) { d <- data.frame(rede = factor(NOME, NOME), y = y0 - (0:3) * dx, lab = sprintf("%s   ρ = %.2f", NOME, rho))
      list(geom_point(data = d, aes(x0, y, colour = rede, shape = rede), size = 1.7, inherit.aes = FALSE), geom_text(data = d, aes(xt, y, label = lab), hjust = 0, size = 6.5 * PT, family = FONTE, inherit.aes = FALSE)) }
    a <- ggplot(pm, aes(AUC, A_points, colour = rede, shape = rede)) + geom_point(size = 1.15, alpha = 0.7, stroke = 0.4) +
      geom_smooth(aes(linetype = rede), method = "loess", se = FALSE, linewidth = 0.6, formula = y ~ x) + leg(bet$rho, 24, 0.485, 3.1, 0.50) +
      scale_colour_manual(values = cols) + scale_shape_manual(values = NETSHP) + scale_linetype_manual(values = lt) +
      scale_x_continuous(breaks = c(0.5, 0.6, 0.7, 0.8, 0.9), limits = c(0.45, 0.95), expand = c(0, 0)) + scale_y_continuous(limits = c(-2, 26), breaks = c(0, 10, 20), expand = c(0, 0)) +
      labs(x = "AUC (mean of the 3 runs of a pipeline)", y = "Lesion reliance A (points)", title = "(a) Between pipelines: AUC and A move together") + tema() +
      theme(plot.title = element_text(size = 7.2, face = "bold"), panel.grid.major = element_line(colour = "grey92", linewidth = 0.25), plot.margin = margin(3, 8, 2, 3))
    b <- ggplot(pl, aes(dAUC, dA * 100, colour = rede, shape = rede)) + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey60") + geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey60") +
      geom_point(size = 0.8, alpha = 0.4, stroke = 0.3) + leg(wit$rho, 13.3, -0.0465, 1.5, -0.0415) +
      scale_colour_manual(values = cols) + scale_shape_manual(values = NETSHP) + scale_linetype_manual(values = lt) +
      scale_x_continuous(breaks = c(-0.04, 0, 0.04)) + coord_cartesian(xlim = c(-0.05, 0.05), ylim = c(-8, 14.5), expand = FALSE) +
      labs(x = "AUC − mean of its pipeline", y = "A − mean of its pipeline (points)", title = "(b) Between runs of one pipeline: no relation") + tema() +
      theme(plot.title = element_text(size = 7.2, face = "bold"), panel.grid.major = element_line(colour = "grey92", linewidth = 0.25), plot.margin = margin(3, 8, 2, 6))
    (a + b + plot_layout(widths = c(1.05, 1))) & theme(legend.position = "none")
  }
  versao(5, "E", 5.4, sg(suppressMessages(mk(TRUE)), 5, "E", 5.4)); versao(5, "F", 5.4, sg(suppressMessages(mk(FALSE)), 5, "F", 5.4))
}

# ================================================================================ Figura 7, versões C (slides) e D (impressão): validade no DDR
fig7CD <- function() {
  d <- rd("ddr_results.csv"); b <- rd("networks.csv"); d$fg <- b$auc_unfiltered_mean[match(d$arch, b$arch)]; d$rede <- factor(NOME[match(d$arch, ARCH)], rev(NOME))
  d$ok <- d$`atinge_0.70` == "sim"; n_ok <- sum(d$ok)
  mk <- function(colored) {
    zona <- if (colored) "#f6d5cf" else "grey90"; cok <- if (colored) "#1b7a4b" else "black"; cno <- if (colored) "#b3261e" else "grey35"
    g <- ggplot(d, aes(y = rede)) + annotate("rect", xmin = 0.5, xmax = 0.70, ymin = 0.35, ymax = 4.65, fill = zona) +
      annotate("text", x = 0.508, y = 0.55, label = "below the validity threshold", size = 6.3 * PT, family = FONTE, colour = cno, fontface = "italic", hjust = 0) +
      geom_vline(xintercept = 0.70, linewidth = 0.5, linetype = "dashed", colour = "grey20") +
      annotate("text", x = 0.705, y = 0.5, label = "0.70", size = 6.5 * PT, family = FONTE, hjust = 0, fontface = "bold") +
      geom_segment(aes(x = fg, xend = auc_baseline_media, yend = rede), arrow = arrow(length = unit(0.12, "cm"), type = "closed"), linewidth = 0.45, colour = "grey45") +
      geom_linerange(aes(xmin = auc_baseline_ic95_inf, xmax = auc_baseline_ic95_sup, colour = ok), orientation = "y", linewidth = 1.0) +
      geom_point(aes(x = fg), shape = 21, fill = "white", colour = "grey30", size = 2.6, stroke = 0.7) +
      geom_point(aes(x = auc_baseline_media, colour = ok, shape = ok, fill = ok), size = 3.0, stroke = 0.7) +
      geom_text(aes(x = auc_baseline_media, label = sprintf("%.2f", auc_baseline_media), colour = ok), nudge_y = 0.33, size = 6.6 * PT, family = FONTE, fontface = "bold") +
      geom_text(aes(x = fg, label = sprintf("%.2f", fg)), nudge_y = 0.33, size = 6.3 * PT, family = FONTE, colour = "grey30") +
      scale_colour_manual(values = c(`TRUE` = cok, `FALSE` = cno)) + scale_fill_manual(values = c(`TRUE` = cok, `FALSE` = "white")) + scale_shape_manual(values = c(`TRUE` = 21, `FALSE` = 21)) +
      scale_x_continuous(limits = c(0.5, 0.97), breaks = c(0.5, 0.6, 0.7, 0.8, 0.9), expand = c(0, 0)) + scale_y_discrete(expand = expansion(add = c(0.45, 0.7))) +
      labs(x = "AUC of the unfiltered model:  \u25cb trained and tested on FGADR   \u2192   \u25cf tested on DDR (95% CI)", y = NULL) + tema() +
      theme(axis.text.y = element_text(size = 7), panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.25), axis.line.y = element_blank(), axis.ticks.y = element_blank(), plot.margin = margin(3, 8, 2, 3))
    cards <- data.frame(x = c(0, 1, 2), h = c("H4", "H5a", "H5b"), t = c("CLAHE reduces A", "Green channel increases A", "Grayscale increases A"))
    cv <- ggplot(cards) + geom_rect(aes(xmin = x * 1.02 + 0.02, xmax = x * 1.02 + 0.98, ymin = 0, ymax = 1), fill = if (colored) "#fff4d6" else "grey95", colour = if (colored) "#b88700" else "grey40", linewidth = 0.5) +
      geom_text(aes(x = x * 1.02 + 0.5, y = 0.88, label = h), size = 7.2 * PT, family = FONTE, fontface = "bold") + geom_text(aes(x = x * 1.02 + 0.5, y = 0.70, label = t), size = 6.4 * PT, family = FONTE) +
      geom_text(aes(x = x * 1.02 + 0.5, y = 0.51, label = "\u25cb  not assessable"), size = 7 * PT, family = FONTE, fontface = "bold", colour = if (colored) "#8a6500" else "black") +
      geom_text(aes(x = x * 1.02 + 0.5, y = 0.19, lineheight = 0.9, label = sprintf("%d of 4 networks ≥ 0.70\n(rule: at least 3)", n_ok)), size = 6.2 * PT, family = FONTE, colour = "grey25") +
      scale_x_continuous(limits = c(0, 3.06), expand = c(0, 0)) + scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) + theme_void()
    g / cv + plot_layout(heights = c(3.0, 1.45))
  }
  versao(7, "C", 5.4, sg(mk(TRUE), 7, "C", 5.4)); versao(7, "D", 5.4, sg(mk(FALSE), 7, "D", 5.4))
}

for (f in list(fig2E, fig3C, fig4FG, fig5EF, fig7CD)) { r <- tryCatch({ f(); "ok" }, error = function(e) paste("ERRO:", conditionMessage(e))); if (r != "ok") { LOG <- c(LOG, r); cat(r, "\n") } }
for (n in 2:7) tryCatch(contato(n), error = function(e) cat("contato", n, conditionMessage(e), "\n"))
writeLines(c(LOG, "", unique(AVISOS)), file.path(FIG, "relatorio_execucao_v4.txt")); cat("feito\n")
