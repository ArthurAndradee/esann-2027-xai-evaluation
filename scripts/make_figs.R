# Figuras do artigo ESANN 2027 (largura 12,2 cm; PDF vetorial via cairo_pdf; legíveis em preto e branco).
# Uso, na pasta esann_figs/:  Rscript make_figs.R [1 2 3 4]
# Entradas (make_data.py, make_ddr.py, make_fig1_panels.py): fig2_data.csv, fig2_baseline.csv, fig3_*.csv, fig4_data.csv,
# fig1_info.json, fig1_panels/*.png. Pacotes: ggplot2, patchwork, png (em ~/Rlibs). Fonte: Liberation Serif (~/.fonts).
#
# Princípios do redesenho (cada figura foi redesenhada, não copiada da referência):
#  - nenhum texto abaixo de 6,3 pt; legendas fora das regiões de dados; espaço entre elementos;
#  - rótulos diretos em vez de tabelas de legenda; valores escritos onde o leitor precisa deles;
#  - a Figura 1 checa por código se cada texto cabe na sua caixa (avisa e reduz até 6,0 pt, nunca corta).
.libPaths(c("~/Rlibs", .libPaths()))
suppressMessages({library(ggplot2); library(patchwork); library(png); library(grid)})

W <- 12.2 / 2.54
FONTE <- "Liberation Serif"
SAIDA <- "figs"; dir.create(SAIDA, showWarnings = FALSE)
ARCH <- c("efficientnetv2s", "efficientnetv2b2", "inceptionv3", "resnet50")
HEAD <- c("EffNetV2\nS", "EffNetV2\nB2", "Inception\nV3", "ResNet\n50")
LAB <- c(`AHE40.0` = "AHE", `CLAHE4.0` = "CLAHE", `MaxGreen2.0` = "MaxGreen", `Unsharp1.5` = "Unsharp mask",
         `Gamma0.8` = "Gamma", GreenChannel = "Green channel", HistogramEq = "Histogram eq.", BenGraham = "Ben Graham",
         LABNorm = "LAB normaliz.", Morpho = "Opening", Median = "Median", Retinex = "Retinex", Gaussian = "Gaussian",
         Grayscale = "Grayscale", Frangi = "Frangi", Canny = "Canny", Otsu = "Otsu")
PT <- 25.4 / 72.27                      # 1 pt em mm (tamanho de texto do ggplot é em mm)
TXT <- 6.8                              # texto padrão (pt)

tema <- function() theme_classic(base_size = TXT, base_family = FONTE) +
  theme(axis.line = element_line(linewidth = 0.3), axis.ticks = element_line(linewidth = 0.3),
        axis.text = element_text(size = 6.6, colour = "black"), axis.title = element_text(size = TXT, margin = margin(t = 3, r = 3)),
        plot.margin = margin(2, 4, 2, 2), legend.position = "none",
        plot.title = element_text(size = 7.2, family = FONTE, hjust = 0, margin = margin(b = 4)))

cinza <- function(entrada, saida) {
  im <- readPNG(entrada); L <- 0.299 * im[, , 1] + 0.587 * im[, , 2] + 0.114 * im[, , 3]
  writePNG(array(L, dim = c(dim(L), 1)), saida)
}
salva <- function(g, nome, h_cm) {
  ggsave(file.path(SAIDA, paste0(nome, ".pdf")), g, width = 12.2, height = h_cm, units = "cm", device = cairo_pdf)
  ggsave(file.path(SAIDA, paste0(nome, ".png")), g, width = 12.2, height = h_cm, units = "cm", dpi = 300, type = "cairo")
  cinza(file.path(SAIDA, paste0(nome, ".png")), file.path(SAIDA, paste0(nome, "_gray.png")))
}

