# Figuras do prompt v3 (ESANN 2027): várias versões de cada figura, para o usuário escolher à mão.
# Uso (na pasta esann_materiais/):  Rscript make_figuras_v3.R [números das figuras]
# Entradas: dados/*.csv e paineis/ (make_dados_v3.py, make_ddr_v3.py, make_paineis_v3.py). Saídas: figuras/figN_vX_hY.Ycm.{pdf,png,_gray.png}
# e figuras/contact_figN.png. Cada versão roda dentro de tryCatch (um erro não derruba as outras; vai para figuras/erros.txt).
.libPaths(c("~/Rlibs", .libPaths()))
suppressMessages({library(ggplot2); library(patchwork); library(png); library(grid)})
W <- 12.2 / 2.54; FONTE <- "LM Fig"; PT <- 25.4 / 72.27
FIG <- "figuras"; dir.create(FIG, showWarnings = FALSE)
ARCH <- c("efficientnetv2s", "efficientnetv2b2", "inceptionv3", "resnet50")
NOME <- c("EfficientNetV2-S", "EfficientNetV2-B2", "InceptionV3", "ResNet-50")
HEAD <- c("EffNetV2\nS", "EffNetV2\nB2", "Inception\nV3", "ResNet\n50")
LAB <- c(`AHE40.0` = "AHE", `CLAHE4.0` = "CLAHE", `MaxGreen2.0` = "MaxGreen", `Unsharp1.5` = "Unsharp mask", `Gamma0.8` = "Gamma",
         GreenChannel = "Green channel", HistogramEq = "Histogram eq.", BenGraham = "Ben Graham", LABNorm = "LAB normaliz.",
         Morpho = "Opening", Median = "Median", Retinex = "Retinex", Gaussian = "Gaussian", Grayscale = "Grayscale", Frangi = "Frangi",
         Canny = "Canny", Otsu = "Otsu")
LOG <- character(); AVISOS <- character()
rd <- function(f) read.csv(file.path("dados", f), check.names = FALSE)
EX <- rd("exames_escolhidos.csv"); PRINC <- EX$imagem[1]
exd <- function(e) file.path("paineis", sub(".png", "", e))
pnl <- function(e, n) readPNG(file.path(exd(e), paste0(n, ".png")))
exi <- function(e) EX[EX$imagem == e, ]

tema <- function() theme_classic(base_size = 6.8, base_family = FONTE) +
  theme(axis.line = element_line(linewidth = 0.3), axis.ticks = element_line(linewidth = 0.3),
        axis.text = element_text(size = 6.4, colour = "black"), axis.title = element_text(size = 6.8, margin = margin(t = 2, r = 2)),
        plot.margin = margin(2, 4, 2, 2), legend.position = "none", plot.title = element_text(size = 7, hjust = 0, margin = margin(b = 3)),
        strip.background = element_blank(), strip.text = element_text(size = 6.8, family = FONTE))
cinza <- function(entrada, saida) {
  im <- readPNG(entrada); L <- 0.299 * im[, , 1] + 0.587 * im[, , 2] + 0.114 * im[, , 3]
  writePNG(array(L, dim = c(dim(L), 1)), saida)
}
nome_arq <- function(fig, v, h) sprintf("fig%d_v%s_h%.1fcm", fig, v, h)
versao <- function(fig, v, h, expr) {                  # roda uma versão sem derrubar as outras
  r <- tryCatch({ force(expr); "ok" }, error = function(e) paste("ERRO:", conditionMessage(e)))
  LOG <<- c(LOG, sprintf("fig%d versão %s (h %.1f cm): %s", fig, v, h, r)); cat(tail(LOG, 1), "\n")
}
sg <- function(g, fig, v, h) {                          # ggplot -> pdf/png/gray
  n <- file.path(FIG, nome_arq(fig, v, h))
  ggsave(paste0(n, ".pdf"), g, width = 12.2, height = h, units = "cm", device = cairo_pdf)
  ggsave(paste0(n, ".png"), g, width = 12.2, height = h, units = "cm", dpi = 300, type = "cairo")
  cinza(paste0(n, ".png"), paste0(n, "_gray.png"))
}
HT <- 3
sgrid <- function(fig, v, h, fun) {                     # figura desenhada com grid (altura em cm)
  n <- file.path(FIG, nome_arq(fig, v, h)); HT <<- h
  cairo_pdf(paste0(n, ".pdf"), width = W, height = h / 2.54, family = FONTE); fun(); dev.off()
  png(paste0(n, ".png"), width = 12.2, height = h, units = "cm", res = 300, type = "cairo", family = FONTE); fun(); dev.off()
  cinza(paste0(n, ".png"), paste0(n, "_gray.png"))
}
# ---- primitivas de grid (coordenadas em cm; t = distância do topo)
cm <- function(x) unit(x, "cm"); Y <- function(t) cm(HT - t)
larg <- function(s, size, face = "plain") convertWidth(grobWidth(textGrob(s, gp = gpar(fontsize = size, fontfamily = FONTE, fontface = face))), "cm", valueOnly = TRUE)
txt <- function(s, x, t, size = 6.5, just = "center", col = "black", face = "plain", maxw = NA, minsize = 6.0, vj = "center") {
  if (!is.na(maxw)) {
    l <- max(sapply(strsplit(s, "\n")[[1]], larg, size = size, face = face))
    while (l > maxw && size > minsize) { size <- size - 0.1; l <- max(sapply(strsplit(s, "\n")[[1]], larg, size = size, face = face)) }
    if (l > maxw) AVISOS <<- c(AVISOS, sprintf("fig (altura %.1f): '%s' %.2f cm > %.2f cm", HT, gsub("\n", " / ", s), l, maxw))
  }
  grid.text(s, x = cm(x), y = Y(t), just = c(just, vj), gp = gpar(fontsize = size, fontfamily = FONTE, col = col, fontface = face, lineheight = 0.95))
}
img <- function(m, x, t, w, h = w) grid.raster(m, x = cm(x), y = Y(t), width = cm(w), height = cm(h), just = c("left", "top"), interpolate = TRUE)
pbox <- function(s, x, t, w = 0.85, size = 6.3) {       # rótulo de probabilidade sobre a imagem (caixa escura)
  grid.rect(x = cm(x), y = Y(t), width = cm(w), height = cm(0.25), gp = gpar(fill = "black", col = NA, alpha = 0.72))
  txt(s, x, t, size, col = "white")
}
seta <- function(x1, t1, x2, t2, lwd = 0.8) grid.lines(x = cm(c(x1, x2)), y = Y(c(t1, t2)), arrow = arrow(length = unit(0.12, "cm"), type = "closed"), gp = gpar(lwd = lwd, fill = "black"))
caixa <- function(x, t, w, h, fill = "white", col = "black", lwd = 0.7, lty = 1) grid.rect(x = cm(x), y = Y(t), width = cm(w), height = cm(h), just = c("left", "top"), gp = gpar(fill = fill, col = col, lwd = lwd, lty = lty))
colchete <- function(x1, x2, t, baixo = TRUE) grid.lines(x = cm(c(x1, x1, x2, x2)), y = Y(t + c(if (baixo) -0.07 else 0.07, 0, 0, if (baixo) -0.07 else 0.07)), gp = gpar(lwd = 0.6))
fmt <- function(p) sprintf("%.3f", p)

