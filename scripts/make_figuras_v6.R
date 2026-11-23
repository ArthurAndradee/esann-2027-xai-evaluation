# Rodada 6 (feedback do usuário). Só PDFs em escolhidas/. Reaproveita o cabeçalho de make_figuras_v5.R (helpers) e redefine as figuras 2, 4, 5 e 8.
# A Figura 3 vira tabela no .tex (ver dados/tabela_redes.tex). Uso (na pasta esann_materiais/): Rscript make_figuras_v6.R
v5 <- readLines("make_figuras_v5.R"); k5 <- grep("^# -+ Figura 2 \\(F\\)", v5)[1]
eval(parse(text = v5[1:(k5 - 1)]))
STAGE <- c("Illumination", "Color", "Local contrast", "Refinement")
STG <- c(BenGraham = 1, Gamma0.8 = 1, Retinex = 1, HistogramEq = 1, LABNorm = 1, GreenChannel = 2, MaxGreen2.0 = 2, Grayscale = 2, AHE40.0 = 3, CLAHE4.0 = 3,
         Unsharp1.5 = 4, Median = 4, Gaussian = 4, Morpho = 4, Frangi = 4, Canny = 4, Otsu = 4)

# ---------------------------------------------------------------------------------------------- Figura 2 (G)
fig2G <- function() sgrid(2, "H", 2.1, function() {
  grid.newpage(); cad <- "BenGraham_CLAHE4.0_Gaussian"; pas <- function(j) readPNG(sprintf("paineis/cadeias/%s__passo%d.png", cad, j))
  iw <- 1.1; ti <- 0.4; cx <- c(2.2, 4.55, 6.9, 9.25)
  img(readPNG("paineis/cadeias/exame_original.png"), 0.65 - iw / 2, ti, iw)
  imgs <- list(pas(1), NULL, pas(2), pas(3)); xp <- 0.65 + iw / 2
  for (k in 1:4) {
    xi <- cx[k] - iw / 2; seta(xp + 0.06, ti + iw / 2, xi - 0.06, ti + iw / 2, 0.8); xp <- xi + iw
    if (is.null(imgs[[k]])) { rrect(xi, ti, iw, iw, "white", "grey50", 0.6, 2); txt("—", cx[k], ti + iw / 2, 7, col = "grey40") } else img(imgs[[k]], xi, ti, iw)
    txt(STAGE[k], cx[k], 0.18, 7, face = "bold", maxw = 2.5, minsize = 6.3)
  }
  f <- c("(5+1)", "(3+1)", "(2+1)", "(7+1)"); ty <- ti + iw + 0.36
  for (k in 1:4) txt(f[k], cx[k], ty, 7)
  for (k in 1:3) txt("×", (cx[k] + cx[k + 1]) / 2, ty, 7)
  txt("= 576 combinations", 12.1, ty, 7, "right", face = "bold")
})

# ---------------------------------------------------------------------------------------------- Figura 4 (I): mesmos 4 estágios do pipeline, linha azul simples
fig4I <- function() {
  fe <- rd("filter_effects_wide.csv"); fe$nm <- LAB[fe$filter]; fe$stage <- factor(STAGE[STG[fe$filter]], STAGE)
  fe <- fe[order(fe$stage, fe$kept_pct_mean), ]; fe$nm <- factor(fe$nm, rev(fe$nm))
  L <- do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(nm = fe$nm, stage = fe$stage, kept = fe[[paste0("kept_pct_", ARCH[j])]], rede = factor(NOME[j], NOME))))
  g <- ggplot(L, aes(kept, nm)) + geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.35, colour = "grey40") +
    geom_segment(aes(x = 100, xend = kept, yend = nm), linewidth = 1.1, colour = "#1f5fa8", lineend = "butt") +
    facet_grid(stage ~ rede, scales = "free_y", space = "free_y", switch = "y") +
    scale_x_continuous(breaks = c(0, 100, 200), limits = c(-5, 225), expand = c(0, 0)) + labs(x = "Lesion reliance kept (%)", y = NULL) + tema() +
    theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0, hjust = 1, size = 6.6, face = "bold"), strip.text.x = element_text(size = 6.5, face = "bold"), strip.background = element_blank(),
          panel.spacing.x = unit(0.45, "cm"), panel.spacing.y = unit(0.14, "cm"), axis.text.y = element_text(size = 6.6), axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.line.x = element_blank(),
          panel.grid.major.x = element_line(colour = "grey91", linewidth = 0.25), panel.border = element_rect(colour = "grey70", fill = NA, linewidth = 0.3), plot.margin = margin(3, 6, 2, 3))
  sg(g, 4, "I", 7.0)
}