# ------------------------------------------------------------------------------------------------ Figura 2
fig2 <- function() {
  d <- read.csv("fig2_data.csv"); b <- read.csv("fig2_baseline.csv")
  ordem <- d$filtro[order(d$kept_mean)]; d$y <- match(d$filtro, ordem)
  long <- do.call(rbind, lapply(seq_along(ARCH), function(j)
    data.frame(y = d$y, rede = j, v = d[[paste0("kept_", ARCH[j])]])))
  long$txt <- sprintf("%.0f", long$v); long$cor <- ifelse(long$v > 125, "white", "black")
  A0 <- b[match(ARCH, b$arch), ]
  base_row <- data.frame(y = 0, rede = 1:4, txt = sprintf("%.1f", A0$A_unfiltered_points))
  rotulos_y <- c(`0` = "Unfiltered (A, points)", setNames(LAB[ordem], as.character(seq_along(ordem))))
  a <- ggplot() +
    geom_tile(data = long, aes(rede, y, fill = v), colour = "white", linewidth = 0.6) +
    geom_text(data = long, aes(rede, y, label = txt, colour = cor), size = 6.8 * PT, family = FONTE) +
    geom_text(data = base_row, aes(rede, y, label = txt), size = 6.8 * PT, family = FONTE, fontface = "italic") +
    geom_hline(yintercept = 0.5, linewidth = 0.3, colour = "grey50") +
    scale_colour_identity() +
    scale_fill_distiller(palette = "Blues", direction = 1, limits = c(0, 230), oob = scales::squish, breaks = c(0, 100, 200)) +
    scale_x_continuous(breaks = 1:4, labels = HEAD, position = "top", expand = c(0, 0)) +
    scale_y_reverse(breaks = 0:17, labels = rotulos_y, limits = c(17.5, -0.5), expand = c(0, 0)) +
    guides(fill = guide_colourbar(direction = "horizontal", title = "Lesion reliance kept, % of the unfiltered model",
                                  title.position = "top", title.hjust = 0.5, ticks.colour = "black",
                                  barwidth = unit(4.2, "cm"), barheight = unit(0.28, "cm"))) +
    labs(x = NULL, y = NULL) + tema() +
    theme(axis.line = element_blank(), axis.ticks = element_blank(), axis.text.x.top = element_text(size = 6.6, lineheight = 0.95, margin = margin(b = 3)),
          axis.text.y = element_text(size = 6.8), legend.position = "bottom", legend.title = element_text(size = 6.8, family = FONTE),
          legend.text = element_text(size = 6.6, family = FONTE), legend.margin = margin(t = 2), legend.box.margin = margin(0, 0, 0, 0))
  auc0 <- b$auc_unfiltered[b$arch == "mean4"]
  dd <- rbind(data.frame(y = d$y, v = d$auc_mean4), data.frame(y = 0, v = auc0))
  dd$base <- dd$y == 0
  p <- ggplot(dd, aes(v, y)) +
    geom_hline(yintercept = 0:17, colour = "grey92", linewidth = 0.25) +
    geom_vline(xintercept = auc0, linetype = "dashed", colour = "grey35", linewidth = 0.35) +
    geom_point(aes(shape = base), size = 1.7, colour = "grey10", fill = "white", stroke = 0.5) +
    geom_text(aes(label = sprintf("%.2f", v)), x = 0.995, hjust = 1, size = 6.4 * PT, family = FONTE, colour = "grey20") +
    scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 23)) +
    scale_x_continuous(limits = c(0.55, 1.0), breaks = c(0.6, 0.7, 0.8, 0.9), expand = c(0, 0)) +
    scale_y_reverse(limits = c(17.5, -0.5), expand = c(0, 0)) +
    guides(shape = "none") + labs(x = "Mean AUC of the four networks", y = NULL) + tema() +
    theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.text.y = element_blank(),
          axis.title.x = element_text(size = TXT, margin = margin(t = 4)))
  g <- (a + p + plot_layout(widths = c(1.35, 1.0), guides = "collect")) & theme(legend.position = "bottom", legend.margin = margin(t = 0), legend.box.spacing = unit(0.1, "cm"))
  salva(g, "fig2_filters", 7.2)
}