# ================================================================================================ FIGURA 1
fig1 <- function() {
  e <- PRINC; i <- exi(e); A <- i$A_da_imagem_pontos
  ab <- rd("ablation_per_image.csv"); abv <- ab[ab$arch == "efficientnetv2s", ]
  med <- aggregate(cbind(p_orig, p_les, p_ctrl) ~ image_id, abv, mean)
  Amed <- mean(med$p_ctrl - med$p_les) * 100
  # ---------------- 1A: faixa de 5 painéis
  versao(1, "A", 2.6, sgrid(1, "A", 2.6, function() {
    grid.newpage(); s <- 2.0; g <- 0.25; x0 <- 0.1; t0 <- 0.45
    nm <- c("A_exame", "B_mascara", "C_gradcam_contorno", "D_lesoes_borradas", "E_controle_borrado")
    rot <- c("Exam", "Lesion mask", "Grad-CAM", "Lesions blurred", "Control blurred")
    for (k in 1:5) { x <- x0 + (k - 1) * (s + g); txt(LETTERS[k], x, 0.2, 7, "left", face = "bold"); txt(rot[k], x + 0.27, 0.2, 6.4, "left", maxw = s - 0.27)
                     img(pnl(e, nm[k]), x, t0, s) }
    pbox(fmt(i$p_lesoes_borradas), x0 + 3 * (s + g) + s / 2, t0 + s - 0.17, 1.2, 6.5); pbox(fmt(i$p_controle_borrado), x0 + 4 * (s + g) + s / 2, t0 + s - 0.17, 1.2, 6.5)
  }))
  # ---------------- 1B: faixa de 4 + distribuição pareada
  versao(1, "B", 3.8, sgrid(1, "B", 3.8, function() {
    grid.newpage(); s <- 1.62; g <- 0.12; x0 <- 0.1; t0 <- 0.62
    nm <- c("A_exame_contorno", "C_gradcam", "D_lesoes_borradas", "E_controle_borrado")
    rot <- c("Exam +\nlesions", "Grad-CAM", "Lesions\nblurred", "Control\nblurred")
    for (k in 1:4) { x <- x0 + (k - 1) * (s + g); txt(rot[k], x + s / 2, 0.30, 6.4, maxw = s); img(pnl(e, nm[k]), x, t0, s) }
    pbox(fmt(i$p_lesoes_borradas), x0 + 2 * (s + g) + s / 2, t0 + s - 0.17, 1.0); pbox(fmt(i$p_controle_borrado), x0 + 3 * (s + g) + s / 2, t0 + s - 0.17, 1.0)
    txt(sprintf("This exam: original p = %s; A = %.1f points", fmt(i$p_original), A), x0, t0 + s + 0.3, 6.4, "left", maxw = 4 * s + 3 * g)
    txt(sprintf("Mean A, %d test exams (campaign runs): %.1f points", nrow(med), Amed), x0, t0 + s + 0.52, 6.4, "left", "grey20", maxw = 4 * s + 3 * g)
    txt("The probability drops when the lesions are blurred,", x0, t0 + s + 0.92, 6.4, "left", "grey20", maxw = 4 * s + 3 * g)
    txt("and not when a lesion-free control is blurred.", x0, t0 + s + 1.14, 6.4, "left", "grey20", maxw = 4 * s + 3 * g)
    L <- rbind(data.frame(id = med$image_id, k = 1, p = med$p_orig), data.frame(id = med$image_id, k = 2, p = med$p_les), data.frame(id = med$image_id, k = 3, p = med$p_ctrl))
    mm <- aggregate(p ~ k, L, median)
    gp <- ggplot(L, aes(k, p)) + geom_line(aes(group = id), linewidth = 0.12, alpha = 0.10, colour = "grey30") +
      geom_line(data = mm, linewidth = 0.8, colour = "black") + geom_point(data = mm, size = 1.8, shape = 21, fill = "white", stroke = 0.7) +
      geom_text(data = mm, aes(label = sprintf("%.2f", p)), nudge_x = 0.27, size = 6.4 * PT, family = FONTE) +
      scale_x_continuous(breaks = 1:3, labels = c("original", "lesions\nblurred", "control\nblurred"), limits = c(0.7, 3.5)) +
      labs(x = NULL, y = "p(referable DR)") + tema()
    print(gp, vp = viewport(x = cm(7.45), y = cm(0.05), width = cm(4.7), height = cm(3.7), just = c("left", "bottom")))
  }))
  # ---------------- 1C: fluxograma
  versao(1, "C", 4.5, sgrid(1, "C", 4.5, function() {
    grid.newpage(); s <- 1.25
    for (r in 1:2) {
      t <- c(0.45, 2.15)[r]; tm <- t + s / 2
      img(pnl(e, "A_exame"), 0.1, t, s)
      seta(1.4, tm, 2.5, tm); txt(c("blur the\nlesions", "blur the\ncontrol")[r], 1.95, tm + 0.14, 6.3, maxw = 1.15, vj = "top")
      img(pnl(e, c("D_lesoes_borradas", "E_controle_borrado")[r]), 2.55, t, s)
      seta(3.9, tm, 4.65, tm); caixa(4.7, t + 0.2, 1.0, s - 0.4, "grey92"); txt("CNN", 5.2, tm, 7, face = "bold")
      seta(5.75, tm, 6.5, tm); txt(sprintf("%s = %s", c("p_les", "p_ctrl")[r], fmt(c(i$p_lesoes_borradas, i$p_controle_borrado)[r])), 6.55, tm, 6.8, "left", maxw = 1.9)
    }
    txt(sprintf("original p = %s", fmt(i$p_original)), 0.1, 3.7, 6.4, "left", "grey20", maxw = 4)
    txt("A = mean over the test exams of ( p_ctrl − p_les )", 6.1, 4.1, 7.2, face = "bold", maxw = 11.8)
    txt("where the map points", 10.6, 0.22, 6.5, maxw = 3.0); img(pnl(e, "C_gradcam_contorno"), 9.45, 0.38, 2.3 * 1.0)
    txt("(white outlines = lesions)", 10.6, 2.9, 6.3, "center", "grey20", maxw = 3.0)
    txt(sprintf("this exam: A = %.1f points", A), 6.55, 3.4, 6.5, "left", "grey20", maxw = 3)
  }))
  # ---------------- 1D: duas linhas + mini barras
  versao(1, "D", 5.0, sgrid(1, "D", 5.0, function() {
    grid.newpage(); s <- 2.0
    txt("Exam, lesions outlined", 0.1 + s / 2, 0.2, 6.4, maxw = s + 0.4); img(pnl(e, "A_exame_contorno"), 0.1, 0.38, s)
    txt("Grad-CAM + outlines", 2.5 + s / 2, 0.2, 6.4, maxw = s + 0.4); img(pnl(e, "C_gradcam_contorno"), 2.5, 0.38, s)
    txt("Where the map points", 5.0, 0.55, 6.6, "left", face = "bold"); txt("compared with where the lesions are.", 5.0, 0.8, 6.4, "left", "grey20", maxw = 7)
    txt("Row below: blur only the lesions, or the same shapes", 5.0, 1.25, 6.4, "left", "grey20", maxw = 7)
    txt("moved to a lesion-free area (control), and re-predict.", 5.0, 1.48, 6.4, "left", "grey20", maxw = 7)
    txt("Lesions blurred", 0.1 + s / 2, 2.62, 6.4, maxw = s + 0.4); img(pnl(e, "D_lesoes_borradas"), 0.1, 2.78, s)
    txt("Control blurred", 2.5 + s / 2, 2.62, 6.4, maxw = s + 0.4); img(pnl(e, "E_controle_borrado"), 2.5, 2.78, s)
    pbox(fmt(i$p_lesoes_borradas), 0.1 + s / 2, 2.78 + s - 0.17, 1.2); pbox(fmt(i$p_controle_borrado), 2.5 + s / 2, 2.78 + s - 0.17, 1.2)
    d <- data.frame(k = factor(c("original", "lesions\nblurred", "control\nblurred"), levels = c("original", "lesions\nblurred", "control\nblurred")),
                    p = c(i$p_original, i$p_lesoes_borradas, i$p_controle_borrado))
    gp <- ggplot(d, aes(k, p)) + geom_col(fill = c("grey70", "grey15", "white"), colour = "grey15", linewidth = 0.4, width = 0.6) +
      geom_text(aes(label = sprintf("%.3f", p)), vjust = -0.4, size = 6.4 * PT, family = FONTE) +
      annotate("text", x = 2.5, y = 1.12, label = sprintf("A = %.1f points", A), size = 6.6 * PT, family = FONTE, fontface = "bold") +
      scale_y_continuous(limits = c(0, 1.2), breaks = c(0, 0.5, 1)) + labs(x = NULL, y = "p(referable DR)") + tema()
    print(gp, vp = viewport(x = cm(5.0), y = cm(0.1), width = cm(7.1), height = cm(2.55), just = c("left", "bottom")))
  }))
  # ---------------- 1E: grade de exames
  versao(1, "E", 4.6, sgrid(1, "E", 4.6, function() {
    grid.newpage(); s <- 0.92; xs <- c(2.35, 3.4, 4.45); rot <- c("original", "lesions blurred", "control blurred")
    for (k in 1:3) txt(gsub(" ", "\n", rot[k]), xs[k] + s / 2, 0.3, 6.3, maxw = s + 0.12, vj = "center")
    txt("p shown on each image", 6.0, 0.3, 6.3, "left", "grey20")
    for (r in seq_len(nrow(EX))) {
      ex <- EX$imagem[r]; ii <- EX[r, ]; t <- 0.68 + (r - 1) * 0.98
      txt(sprintf("grade %d\n%d regions", ii$grau, ii$n_regioes), 0.1, t + s / 2, 6.3, "left", maxw = 2.1)
      for (k in 1:3) { img(pnl(ex, c("A_exame", "D_lesoes_borradas", "E_controle_borrado")[k]), xs[k], t, s)
                       pbox(sprintf("%.2f", c(ii$p_original, ii$p_lesoes_borradas, ii$p_controle_borrado)[k]), xs[k] + s / 2, t + s - 0.15, 0.62, 6.3) }
      a <- ii$A_da_imagem_pontos; w <- max(0.03, abs(a) / 40 * 5.0)
      grid.rect(x = cm(6.0), y = Y(t + s / 2), width = cm(w), height = cm(0.32), just = c("left", "center"), gp = gpar(fill = if (a >= 0) "grey25" else "white", col = "grey25", lwd = 0.5))
      txt(sprintf("A = %.1f", a), 6.0 + w + 0.1, t + s / 2, 6.5, "left")
    }
  }))
}

