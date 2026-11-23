# Prompt v5: fig2, fig3 e fig5 do artigo com altura menor. Uso (na pasta esann_materiais/): Rscript make_figuras_v9.R
Sys.setenv(SO_DEFS = "1"); source("make_figuras_v8.R")
W <- 12.17 / 2.54; OUT9 <- "entrega_v5"; dir.create(OUT9, showWarnings = FALSE); PREV9 <- Sys.getenv("PREVIEW9")
sg2 <- function(g, nome, h) { ggsave(file.path(OUT9, paste0(nome, ".pdf")), g, width = 12.17, height = h, units = "cm", device = cairo_pdf)
  ggsave(file.path(OUT9, paste0(nome, ".png")), g, width = 12.17, height = h, units = "cm", dpi = 300, type = "cairo") }
sgrid2 <- function(nome, h, fun) { HT <<- h; cairo_pdf(file.path(OUT9, paste0(nome, ".pdf")), width = W, height = h / 2.54, family = FONTE); fun(); dev.off()
  png(file.path(OUT9, paste0(nome, ".png")), width = 12.17, height = h, units = "cm", res = 300, type = "cairo", family = FONTE); fun(); dev.off() }
fig2P <- function() sgrid2("fig2_pipeline", 2.55, function() {
  grid.newpage(); cad <- "Retinex_GreenChannel_CLAHE4.0_Gaussian"; pas <- function(j) readPNG(sprintf("paineis/cadeias/%s__passo%d.png", cad, j))
  iw <- 1.85; gp <- (12.0 - 5 * iw) / 4; xl <- 0.1 + (0:4) * (iw + gp); cx <- xl + iw / 2; ti <- 0.5
  imgs <- list(readPNG("paineis/cadeias/exame_original.png"), pas(1), pas(2), pas(3), pas(4))
  for (k in 1:5) {
    if (is.null(imgs[[k]])) { rrect(xl[k], ti, iw, iw, "white", "grey50", 0.7, 2); txt("—", cx[k], ti + iw / 2, 8.5, col = "grey40") } else img(imgs[[k]], xl[k], ti, iw)
    if (k > 1) { grid.rect(x = cm(cx[k]), y = Y(ti + iw - 0.19), width = cm(iw - 0.2), height = cm(0.3), gp = gpar(fill = "black", col = NA, alpha = 0.72)); txt(c("Retinex", "Green channel", "CLAHE", "Gaussian")[k - 1], cx[k], ti + iw - 0.19, 8.0, col = "white", maxw = iw - 0.3, minsize = 7.0) }
    if (k > 1) seta(xl[k - 1] + iw + 0.07, ti + iw / 2, xl[k] - 0.07, ti + iw / 2, 0.9)
    if (k > 1) txt(STAGE[k - 1], cx[k], 0.24, 9.0, face = "bold", maxw = iw + gp - 0.1, minsize = 7.5)
  }
})

fig3P <- function() {
  TX <<- 6.9
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
  g <- ggplot(L, aes(delta, nm)) + geom_col(aes(fill = neg), width = 0.58, alpha = 0.65, show.legend = FALSE, na.rm = TRUE) + geom_vline(xintercept = 0, linewidth = 0.4, colour = "grey30") +
    geom_errorbar(aes(xmin = delta - sd, xmax = delta + sd), orientation = "y", width = 0.35, linewidth = 0.3, colour = "grey10", na.rm = TRUE) +
    geom_text(aes(x = 300, label = lab), hjust = 1, na.rm = TRUE, size = (TX - 0.6) * PT, family = FONTE) +
    scale_fill_manual(values = c(`TRUE` = "#b03a2e", `FALSE` = "#1f4e8c")) +
    facet_grid(stage ~ rede, scales = "free_y", space = "free_y", switch = "y") +
    scale_x_continuous(breaks = c(-100, 0, 100), limits = c(-115, 305), expand = c(0, 0)) + labs(x = "Change in lesion reliance (%)", y = NULL) + tema8() +
    theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 90, hjust = 0.5, size = TX - 0.2, face = "bold", lineheight = 0.85), strip.text.x = element_text(size = TX - 0.4, face = "bold"), strip.background = element_blank(),
          panel.spacing.x = unit(0.2, "cm"), panel.spacing.y = unit(0.08, "cm"), axis.text.y = element_text(size = TX), axis.text.x = element_text(size = TX - 0.5), axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.line.x = element_blank(),
          panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.25), panel.border = element_rect(colour = "grey75", fill = NA, linewidth = 0.3), plot.margin = margin(2, 4, 1, 2))
  sg2(g, "fig3_filters", 6.5)
}

fig5P <- function() {
  s <- rd("chains_similar_auc.csv"); b <- rd("networks.csv"); A0 <- mean(b$A_unfiltered_points); auc0 <- mean(b$auc_unfiltered_mean)
  nm <- function(x) { p <- strsplit(x, " > ")[[1]]; paste(sapply(p, function(z) if (z %in% names(LAB)) LAB[[z]] else z), collapse = "  →  ") }
  ex <- read.csv("dados/chains_extremas.csv"); linhas <- c(ex$chain[1:2], "Unfiltered", ex$chain[3:4])
  sgrid2("fig5_chains", 4.5, function() {
    grid.newpage(); txt("Pipeline", 1.4, 0.22, 8.4, "left", face = "bold"); txt("AUC", 8.9, 0.22, 8.4, "left", face = "bold"); txt("A (points)", 10.0, 0.22, 8.4, "left", face = "bold"); hl(0.1, 12.1, 0.45, 0.7)
    for (r in 1:5) { ch <- linhas[r]; t <- 0.5 + (r - 1) * 0.79
      f <- if (ch == "Unfiltered") "paineis/cadeias/exame_original.png" else file.path("paineis/extremas", paste0(gsub(" > ", "_", ch), ".png")); img(readPNG(f), 0.1, t, 0.7)
      if (ch == "Unfiltered") { auc <- auc0; a <- A0; n <- "Unfiltered" } else { row <- s[s$pipeline == ch, ]; auc <- row$AUC_mean4; a <- row$A_points_mean4; n <- nm(ch) }
      txt(n, 1.0, t + 0.35, 8.4, "left", maxw = 7.7, minsize = 7.4); txt(sprintf("%.3f", auc), 8.9, t + 0.35, 8.4, "left"); txt(sprintf("%.1f", a), 10.0, t + 0.35, 8.4, "left") }
    hl(0.1, 12.1, 4.45, 0.7)
  })
}


for (f in list(fig2P, fig3P, fig5P)) { r <- tryCatch({ suppressMessages(f()); "ok" }, error = function(e) paste("ERRO:", conditionMessage(e))); cat(r, "\n") }