# ------------------------------------------------------------------------------------------------ Figura 3
fig3 <- function() {
  pm <- read.csv("fig3_pipelines_v2s.csv"); pm <- pm[as.character(pm$deg) %in% c("False", "FALSE"), ]
  r <- read.csv("fig3_runs_destacados.csv"); cr <- read.csv("fig3_correlations.csv")
  r$grupo <- factor(match(r$condicao, unique(r$condicao)))
  cols <- c("#08306b", "#cc5500", "#2e7d32", "#7b1fa2", "#000000"); shp <- c(16, 15, 17, 18, 25)
  pa <- ggplot() +
    geom_point(data = pm, aes(AUC, A), size = 0.9, colour = "grey60", stroke = 0) +
    geom_path(data = r, aes(AUC, Apts, group = grupo, colour = grupo), linewidth = 0.45) +
    geom_point(data = r, aes(AUC, Apts, colour = grupo, shape = grupo, fill = grupo), size = 1.9, stroke = 0.2) +
    scale_colour_manual(values = cols) + scale_fill_manual(values = cols) + scale_shape_manual(values = shp) +
    # legenda em faixa livre acima dos dados (os dados chegam a 15,2)
    annotate("point", x = 0.7155, y = 20.2, size = 0.9, colour = "grey60") +
    annotate("text", x = 0.7265, y = 20.2, label = "pipeline mean", size = 6.6 * PT, hjust = 0, family = FONTE) +
    annotate("point", x = 0.7155, y = 18.2, size = 1.9, colour = "black", shape = 16) +
    annotate("text", x = 0.7265, y = 18.2, label = "3 runs of one pipeline (joined)", size = 6.6 * PT, hjust = 0, family = FONTE) +
    scale_x_continuous(breaks = c(0.75, 0.80, 0.85, 0.90)) + scale_y_continuous(breaks = c(0, 5, 10, 15)) +
    coord_cartesian(ylim = c(-3, 21.5), xlim = c(0.705, 0.925), expand = FALSE) +
    labs(x = "AUC", y = "Lesion reliance (probability points)", title = "(a) EfficientNetV2-S, one dot per pipeline") +
    tema() + theme(panel.grid.major = element_line(colour = "grey93", linewidth = 0.25))
  rd <- 1:4; bw <- 0.36
  bar <- rbind(data.frame(x = rd - 0.2, v = cr$between, tipo = "between"), data.frame(x = rd + 0.2, v = cr$within, tipo = "within"))
  hach <- do.call(rbind, lapply(which(bar$tipo == "within"), function(i) {
    x0 <- bar$x[i] - bw / 2; x1 <- bar$x[i] + bw / 2; h <- bar$v[i]
    do.call(rbind, lapply(seq(x0 - 0.3, x1, by = 0.07), function(a) {
      m <- 3.2; xa <- max(a, x0); xb <- min(a + h / m, x1)
      if (xb <= xa) return(NULL)
      data.frame(x = xa, xend = xb, y = (xa - a) * m, yend = (xb - a) * m)
    }))
  }))
  pb <- ggplot() +
    geom_col(data = bar[bar$tipo == "between", ], aes(x, v), width = bw, fill = "grey15", colour = "grey15", linewidth = 0.3) +
    geom_col(data = bar[bar$tipo == "within", ], aes(x, v), width = bw, fill = "white", colour = "grey15", linewidth = 0.3) +
    geom_segment(data = hach, aes(x = x, xend = xend, y = y, yend = yend), linewidth = 0.25, colour = "grey15") +
    geom_text(data = bar, aes(x, v + 0.07, label = sprintf("%.2f", v)), size = 6.6 * PT, family = FONTE) +
    annotate("rect", xmin = 0.55, xmax = 0.76, ymin = 1.30, ymax = 1.40, fill = "grey15") +
    annotate("text", x = 0.84, y = 1.35, label = "across pipelines (185)", size = 6.6 * PT, hjust = 0, family = FONTE) +
    annotate("rect", xmin = 0.55, xmax = 0.76, ymin = 1.12, ymax = 1.22, fill = "white", colour = "grey15", linewidth = 0.3) +
    annotate("segment", x = c(0.59, 0.66, 0.73), xend = c(0.62, 0.69, 0.76), y = 1.12, yend = c(1.22, 1.22, 1.15), linewidth = 0.25) +
    annotate("text", x = 0.84, y = 1.17, label = "across the 3 runs of a pipeline", size = 6.6 * PT, hjust = 0, family = FONTE) +
    scale_x_continuous(breaks = 1:4, labels = HEAD, expand = c(0.02, 0)) +
    scale_y_continuous(breaks = seq(0, 1, 0.2), expand = c(0, 0)) +
    coord_cartesian(ylim = c(0, 1.5)) +
    labs(x = NULL, y = "Rank correlation of AUC with reliance", title = "(b) Spearman correlation") +
    tema() + theme(axis.text.x = element_text(size = 6.6, lineheight = 0.95), panel.grid.major.y = element_line(colour = "grey93", linewidth = 0.25))
  salva(pa + pb + plot_layout(widths = c(1.2, 1.0)), "fig3_between_within", 6.0)
}