# ================================================================================================ FIGURA 2
thumbs <- function() {
  e <- PRINC; d <- exd(e); f <- function(n) readPNG(file.path(d, paste0("filtro_", n, ".png")))
  list(f = f, e = e)
}
GAL <- list(
  list(filt = c("Unfiltered", "BenGraham", "Gamma0.8", "Retinex", "HistogramEq", "LABNorm", "GreenChannel", "MaxGreen2.0", "Grayscale"),
       lab = c("Unfiltered", "Ben Graham", "Gamma", "Retinex", "Histogram eq.", "LAB norm.", "Green channel", "MaxGreen", "Grayscale"),
       br = list(list(2, 6, "Stage 1: Illumination"), list(7, 9, "Stage 2: Color"))),
  list(filt = c("AHE40.0", "CLAHE4.0", "Unsharp1.5", "Median", "Gaussian", "Morpho", "Frangi", "Canny", "Otsu"),
       lab = c("AHE", "CLAHE", "Unsharp mask", "Median", "Gaussian", "Opening", "Frangi", "Canny", "Otsu"),
       br = list(list(1, 2, "Stage 3: Local contrast"), list(3, 9, "Stage 4: Refinement"))))
galeria <- function(f, t_top, t = 1.0, passo = 1.355, lab_min = 5.5, size_lab = 6.0, row_pitch = 1.5) {
  xs <- function(c) 0.1 + (c - 1) * passo
  for (r in 1:2) {
    L <- GAL[[r]]; yl <- t_top + (r - 1) * row_pitch + 0.25; ty <- yl + 0.07
    for (c in 1:9) { img(f(L$filt[c]), xs(c), ty, t); txt(L$lab[c], xs(c) + t / 2, ty + t + 0.04, size_lab, maxw = passo - 0.02, minsize = lab_min, vj = "top") }
    for (b in L$br) { x1 <- xs(b[[1]]) + 0.03; x2 <- xs(b[[2]]) + t - 0.03; colchete(x1, x2, yl); txt(b[[3]], (x1 + x2) / 2, yl - 0.05, 6.3, maxw = x2 - x1, minsize = 5.5, vj = "bottom") }
  }
}
fig2 <- function() {
  th <- thumbs(); f <- th$f
  versao(2, "A", 3.2, sgrid(2, "A", 3.2, function() { grid.newpage(); galeria(f, 0.0, t = 0.9, row_pitch = 1.53) }))
  # ---- 2B: fluxo por estágio
  versao(2, "B", 5.0, sgrid(2, "B", 5.0, function() {
    grid.newpage()
    st <- list(list("1  Illumination", "5 options", c("BenGraham", "Gamma0.8", "Retinex", "HistogramEq", "LABNorm"), c("Ben Graham", "Gamma", "Retinex", "Histogram eq.", "LAB norm.")),
               list("2  Color", "3 options", c("GreenChannel", "MaxGreen2.0", "Grayscale"), c("Green channel", "MaxGreen", "Grayscale")),
               list("3  Local contrast", "2 options", c("AHE40.0", "CLAHE4.0"), c("AHE", "CLAHE")),
               list("4  Refinement", "7 options", c("Unsharp1.5", "Median", "Gaussian", "Morpho", "Frangi", "Canny", "Otsu"), c("Unsharp mask", "Median", "Gaussian", "Opening", "Frangi", "Canny", "Otsu")))
    cw <- 2.62; x0 <- 0.1
    for (k in 1:4) {
      x <- x0 + (k - 1) * (cw + 0.28); S <- st[[k]]
      txt(S[[1]], x + cw / 2, 0.22, 6.6, face = "bold", maxw = cw); txt(paste0(S[[2]], " (or omit)"), x + cw / 2, 0.47, 6.3, col = "grey20", maxw = cw)
      for (j in seq_along(S[[3]])) { t <- 0.72 + (j - 1) * 0.54; img(f(S[[3]][j]), x, t, 0.48); txt(S[[4]][j], x + 0.56, t + 0.24, 6.3, "left", maxw = cw - 0.6) }
      if (k < 4) seta(x + cw + 0.02, 2.2, x + cw + 0.26, 2.2, 1.0)
    }
    txt("(5+1) × (3+1) × (2+1) × (7+1) = 576 pipelines", 6.1, 4.82, 7, face = "bold", maxw = 11.8)
  }))
  # ---- 2C: galeria + cadeias
  versao(2, "C", 5.2, sgrid(2, "C", 5.2, function() {
    grid.newpage(); galeria(f, 0.0, t = 0.7, passo = 1.355, size_lab = 6.0, lab_min = 5.5, row_pitch = 1.22)
    ch <- rd("chains_exemplares.csv"); pick <- ch[c(1, 4, nrow(ch)), ]
    curto <- c(LAB, LABNorm = "LAB norm.", HistogramEq = "Histogram eq.")
    txt("Example chains, same exam (filter named on each arrow)", 0.1, 2.62, 6.6, "left", face = "bold"); txt("mean, 4 networks", 9.6, 2.62, 6.3, "left", "grey20")
    for (r in seq_len(nrow(pick))) {
      cid <- pick$condicao_id[r]; partes <- strsplit(cid, "_")[[1]]; t <- 2.85 + (r - 1) * 0.78
      img(readPNG("paineis/cadeias/exame_original.png"), 0.1, t, 0.62); x <- 0.72
      for (j in seq_along(partes)) {
        seta(x + 0.05, t + 0.31, x + 1.2, t + 0.31); txt(curto[[partes[j]]], x + 0.62, t + 0.24, 6.0, maxw = 1.12, minsize = 5.5, vj = "bottom")
        img(readPNG(file.path("paineis/cadeias", sprintf("%s__passo%d.png", cid, j))), x + 1.25, t, 0.62); x <- x + 1.87
      }
      txt(sprintf("AUC %.3f   A %.1f pts", pick$AUC_mean4[r], pick$A_points_mean4[r]), 9.6, t + 0.31, 6.4, "left", maxw = 2.5)
    }
  }))
  # ---- 2D: funil
  versao(2, "D", 2.5, sgrid(2, "D", 2.5, function() {
    grid.newpage(); bw <- c(3.4, 4.5, 3.3); xs <- c(0.1, 4.2, 9.05)
    tx <- list("576 pipelines\n(grid: 4 stages)", "185 trained\n18 = unfiltered + 17 single filters\n150 D-optimal · 20 random (3 overlaps)", "4 networks × 3 runs\n= 2,220 models")
    for (k in 1:3) { caixa(xs[k], 0.35, bw[k], 1.7, c("grey95", "grey90", "grey85")[k]); txt(tx[[k]], xs[k] + bw[k] / 2, 1.2, 6.5, maxw = bw[k] - 0.15) }
    seta(xs[1] + bw[1] + 0.03, 1.2, xs[2] - 0.03, 1.2, 1.0); seta(xs[2] + bw[2] + 0.03, 1.2, xs[3] - 0.03, 1.2, 1.0)
  }))
}