# ---------------------------------------------------------------------------------------------- Figura 5 (H): cores sólidas à direita, (a)/(b) alinhados ao painel
fig5H <- function() {
  pl <- rd("pipelines_long.csv"); lad <- rd("correlations_ladder.csv"); pl$rede <- factor(NOME[match(pl$arch, ARCH)], NOME)
  pm <- aggregate(cbind(AUC, A_points) ~ chain + rede, pl, mean)
  pl$mAUC <- ave(pl$AUC, pl$chain, pl$arch); pl$mA <- ave(pl$A_points, pl$chain, pl$arch); pl$dAUC <- pl$AUC - pl$mAUC; pl$dA100 <- (pl$A_points - pl$mA)
  bet <- lad[lad$tipo == "between pipelines", ]$rho; wit <- lad[lad$tipo == "between runs of one pipeline", ]$rho
  cols <- c("#0072b2", "#d55e00", "#009e73", "#cc79a7"); shp <- c(16, 15, 17, 18); curto <- c("EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50")
  mk <- function(d, x, y, rho, smooth, tag, xl, yl) {
    lab <- sprintf("%s  ρ = %.2f", curto, rho); d$lab <- factor(lab[as.integer(d$rede)], lab)
    ggplot(d, aes(.data[[x]], .data[[y]], colour = lab, shape = lab, linetype = lab)) +
      geom_point(size = if (smooth) 1.2 else 1.3, alpha = 0.45, stroke = 0.4) +
      (if (smooth) geom_smooth(method = "loess", se = FALSE, linewidth = 0.6, formula = y ~ x)
       else geom_smooth(data = function(z) z[abs(z$dAUC) <= 0.05, ], method = "lm", se = FALSE, linewidth = 0.6, formula = y ~ x, fullrange = TRUE)) +
      scale_colour_manual(values = setNames(cols, lab)) + scale_shape_manual(values = setNames(shp, lab)) + scale_linetype_manual(values = setNames(rep("solid", 4), lab)) +
      labs(x = xl, y = yl, title = tag) + tema() + guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 1.8, alpha = 1, linewidth = 0.6)), shape = guide_legend(nrow = 2, byrow = TRUE), linetype = guide_legend(nrow = 2, byrow = TRUE)) +
      theme(legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 6.4), legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = 0), legend.spacing.x = unit(0.1, "cm"),
            panel.grid.major = element_line(colour = "grey92", linewidth = 0.25), plot.title = element_text(size = 7.5, face = "bold", hjust = 0, margin = margin(b = 3)), plot.title.position = "panel", plot.margin = margin(3, 6, 2, 3))
  }
  a <- mk(pm, "AUC", "A_points", bet, TRUE, "(a)", "AUC (mean of the 3 runs of a pipeline)", "Lesion reliance A (points)") +
    scale_x_continuous(breaks = c(0.5, 0.6, 0.7, 0.8, 0.9), limits = c(0.45, 0.95), expand = c(0, 0)) + scale_y_continuous(limits = c(-2, 21), breaks = c(0, 5, 10, 15, 20), expand = c(0, 0))
  b <- mk(pl, "dAUC", "dA100", wit, FALSE, "(b)", "AUC − mean of its pipeline", "A − mean of its pipeline (points)") + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey55") + geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey55") +
    scale_x_continuous(breaks = c(-0.04, 0, 0.04)) + coord_cartesian(xlim = c(-0.05, 0.05), ylim = c(-0.08, 0.09) * 100, expand = FALSE)
  sg(suppressMessages(a + b + plot_layout(widths = c(1.05, 1))), 5, "K", 6.0)
}

# ---------------------------------------------------------------------------------------------- Figura 8 (E): heatmap com barra de cores vertical à direita
fig8E <- function() {
  lt <- rd("lesion_type.csv"); lt$rede <- factor(NOME[match(lt$arch, ARCH)], NOME)
  lt$f <- factor(c(AHE40.0 = "AHE", CLAHE4.0 = "CLAHE", GreenChannel = "Green channel", Grayscale = "Grayscale")[lt$filter], c("AHE", "CLAHE", "Green channel", "Grayscale"))
  lt$tipo <- factor(lt$lesion, c("MA", "HE", "EX", "SE")); lt$lab <- gsub("-", "\u2212", sprintf("%+.0f%s", lt$dA_pct_of_unfiltered, ifelse(as.logical(lt$significant), "*", "")), fixed = TRUE)
  g <- ggplot(lt, aes(tipo, f, fill = dA_pct_of_unfiltered)) + geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = lab, colour = abs(dA_pct_of_unfiltered) > 65), size = 5.3 * PT, family = FONTE) + scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "black"), guide = "none") +
    scale_fill_gradientn(colours = c("#1b5fa8", "#7fb0de", "#ffffff", "#f8b878", "#e8710a"), limits = c(-100, 100), oob = scales::squish, breaks = c(-100, -50, 0, 50, 100), labels = function(x) paste0(x, "%"), name = "ΔA (% of unfiltered)",
                         guide = guide_colourbar(direction = "vertical", title.position = "right", title.theme = element_text(angle = 90, hjust = 0.5, size = 7.4, family = FONTE), barwidth = unit(0.3, "cm"), barheight = unit(3.3, "cm"), ticks.colour = "black", frame.colour = "grey40", frame.linewidth = 0.2)) +
    scale_y_discrete(limits = rev(levels(lt$f))) + scale_x_discrete(position = "top") + facet_wrap(~rede, nrow = 1) + labs(x = NULL, y = NULL) + tema() +
    theme(axis.line = element_blank(), axis.ticks = element_blank(), axis.text = element_text(size = 7.4), panel.spacing = unit(0.15, "cm"), strip.text = element_text(size = 7.4),
          legend.position = "right", legend.justification = "top", legend.text = element_text(size = 7.2), legend.margin = margin(l = 2, t = 0, b = 0), legend.box.margin = margin(0, 0, 0, 0), plot.margin = margin(1, 3, 1, 1))
  sg(g, 8, "G", 4.2)
}

for (f in list(fig2G, fig4I, fig5H, fig8E)) { r <- tryCatch({ suppressMessages(f()); "ok" }, error = function(e) paste("ERRO:", conditionMessage(e))); cat(r, "\n") }
cat(unique(AVISOS), sep = "\n"); cat("feito\n")