# ------------------------------------------------------------------------------------------------ Figura 4
fig4 <- function() {
  d <- read.csv("fig4_data.csv")
  nomes <- c("EfficientNetV2-S", "EfficientNetV2-B2", "InceptionV3", "ResNet-50")
  d$rede <- factor(nomes[match(d$arch, ARCH)], levels = rev(nomes))
  d$filtro <- factor(c(CLAHE4.0 = "CLAHE", GreenChannel = "Green channel", Grayscale = "Grayscale")[d$filter],
                     levels = c("CLAHE", "Green channel", "Grayscale"))
  d$apta <- ifelse(d$meets_threshold, "AUC \u2265 0.70 in DDR", "AUC < 0.70 in DDR")
  g <- ggplot(d, aes(y = rede)) +
    geom_vline(xintercept = 100, linetype = "dashed", colour = "grey40", linewidth = 0.35) +
    geom_linerange(aes(xmin = ci_low, xmax = ci_high), orientation = "y", linewidth = 0.45, position = position_nudge(y = 0.14)) +
    geom_point(aes(x = kept_ddr, shape = apta), size = 2.2, stroke = 0.6, position = position_nudge(y = 0.14), fill = "white") +
    geom_point(aes(x = kept_fgadr, shape = "FGADR (same models)"), size = 2.2, stroke = 0.6, colour = "grey35", position = position_nudge(y = -0.18)) +
    scale_shape_manual(values = c(`AUC ≥ 0.70 in DDR` = 16, `AUC < 0.70 in DDR` = 21, `FGADR (same models)` = 4)) +
    scale_x_continuous(breaks = c(0, 100, 200)) +
    facet_wrap(~filtro, nrow = 1) + coord_cartesian(xlim = c(0, 250)) +
    labs(x = "Lesion reliance kept, % of the unfiltered model", y = NULL) +
    tema() + theme(legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 6.6),
                   legend.key.size = unit(0.35, "cm"), strip.background = element_blank(), strip.text = element_text(size = 7.2, family = FONTE),
                   axis.text.y = element_text(size = 6.8), legend.margin = margin(t = 0), legend.box.margin = margin(-2, 0, 0, 0),
                   panel.grid.major.x = element_line(colour = "grey93", linewidth = 0.25), panel.spacing = unit(0.5, "cm"))
  salva(g, "fig4_ddr", 5.0)
}