# ================================================================================================ FIGURA 3
fig3 <- function() {
  nt <- rd("networks.csv"); nt$nome <- NOME[match(nt$arch, ARCH)]
  versao(3, "A", 2.5, sgrid(3, "A", 2.5, function() {
    grid.newpage(); xc <- c(0.1, 2.5, 3.9, 7.0, 10.6); h <- c("Network", "Family", "Backbone params (M)", "AUC unfiltered (mean ± SD)", "A unfiltered")
    for (k in 1:5) txt(h[k], xc[k], 0.25, 6.4, "left", face = "bold", maxw = c(2.3, 1.3, 3.0, 3.5, 1.6)[k], minsize = 6.0)
    for (r in 1:4) {
      t <- 0.65 + (r - 1) * 0.42; x <- nt[r, ]
      txt(x$nome, xc[1], t, 6.6, "left", maxw = 2.35, minsize = 6.0); txt(x$family, xc[2], t, 6.5, "left", maxw = 1.35, minsize = 6.0)
      w <- x$params_millions_backbone / 25 * 2.3; grid.rect(x = cm(xc[3]), y = Y(t), width = cm(w), height = cm(0.26), just = c("left", "center"), gp = gpar(fill = "grey30", col = NA))
      txt(sprintf("%.1f", x$params_millions_backbone), xc[3] + w + 0.08, t, 6.4, "left")
      px <- 7.0 + (x$auc_unfiltered_mean - 0.89) / 0.04 * 1.5; sd <- x$auc_unfiltered_sd / 0.04 * 1.5
      grid.lines(x = cm(c(px - sd, px + sd)), y = Y(c(t, t)), gp = gpar(lwd = 0.8)); grid.points(x = cm(px), y = Y(t), pch = 16, size = unit(3, "pt"))
      txt(sprintf("%.3f ± %.3f", x$auc_unfiltered_mean, x$auc_unfiltered_sd), 8.9, t, 6.3, "left", maxw = 1.7, minsize = 6.0)
      txt(sprintf("%.1f pts", x$A_unfiltered_points), xc[5], t, 6.5, "left", maxw = 1.5)
    }
  }))
  g <- ggplot(nt, aes(params_millions_backbone, auc_unfiltered_mean)) +
    geom_errorbar(aes(ymin = auc_unfiltered_mean - auc_unfiltered_sd, ymax = auc_unfiltered_mean + auc_unfiltered_sd), width = 0, linewidth = 0.4) +
    geom_point(size = 2.4) + geom_text(data = transform(nt, lx = params_millions_backbone * c(1, 1, 0.94, 1.06), ly = auc_unfiltered_mean + c(0.0045, 0.0045, -0.0045, 0.0015)),
              aes(lx, ly, label = nome), hjust = c(0.5, 0.5, 1, 0), size = 6.5 * PT, family = FONTE) +
    scale_x_log10(limits = c(6, 40), breaks = c(8, 10, 20, 30)) + scale_y_continuous(limits = c(0.89, 0.93)) +
    labs(x = "Backbone parameters, millions (log scale)", y = "AUC unfiltered") + tema()
  versao(3, "B", 3.0, sg(g, 3, "B", 3.0))
}

# ================================================================================================ FIGURA 4
fe <- NULL
carrega_fe <- function() { x <- rd("filter_effects_wide.csv"); x$nm <- LAB[x$filter]; fe <<- x; x }
longk <- function() { do.call(rbind, lapply(seq_along(ARCH), function(j) data.frame(filter = fe$filter, nm = fe$nm, arch = ARCH[j], rede = NOME[j], head = HEAD[j], kept = fe[[paste0("kept_pct_", ARCH[j])]], auc = fe[[paste0("auc_", ARCH[j])]], family = fe$family, k = j))) }
fig4 <- function() {
  carrega_fe(); base <- rd("networks.csv"); Ab <- base$A_unfiltered_points[match(ARCH, base$arch)]
  ord <- fe$filter[order(fe$kept_pct_mean)]; L <- longk(); L$y <- match(L$filter, ord)
  # ---- 4A: mapa de calor + pontos, h 5.1
  rot <- paste0(HEAD, "\n[", sprintf("%.1f", Ab), "]"); L$txt <- sprintf("%.0f", L$kept); L$cor <- ifelse(L$kept > 125, "white", "black")
  a <- ggplot(L, aes(k, y, fill = kept)) + geom_tile(colour = "white", linewidth = 0.4) + geom_text(aes(label = txt, colour = cor), size = 6.3 * PT, family = FONTE) + scale_colour_identity() +
    scale_fill_distiller(palette = "Blues", direction = 1, limits = c(0, 230), oob = scales::squish) +
    scale_x_continuous(breaks = 1:4, labels = rot, position = "top", expand = c(0, 0)) + scale_y_reverse(breaks = seq_along(ord), labels = LAB[ord], limits = c(17.5, 0.5), expand = c(0, 0)) +
    labs(x = NULL, y = NULL, caption = "Lesion reliance kept, % of the unfiltered model") + tema() +
    theme(axis.line = element_blank(), axis.ticks = element_blank(), axis.text.x.top = element_text(size = 6.3, lineheight = 0.9), axis.text.y = element_text(size = 6.3),
          plot.caption = element_text(size = 6.6, hjust = 0.5, family = FONTE, margin = margin(t = 1)), plot.caption.position = "panel", plot.margin = margin(1, 3, 1, 1))
  fa <- aggregate(auc ~ filter + nm, L, mean); fa$y <- match(fa$filter, ord); auc0 <- mean(base$auc_unfiltered_mean)
  p <- ggplot(fa, aes(auc, y)) + geom_hline(yintercept = seq_along(ord), colour = "grey93", linewidth = 0.2) + geom_vline(xintercept = auc0, linetype = "dashed", linewidth = 0.3, colour = "grey35") +
    geom_point(size = 1.3) + annotate("text", x = auc0 - 0.012, y = 1.0, label = "unfiltered", size = 6.3 * PT, family = FONTE, hjust = 1, colour = "grey30") +
    scale_x_continuous(limits = c(0.55, 0.95), breaks = c(0.6, 0.8)) + scale_y_reverse(breaks = NULL, limits = c(17.5, 0.5), expand = c(0, 0)) + labs(x = "Mean AUC, 4 networks", y = NULL) + tema() +
    theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), plot.margin = margin(1, 3, 1, 0))
  g4a <- (a + p + plot_layout(widths = c(1.5, 1.0))) & theme(legend.position = "none")
  versao(4, "A", 5.1, sg(g4a, 4, "A", 5.1))
  # ---- 4B: múltiplos pequenos, h 6.0
  g4b <- ggplot(L, aes(kept, y)) + geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.3, colour = "grey40") + geom_hline(yintercept = seq_along(ord), colour = "grey94", linewidth = 0.2) +
    geom_point(size = 1.3) + facet_wrap(~factor(rede, NOME), nrow = 1) + scale_y_reverse(breaks = seq_along(ord), labels = LAB[ord], expand = expansion(add = 0.6)) +
    scale_x_continuous(breaks = c(0, 100, 200)) + labs(x = "Lesion reliance kept, % of the unfiltered model", y = NULL) + tema() +
    theme(axis.text.y = element_text(size = 6.4), strip.text = element_text(size = 6.4), panel.spacing = unit(0.2, "cm"))
  g4b <- g4b + theme(axis.text.y = element_text(size = 6.4))
  versao(4, "B", 6.0, sg(g4b, 4, "B", 6.0))
  # ---- 4C: plano de trade-off, h 4.5
  fe$destr <- fe$family == "destructive"; rel <- c("AHE40.0", "CLAHE4.0", "GreenChannel", "Grayscale", "Gaussian", "Frangi", "Canny", "Otsu")
  fe$lab <- ifelse(fe$filter %in% rel, fe$nm, NA)
  g4c <- ggplot(fe, aes(dAUC_mean, kept_pct_mean)) + geom_hline(yintercept = 100, linetype = "dashed", linewidth = 0.3, colour = "grey40") + geom_vline(xintercept = 0, linetype = "dotted", linewidth = 0.3, colour = "grey60") +
    geom_errorbar(aes(ymin = kept_pct_min, ymax = kept_pct_max, colour = destr), width = 0, linewidth = 0.3) + geom_errorbarh(aes(xmin = dAUC_min, xmax = dAUC_max, colour = destr), height = 0, linewidth = 0.3) +
    geom_point(aes(colour = destr), size = 1.4) + geom_text(aes(label = lab, colour = destr), nudge_y = 9, nudge_x = 0.004, size = 6.3 * PT, family = FONTE, hjust = 0, check_overlap = TRUE, na.rm = TRUE) +
    scale_colour_manual(values = c(`FALSE` = "black", `TRUE` = "grey60")) + coord_cartesian(xlim = c(-0.35, 0.06)) +
    labs(x = "ΔAUC vs unfiltered (mean of 4 networks; bars = min to max)", y = "A kept, % (mean; bars = min to max)") + tema()
  versao(4, "C", 4.5, sg(g4c, 4, "C", 4.5))
  # ---- 4D: coordenadas paralelas, h 4.2
  dest <- c("AHE40.0", "CLAHE4.0", "GreenChannel", "Grayscale"); L$hl <- L$filter %in% dest
  lab_end <- L[L$k == 4 & L$hl, ]
  g4d <- ggplot(L, aes(k, kept, group = filter)) + geom_hline(yintercept = 100, linetype = "dashed", linewidth = 0.3, colour = "grey40") +
    geom_line(data = L[!L$hl, ], linewidth = 0.3, colour = "grey70") + geom_line(data = L[L$hl, ], aes(linetype = nm), linewidth = 0.8, colour = "black") +
    geom_point(data = L[L$hl, ], aes(shape = nm), size = 1.6) + geom_text(data = lab_end, aes(label = nm), nudge_x = 0.08, hjust = 0, size = 6.4 * PT, family = FONTE) +
    scale_x_continuous(breaks = 1:4, labels = HEAD, expand = expansion(add = c(0.15, 1.1))) + scale_y_continuous(breaks = c(0, 100, 200)) +
    labs(x = NULL, y = "A kept, %") + tema() + theme(axis.text.x = element_text(lineheight = 0.9))
  versao(4, "D", 4.2, sg(g4d, 4, "D", 4.2))
  # ---- 4E: barras por família, h 5.0
  fam_ord <- c("destructive", "contrast equalization", "smoothing / sharpening", "illumination", "neutral", "color")
  M <- aggregate(kept ~ filter + nm + family, L, mean); M$family <- factor(M$family, fam_ord); M <- M[order(M$family, M$kept), ]; M$nm <- factor(M$nm, rev(M$nm))
  L2 <- L; L2$nm <- factor(L2$nm, levels = levels(M$nm)); L2$family <- factor(L2$family, fam_ord)
  g4e <- ggplot(M, aes(kept, nm)) + geom_col(fill = "grey80", width = 0.7) + geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.3, colour = "grey40") +
    geom_point(data = L2, aes(shape = rede), size = 1.0) + scale_shape_manual(values = c(16, 15, 17, 4)) +
    facet_grid(family ~ ., scales = "free_y", space = "free_y", switch = "y", labeller = labeller(family = function(x) sub(" / ", "/\n", sub("contrast equalization", "contrast\nequalization", x)))) +
    scale_x_continuous(breaks = c(0, 100, 200), expand = expansion(mult = c(0, 0.03))) + labs(x = "A kept, % of the unfiltered model (bar = mean, dots = networks)", y = NULL) + tema() +
    theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0, size = 6.0, hjust = 1, lineheight = 0.9), axis.text.y = element_text(size = 6.2), panel.spacing = unit(0.06, "cm"),
          legend.position = "right", legend.title = element_blank(), legend.text = element_text(size = 6.3), legend.key.size = unit(0.3, "cm"))
  versao(4, "E", 5.0, sg(g4e, 4, "E", 5.0))
}