# ------------------------------------------------------------------------------------------------ Figura 1
pega <- function(f, k) {
  x <- paste(readLines(f, warn = FALSE), collapse = " ")
  as.numeric(sub(paste0('.*"', k, '": *(-?[0-9.eE+-]+).*'), "\\1", regmatches(x, regexpr(paste0('"', k, '": *-?[0-9.eE+-]+'), x))))
}
fig1 <- function() {
  info <- sapply(c("p_original", "p_lesoes_borradas", "p_controle_borrado", "A_da_imagem"), function(k) pega("fig1_info.json", k))
  amed <- pega("fig1_info.json", "A_medio_das_524_imagens_deste_modelo")
  P <- function(n) readPNG(file.path("fig1_panels", paste0(n, ".png")))
  Ht <- 8.55                                           # altura total (cm)
  avisos <- character()
  desenha <- function() {
    grid.newpage()
    cm <- function(x) unit(x, "cm")
    Y <- function(t) cm(Ht - t)                       # t = distância do topo (cm)
    larg <- function(s, size, face) convertWidth(grobWidth(textGrob(s, gp = gpar(fontsize = size, fontfamily = FONTE, fontface = face))), "cm", valueOnly = TRUE)
    txt <- function(s, x, t, size = 6.5, just = "center", col = "black", face = "plain", maxw = NA) {
      if (!is.na(maxw)) {                             # cabe na caixa? reduz até 6,0 pt e avisa se ainda não couber
        l <- max(sapply(strsplit(s, "\n")[[1]], larg, size = size, face = face))
        while (l > maxw && size > 6.0) { size <- size - 0.1; l <- max(sapply(strsplit(s, "\n")[[1]], larg, size = size, face = face)) }
        if (l > maxw) avisos <<- c(avisos, sprintf("'%s' (%.2f cm) > caixa %.2f cm", gsub("\n", " / ", s), l, maxw))
      }
      grid.text(s, x = cm(x), y = Y(t), just = just, gp = gpar(fontsize = size, fontfamily = FONTE, col = col, fontface = face, lineheight = 0.95))
    }
    img <- function(n, x, t, w) grid.raster(P(n), x = cm(x), y = Y(t), width = cm(w), height = cm(w), just = c("left", "top"), interpolate = TRUE)
    # ---- faixa superior: método (A-E). 5 x 2,1 cm + 4 x 0,2 cm = 11,3 cm (< 12,2 cm)
    s <- 2.1; g <- 0.2; x0 <- 0.1; t0 <- 0.42
    nom <- c("A_exame", "B_lesoes", "C_gradcam", "D_lesoes_borradas", "E_controle_borrado")
    rot <- c("Exam", "Lesion mask", "Grad-CAM", "Lesions blurred", "Control blurred")
    for (k in 1:5) {
      x <- x0 + (k - 1) * (s + g)
      txt(LETTERS[k], x, 0.20, 7.2, "left", "black", "bold")
      txt(rot[k], x + 0.28, 0.20, 6.5, "left", maxw = s - 0.28)
      img(nom[k], x, t0, s)
    }
    caixa <- function(k, p) {                          # p = 0.xxx dentro do painel, em caixa escura
      x <- x0 + (k - 1) * (s + g)
      grid.rect(x = cm(x + s / 2), y = Y(t0 + s - 0.17), width = cm(1.25), height = cm(0.27), gp = gpar(fill = "black", col = NA, alpha = 0.7))
      txt(sprintf("p = %.3f", p), x + s / 2, t0 + s - 0.17, 6.6, col = "white")
    }
    caixa(4, info["p_lesoes_borradas"]); caixa(5, info["p_controle_borrado"])
    xD <- x0 + 3 * (s + g); xE2 <- x0 + 4 * (s + g) + s; yb <- t0 + s + 0.12
    grid.lines(x = cm(c(xD, xD, xE2, xE2)), y = Y(c(yb, yb + 0.07, yb + 0.07, yb)), gp = gpar(lwd = 0.6))
    txt(sprintf("A = p(E) \u2212 p(D) = %.1f points", 100 * info["A_da_imagem"]), (xD + xE2) / 2, yb + 0.30, 6.6, "center", maxw = xE2 - xD)
    ml <- xD - x0 - 0.3                                  # largura da caixa de texto à esquerda
    txt(sprintf("This exam: original p = %.3f", info["p_original"]), x0, yb + 0.26, 6.4, "left", "grey15", maxw = ml)
    txt(sprintf("Mean A over the 524 test exams: %.1f points", 100 * amed), x0, yb + 0.48, 6.4, "left", "grey15", maxw = ml)
    txt("Control: same lesion shapes moved to a lesion-free area", x0, yb + 0.70, 6.4, "left", "grey15", maxw = ml)
    # ---- separador e título da galeria
    grid.lines(x = cm(c(0.1, 12.1)), y = Y(c(3.64, 3.64)), gp = gpar(lwd = 0.4, col = "grey60"))
    txt("Preprocessing filters applied to exam A (299 \u00d7 299 px, as seen by the network)", 0.10, 3.88, 6.8, "left", "black", "bold", maxw = 12.0)
    # ---- galeria: 2 linhas x 9 miniaturas (1,10 cm), passo 1,355 cm
    t <- 1.10; passo <- 1.355; xs <- function(c) 0.10 + (c - 1) * passo
    linhas <- list(
      list(filt = c("Unfiltered", "BenGraham", "Gamma0.8", "Retinex", "HistogramEq", "LABNorm", "GreenChannel", "MaxGreen2.0", "Grayscale"),
           lab = c("Unfiltered", "Ben\nGraham", "Gamma", "Retinex", "Histogram\neq.", "LAB\nnorm.", "Green\nchannel", "MaxGreen", "Grayscale"),
           br = list(list(2, 6, "Stage 1: Illumination"), list(7, 9, "Stage 2: Color"))),
      list(filt = c("AHE40.0", "CLAHE4.0", "Unsharp1.5", "Median", "Gaussian", "Morpho", "Frangi", "Canny", "Otsu"),
           lab = c("AHE", "CLAHE", "Unsharp\nmask", "Median", "Gaussian", "Opening", "Frangi", "Canny", "Otsu"),
           br = list(list(1, 2, "Stage 3:\nLocal contrast"), list(3, 9, "Stage 4: Refinement"))))
    yl <- c(4.36, 6.68)                                  # linha do colchete de cada fileira (distância do topo)
    for (r in 1:2) {
      L <- linhas[[r]]; ty <- yl[r] + 0.09                # topo das miniaturas
      for (c in 1:9) {
        img(paste0("filtro_", L$filt[c]), xs(c), ty, t)
        txt(L$lab[c], xs(c) + t / 2, ty + t + 0.05, 6.3, c("center", "top"), maxw = passo - 0.04)
      }
      for (b in L$br) {
        x1 <- xs(b[[1]]) + 0.03; x2 <- xs(b[[2]]) + t - 0.03
        grid.lines(x = cm(c(x1, x1, x2, x2)), y = Y(c(yl[r] + 0.07, yl[r], yl[r], yl[r] + 0.07)), gp = gpar(lwd = 0.6))
        txt(b[[3]], (x1 + x2) / 2, yl[r] - 0.05, 6.5, c("center", "bottom"), maxw = x2 - x1)
      }
    }
  }
  Ht <- 8.55
  png(file.path(SAIDA, "fig1_overview.png"), width = 12.2, height = Ht, units = "cm", res = 300, type = "cairo", family = FONTE)
  desenha(); dev.off()
  cairo_pdf(file.path(SAIDA, "fig1_overview.pdf"), width = W, height = Ht / 2.54, family = FONTE); desenha(); dev.off()
  cinza(file.path(SAIDA, "fig1_overview.png"), file.path(SAIDA, "fig1_overview_gray.png"))
  if (length(avisos)) cat("AVISOS de texto (não cabe na caixa):\n", paste(unique(avisos), collapse = "\n"), "\n") else cat("Figura 1: todo o texto cabe nas caixas.\n")
}

args <- commandArgs(trailingOnly = TRUE)
alvo <- if (length(args)) args else c("2", "3", "4", "1")
if ("2" %in% alvo) fig2()
if ("3" %in% alvo) fig3()
if ("4" %in% alvo && file.exists("fig4_data.csv")) fig4()
if ("1" %in% alvo && file.exists("fig1_info.json")) fig1()
cat("feito\n")