# ================================================================================================ FIGURA 5
fig5 <- function() {
  pl <- rd("pipelines_long.csv"); ps <- rd("pipelines_summary.csv"); lad <- rd("correlations_ladder.csv")
  pl$rede <- factor(NOME[match(pl$arch, ARCH)], NOME); pl$col <- as.logical(pl$collapsed)
  pm <- aggregate(cbind(AUC, A_points) ~ chain + rede, pl, mean); pm$dev <- NA
  pl$mAUC <- ave(pl$AUC, pl$chain, pl$arch); pl$mA <- ave(pl$A_points, pl$chain, pl$arch); pl$dAUC <- pl$AUC - pl$mAUC; pl$dA <- pl$A_points - pl$mA
  bet <- lad[lad$tipo == "between pipelines", ]; wit <- lad[lad$tipo == "between runs of one pipeline", ]; res <- lad[lad$tipo == "between, AUC in [0.89, 0.915]", ]
  # ---- 5A: dispersão + barras, h 4.3 (como v2, compacta)
  ps2 <- read.csv("../esann_figs/fig3_pipelines_v2s.csv"); ps2 <- ps2[as.character(ps2$deg) %in% c("False", "FALSE"), ]; rr <- read.csv("../esann_figs/fig3_runs_destacados.csv"); rr$g <- factor(match(rr$condicao, unique(rr$condicao)))
  cols <- c("#08306b", "#cc5500", "#2e7d32", "#7b1fa2", "#000000"); shp <- c(16, 15, 17, 18, 25)
  pa <- ggplot() + geom_point(data = ps2, aes(AUC, A), size = 0.7, colour = "grey60", stroke = 0) + geom_path(data = rr, aes(AUC, Apts, group = g, colour = g), linewidth = 0.4) +
    geom_point(data = rr, aes(AUC, Apts, colour = g, shape = g, fill = g), size = 1.6, stroke = 0.2) + scale_colour_manual(values = cols) + scale_fill_manual(values = cols) + scale_shape_manual(values = shp) +
    annotate("point", x = 0.714, y = 21.5, size = 0.7, colour = "grey60") + annotate("text", x = 0.724, y = 21.5, label = "pipeline mean", size = 6.3 * PT, hjust = 0, family = FONTE) +
    annotate("point", x = 0.714, y = 19, size = 1.6) + annotate("text", x = 0.724, y = 19, label = "3 runs of one pipeline", size = 6.3 * PT, hjust = 0, family = FONTE) +
    scale_x_continuous(breaks = c(0.75, 0.85)) + scale_y_continuous(breaks = c(0, 5, 10, 15)) + coord_cartesian(ylim = c(-3, 23), xlim = c(0.705, 0.925), expand = FALSE) +
    labs(x = "AUC", y = "Lesion reliance (points)", title = "(a) EfficientNetV2-S") + tema()
  bar <- rbind(data.frame(x = 1:4 - 0.2, v = bet$rho, t = "pipelines"), data.frame(x = 1:4 + 0.2, v = wit$rho, t = "runs"))
  pb <- ggplot(bar, aes(x, v, fill = t)) + geom_col(width = 0.36, colour = "grey15", linewidth = 0.3) + scale_fill_manual(values = c(pipelines = "grey15", runs = "white")) +
    geom_text(aes(label = sprintf("%.2f", v)), vjust = -0.35, size = 6.3 * PT, family = FONTE) + scale_x_continuous(breaks = 1:4, labels = HEAD) + scale_y_continuous(limits = c(0, 1.5), breaks = c(0, .5, 1)) +
    annotate("text", x = 0.55, y = 1.45, label = "dark: across pipelines", size = 6.3 * PT, hjust = 0, family = FONTE) + annotate("text", x = 0.55, y = 1.28, label = "white: across runs of one pipeline", size = 6.3 * PT, hjust = 0, family = FONTE) +
    labs(x = NULL, y = "Spearman ρ (AUC, A)", title = "(b)") + tema() + theme(axis.text.x = element_text(lineheight = 0.9))
  versao(5, "A", 4.3, sg(pa + pb + plot_layout(widths = c(1.15, 1)), 5, "A", 4.3))
  # ---- 5B: uma dispersão por rede, h 4.5
  ann <- data.frame(rede = factor(NOME, NOME), lab = sprintf("ρ pipelines = %.2f\nρ runs = %.2f", bet$rho, wit$rho))
  g5b <- ggplot(pm, aes(AUC, A_points)) + geom_point(size = 0.7, colour = "grey30", alpha = 0.8) + geom_smooth(method = "lm", se = FALSE, linewidth = 0.4, colour = "black") +
    geom_text(data = ann, aes(label = lab), x = 0.55, y = Inf, vjust = 1.2, hjust = 0, size = 6.3 * PT, family = FONTE, lineheight = 0.95, inherit.aes = FALSE) +
    facet_wrap(~rede, nrow = 1) + scale_x_continuous(breaks = c(0.6, 0.8)) + labs(x = "AUC (pipeline mean)", y = "A (points)") + tema() + theme(panel.spacing = unit(0.2, "cm"))
  versao(5, "B", 4.5, sg(suppressMessages(g5b), 5, "B", 4.5))
  # ---- 5C: entre e dentro, h 4.6
  pa2 <- ggplot(pm, aes(AUC, A_points, shape = rede)) + geom_point(size = 0.8, alpha = 0.8) + scale_shape_manual(values = c(16, 15, 17, 4)) +
    labs(x = "AUC (pipeline mean)", y = "A (points)", title = "(a) between pipelines") + tema() + theme(legend.position = c(0.28, 0.82), legend.title = element_blank(), legend.text = element_text(size = 6.3), legend.key.size = unit(0.28, "cm"), legend.background = element_blank())
  pb2 <- ggplot(pl, aes(dAUC, dA, shape = rede)) + geom_point(size = 0.35, alpha = 0.35) + geom_smooth(aes(linetype = rede), method = "lm", se = FALSE, linewidth = 0.4, colour = "black") +
    scale_shape_manual(values = c(16, 15, 17, 4)) + coord_cartesian(xlim = c(-0.12, 0.12), ylim = c(-0.08, 0.08)) + scale_x_continuous(breaks = c(-0.1, 0, 0.1)) +
    labs(x = "AUC − pipeline mean", y = "A − pipeline mean (prob.)", title = "(b) between runs of the same pipeline") + tema()
  versao(5, "C", 4.6, sg(suppressMessages(pa2 + pb2), 5, "C", 4.6))
  # ---- 5D: escada de correlações, h 2.6
  lad$tipo2 <- factor(lad$tipo, c("between pipelines", "between, AUC in [0.89, 0.915]", "between runs of one pipeline"), c("between pipelines\n(all 185)", "between pipelines,\nAUC 0.89–0.915", "between the 3 runs\nof one pipeline"))
  lad$rede <- factor(NOME[match(lad$arch, ARCH)], NOME); lad$x <- as.integer(lad$tipo2)
  g5d <- ggplot(lad, aes(x, rho, shape = rede, group = rede)) + geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey50") +
    geom_line(linewidth = 0.35, position = position_dodge(0.18)) + geom_errorbar(aes(ymin = ci95_low, ymax = ci95_high), width = 0, linewidth = 0.3, position = position_dodge(0.18)) +
    geom_point(size = 1.6, position = position_dodge(0.18), fill = "white") + scale_shape_manual(values = c(16, 15, 17, 4)) +
    scale_x_continuous(breaks = 1:3, labels = levels(lad$tipo2), expand = expansion(add = 0.4)) + scale_y_continuous(breaks = c(0, 0.5, 1)) +
    labs(x = NULL, y = "Spearman ρ (AUC, A)") + tema() + theme(legend.position = "right", legend.title = element_blank(), legend.text = element_text(size = 6.3), legend.key.size = unit(0.3, "cm"))
  versao(5, "D", 2.6, sg(g5d, 5, "D", 2.6))
}

# ================================================================================================ FIGURA 6
fig6 <- function() {
  s <- rd("chains_similar_auc.csv"); s <- s[order(s$A_points_mean4), ]; s$r <- seq_len(nrow(s)); b <- rd("networks.csv"); A0 <- mean(b$A_unfiltered_points); auc0 <- mean(b$auc_unfiltered_mean)
  ext <- s[c(1, 2, nrow(s) - 1, nrow(s)), ]; lbl <- function(x) gsub("([0-9])\\.0", "\\1", gsub("40.0", "", gsub("4.0", "", gsub("2.0", "", gsub("1.5", "", gsub("0.8", "", x)))))); nm1 <- function(x) { p <- strsplit(x, " > ")[[1]]; paste(sapply(p, function(z) { k <- names(LAB)[sapply(names(LAB), function(n) z == n)]; if (length(k)) LAB[[k]] else z }), collapse = " > ") }
  s$nm <- sapply(s$pipeline, nm1)
  # ---- 6A
  g6a <- ggplot(s, aes(r, A_points_mean4)) + geom_hline(yintercept = A0, linetype = "dashed", linewidth = 0.3, colour = "grey40") + geom_point(size = 1.2) +
    annotate("text", x = 4, y = A0 + 0.7, label = sprintf("unfiltered: A = %.1f", A0), size = 6.3 * PT, family = FONTE, colour = "grey30", hjust = 0) +
    geom_text(data = s[c(1, nrow(s)), ], aes(label = nm), size = 6.2 * PT, family = FONTE, hjust = c(0, 1), nudge_x = c(0.8, -0.8), nudge_y = c(0.9, -0.2)) +
    geom_text(data = s[c(2, nrow(s) - 1), ], aes(label = nm), size = 6.2 * PT, family = FONTE, hjust = c(0, 1), nudge_x = c(0.8, -0.8), nudge_y = c(-1.0, -0.9)) +
    scale_x_continuous(breaks = c(1, 10, 20, 27), expand = expansion(add = 1)) + scale_y_continuous(limits = c(2.5, 16), breaks = c(5, 10, 15)) +
    labs(x = "pipeline rank by A (27 pipelines with AUC within ±0.01 of the unfiltered model)", y = "A (points)") + tema()
  versao(6, "A", 4.0, sg(g6a, 6, "A", 4.0))
  # ---- 6B: pirulitos
  s$nm2 <- factor(s$nm, s$nm); s$show <- ifelse(s$r %in% c(1:3, (nrow(s) - 2):nrow(s)), s$nm, NA)
  g6b <- ggplot(s, aes(A_points_mean4, nm2)) + geom_vline(xintercept = A0, linetype = "dashed", linewidth = 0.3, colour = "grey40") + geom_segment(aes(x = 0, xend = A_points_mean4, yend = nm2), linewidth = 0.3, colour = "grey60") +
    geom_point(size = 1.1) + geom_text(aes(label = show), hjust = 0, nudge_x = 0.25, size = 6.3 * PT, family = FONTE, na.rm = TRUE) +
    scale_y_discrete(breaks = NULL) + scale_x_continuous(limits = c(0, 22), breaks = c(0, 5, 10, 15)) + labs(x = sprintf("A (points); dashed = unfiltered (%.1f)", A0), y = NULL) + tema()
  versao(6, "B", 5.5, sg(g6b, 6, "B", 5.5))
  # ---- 6C: tabela com miniaturas
  ex <- read.csv("dados/chains_extremas.csv"); linhas <- rbind(data.frame(chain = ex$chain[1:2]), data.frame(chain = "unfiltered"), data.frame(chain = ex$chain[3:4]))
  versao(6, "C", 4.5, sgrid(6, "C", 4.5, function() {
    grid.newpage(); txt("Pipeline (same exam)", 1.0, 0.25, 6.5, "left", face = "bold"); txt("AUC", 9.1, 0.25, 6.5, "left", face = "bold"); txt("A (points)", 10.4, 0.25, 6.5, "left", face = "bold")
    for (r in 1:5) {
      ch <- linhas$chain[r]; t <- 0.5 + (r - 1) * 0.74
      f <- if (ch == "unfiltered") "paineis/cadeias/exame_original.png" else file.path("paineis/extremas", paste0(gsub(" > ", "_", ch), ".png"))
      img(readPNG(f), 0.1, t, 0.66)
      if (ch == "unfiltered") { auc <- auc0; a <- A0; nome <- "unfiltered" } else { row <- s[s$pipeline == ch, ]; auc <- row$AUC_mean4; a <- row$A_points_mean4; nome <- row$nm }
      txt(gsub(" > ", "  →  ", nome), 1.0, t + 0.33, 6.6, "left", maxw = 7.9); txt(sprintf("%.3f", auc), 9.1, t + 0.33, 6.6, "left"); txt(sprintf("%.1f", a), 10.4, t + 0.33, 6.6, "left")
    }
    txt("rows: the 2 lowest A, the unfiltered model, and the 2 highest A among pipelines with AUC within ±0.01 of it (mean of 4 networks)", 0.1, 4.42, 6.3, "left", "grey20", maxw = 12)
  }))
  # ---- 6D: dispersão com faixa
  ps <- rd("pipelines_summary.csv"); ps <- ps[ps$pipeline != "unfiltered", ]
  ext$lx <- c(0.8605, 0.8605, 0.8605, 0.8605); ext$ly <- c(1.8, 0.4, 15.4, 14.0); ext$nm <- sapply(ext$pipeline, nm1)
  g6d <- ggplot(ps, aes(AUC_mean4, A_points_mean4)) + annotate("rect", xmin = auc0 - 0.01, xmax = auc0 + 0.01, ymin = -Inf, ymax = Inf, fill = "grey88") + geom_point(size = 0.8, colour = "grey35") +
    geom_segment(data = ext, aes(x = lx + 0.0, xend = AUC_mean4, y = ly, yend = A_points_mean4), linewidth = 0.25, colour = "grey40") +
    geom_point(data = ext, aes(AUC_mean4, A_points_mean4), size = 1.6, shape = 21, fill = "white", stroke = 0.7) + geom_text(data = ext, aes(x = lx, y = ly, label = nm), size = 6.2 * PT, family = FONTE, hjust = 0, vjust = 0.5, nudge_x = -0.0004) +
    coord_cartesian(xlim = c(0.858, 0.93), ylim = c(0, 16.5)) + scale_x_continuous(breaks = c(0.86, 0.88, 0.90, 0.92)) + labs(x = "AUC (mean of 4 networks); shaded band = unfiltered AUC \u00b1 0.01", y = "A (points)") + tema()
  versao(6, "D", 4.0, sg(g6d, 6, "D", 4.0))
}

# ================================================================================================ FIGURA 7
fig7 <- function() {
  d <- rd("ddr_results.csv"); d$rede <- factor(NOME[match(d$arch, ARCH)], NOME); ok <- sum(d$`atinge_0.70` == "sim")
  b <- rd("networks.csv"); d$fg <- b$auc_unfiltered_mean[match(d$arch, b$arch)]
  txtv <- c(H4 = "H4  CLAHE reduces A", H5a = "H5a  Green channel increases A", H5b = "H5b  Grayscale increases A")
  ver <- if (ok < 3) "not assessable" else "see table"
  # ---- 7B: validade + vereditos (única exigida; resultados 'não avaliáveis')
  g1 <- ggplot(d, aes(rede, auc_baseline_media)) + geom_col(width = 0.55, fill = ifelse(d$`atinge_0.70` == "sim", "grey25", "white"), colour = "grey15", linewidth = 0.4) +
    geom_errorbar(aes(ymin = auc_baseline_ic95_inf, ymax = auc_baseline_ic95_sup), width = 0.15, linewidth = 0.35) + geom_hline(yintercept = 0.70, linetype = "dashed", linewidth = 0.4) +
    annotate("text", x = 4.45, y = 0.715, label = "0.70", size = 6.4 * PT, family = FONTE, hjust = 1) + geom_text(aes(label = sprintf("%.2f", auc_baseline_media), y = auc_baseline_ic95_sup + 0.03), size = 6.4 * PT, family = FONTE) +
    scale_y_continuous(limits = c(0.5, 0.85), breaks = c(0.5, 0.6, 0.7, 0.8), oob = scales::squish) + coord_cartesian(ylim = c(0.5, 0.85)) +
    scale_x_discrete(labels = HEAD) + labs(x = NULL, y = "AUC, unfiltered, DDR") + tema() + theme(axis.text.x = element_text(lineheight = 0.9))
  tv <- data.frame(y = 3:1, h = txtv, s = "○")
  g2 <- ggplot(tv) + geom_text(aes(x = 0, y = y, label = h), hjust = 0, size = 6.5 * PT, family = FONTE) + geom_text(aes(x = 0.62, y = y, label = s), size = 9 * PT, family = FONTE) +
    geom_text(aes(x = 0.68, y = y, label = ver), hjust = 0, size = 6.5 * PT, family = FONTE) + annotate("text", x = 0, y = 0.1, hjust = 0, size = 6.2 * PT, family = FONTE, colour = "grey25",
      label = sprintf("○ not assessable (validity: %d of 4 networks reach AUC 0.70; rule needs 3)   ✓ confirmed   ✗ not confirmed", ok)) +
    scale_x_continuous(limits = c(0, 1)) + scale_y_continuous(limits = c(-0.2, 3.5)) + theme_void()
  versao(7, "B", 3.2, sg(g1 / g2 + plot_layout(heights = c(2.1, 1.1)), 7, "B", 3.2))
  # ---- extra (não pedido, pois os resultados não são avaliáveis): 7A
  f4 <- read.csv("../esann_figs/fig4_data.csv"); f4$rede <- factor(NOME[match(f4$arch, ARCH)], rev(NOME)); f4$filtro <- factor(c(CLAHE4.0 = "CLAHE", GreenChannel = "Green channel", Grayscale = "Grayscale")[f4$filter], c("CLAHE", "Green channel", "Grayscale"))
  f4$apta <- ifelse(f4$meets_threshold, "AUC ≥ 0.70 in DDR", "AUC < 0.70 in DDR")
  ga <- ggplot(f4, aes(y = rede)) + geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.3, colour = "grey40") + geom_linerange(aes(xmin = ci_low, xmax = ci_high), orientation = "y", linewidth = 0.4, position = position_nudge(y = 0.14)) +
    geom_point(aes(x = kept_ddr, shape = apta), size = 1.9, stroke = 0.5, fill = "white", position = position_nudge(y = 0.14)) + geom_point(aes(x = kept_fgadr, shape = "FGADR (same models)"), size = 1.9, stroke = 0.5, colour = "grey35", position = position_nudge(y = -0.18)) +
    scale_shape_manual(values = c(`AUC ≥ 0.70 in DDR` = 16, `AUC < 0.70 in DDR` = 21, `FGADR (same models)` = 4)) + scale_x_continuous(breaks = c(0, 100, 200)) + facet_wrap(~filtro, nrow = 1) + coord_cartesian(xlim = c(0, 250)) +
    labs(x = "Lesion reliance kept, % of the unfiltered model", y = NULL) + tema() + theme(legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 6.3), legend.key.size = unit(0.3, "cm"), panel.spacing = unit(0.4, "cm"))
  dir.create(file.path(FIG, "extras_nao_pedidos"), showWarnings = FALSE)
  n <- file.path(FIG, "extras_nao_pedidos", nome_arq(7, "A", 3.8)); ggsave(paste0(n, ".pdf"), ga, width = 12.2, height = 3.8, units = "cm", device = cairo_pdf); ggsave(paste0(n, ".png"), ga, width = 12.2, height = 3.8, units = "cm", dpi = 300, type = "cairo")
}

# ================================================================================================ FIGURA 8
fig8 <- function() {
  lt <- rd("lesion_type.csv"); lt$rede <- factor(NOME[match(lt$arch, ARCH)], NOME); lt$f <- factor(c(AHE40.0 = "AHE", CLAHE4.0 = "CLAHE", GreenChannel = "Green channel", Grayscale = "Grayscale")[lt$filter], c("AHE", "CLAHE", "Green channel", "Grayscale"))
  lt$tipo <- factor(lt$lesion, c("MA", "HE", "EX", "SE"))
  mm <- aggregate(dA_pct_of_unfiltered ~ f + tipo, lt, mean); ns <- aggregate(significant ~ f + tipo, lt, function(x) sum(as.logical(x))); mm$n_sig <- ns$significant
  mm$lab <- sprintf("%+.0f%s", mm$dA_pct_of_unfiltered, ifelse(mm$n_sig >= 3, "*", ""))
  hm <- function(d, colour_lab = TRUE) ggplot(d, aes(tipo, f, fill = dA_pct_of_unfiltered)) + geom_tile(colour = "white", linewidth = 0.5) + geom_text(aes(label = lab, colour = abs(dA_pct_of_unfiltered) > 60), size = 6.5 * PT, family = FONTE) +
    scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "black")) + scale_fill_gradient2(low = "#2c3e50", mid = "white", high = "#7f8c8d", midpoint = 0, limits = c(-100, 100), oob = scales::squish) +
    scale_y_discrete(limits = rev(levels(d$f))) + scale_x_discrete(position = "top") + labs(x = NULL, y = NULL) + tema() + theme(axis.line = element_blank(), axis.ticks = element_blank(), axis.text = element_text(size = 6.5))
  versao(8, "A", 2.6, sg(hm(mm) + labs(caption = "ΔA, % of the unfiltered model (mean of 4 networks); * = significant in ≥ 3 of 4 networks") + theme(plot.caption = element_text(size = 6.3, family = FONTE, hjust = 0)), 8, "A", 2.6))
  g8b <- ggplot(mm, aes(tipo, dA_pct_of_unfiltered, fill = f)) + geom_hline(yintercept = 0, linewidth = 0.3) + geom_col(position = position_dodge(0.8), width = 0.75, colour = "grey15", linewidth = 0.3) +
    geom_text(aes(label = ifelse(n_sig >= 3, "*", "")), position = position_dodge(0.8), vjust = ifelse(mm$dA_pct_of_unfiltered >= 0, -0.1, 1.1), size = 7 * PT, family = FONTE) +
    scale_fill_manual(values = c("grey20", "grey45", "white", "grey80")) + scale_y_continuous(expand = expansion(mult = 0.14)) + labs(x = "lesion type", y = "ΔA, % of unfiltered") + tema() +
    theme(legend.position = "right", legend.title = element_blank(), legend.text = element_text(size = 6.4), legend.key.size = unit(0.3, "cm"))
  versao(8, "B", 3.2, sg(g8b, 8, "B", 3.2))
  lt$lab <- sprintf("%+.0f%s", lt$dA_pct_of_unfiltered, ifelse(as.logical(lt$significant), "*", ""))
  g8c <- hm(transform(lt, lab = lab)) + facet_wrap(~rede, nrow = 1) + theme(panel.spacing = unit(0.15, "cm"), strip.text = element_text(size = 6.4))
  versao(8, "C", 4.2, sg(g8c, 8, "C", 4.2))
}

# ================================================================================================ folhas de contato
contato <- function(n) {
  fs <- sort(list.files(FIG, pattern = sprintf("^fig%d_v.*_h.*cm\\.png$", n), full.names = TRUE)); fs <- fs[!grepl("_gray", fs)]
  if (!length(fs)) return(invisible())
  ims <- lapply(fs, readPNG); hs <- sapply(ims, function(m) dim(m)[1] / 300 * 2.54); ws <- sapply(ims, function(m) dim(m)[2] / 300 * 2.54)
  cols <- 2; rows <- ceiling(length(fs) / cols); pad <- 0.5; lab <- 0.45
  rh <- sapply(seq_len(rows), function(r) max(hs[((r - 1) * cols + 1):min(r * cols, length(fs))]) + lab + pad)
  Wt <- cols * (12.2 + pad) + pad; Ht <- sum(rh) + pad
  png(file.path(FIG, sprintf("contact_fig%d.png", n)), width = Wt, height = Ht, units = "cm", res = 110, type = "cairo", family = FONTE)
  grid.newpage(); grid.rect(gp = gpar(fill = "white", col = NA)); y <- Ht - pad
  for (r in seq_len(rows)) for (cc in 1:cols) {
    k <- (r - 1) * cols + cc; if (k > length(fs)) next
    x <- pad + (cc - 1) * (12.2 + pad); yt <- Ht - pad - sum(rh[seq_len(r - 1)])
    grid.text(sub("\\.png$", "", basename(fs[k])), x = unit(x, "cm"), y = unit(yt - 0.2, "cm"), just = c("left", "center"), gp = gpar(fontsize = 8, fontfamily = FONTE, fontface = "bold"))
    grid.rect(x = unit(x, "cm"), y = unit(yt - lab, "cm"), width = unit(ws[k], "cm"), height = unit(hs[k], "cm"), just = c("left", "top"), gp = gpar(col = "grey70", fill = NA, lwd = 0.4))
    grid.raster(ims[[k]], x = unit(x, "cm"), y = unit(yt - lab, "cm"), width = unit(ws[k], "cm"), height = unit(hs[k], "cm"), just = c("left", "top"), interpolate = TRUE)
  }
  dev.off()
}

args <- commandArgs(trailingOnly = TRUE); alvo <- if (length(args)) as.integer(args) else c(1, 2, 4, 5, 7, 6, 3, 8)
fun <- list(`1` = fig1, `2` = fig2, `3` = fig3, `4` = fig4, `5` = fig5, `6` = fig6, `7` = fig7, `8` = fig8)
for (n in alvo) {
  r <- tryCatch({ fun[[as.character(n)]](); "ok" }, error = function(e) paste("ERRO:", conditionMessage(e)))
  if (r != "ok") LOG <- c(LOG, sprintf("fig%d (geral): %s", n, r))
  tryCatch(contato(n), error = function(e) LOG <<- c(LOG, paste("contato", n, conditionMessage(e))))
}
writeLines(c(LOG, "", "AVISOS de texto que não coube (já reduzido ao mínimo permitido):", unique(AVISOS)), file.path(FIG, "relatorio_execucao.txt"))
cat("feito\n")
