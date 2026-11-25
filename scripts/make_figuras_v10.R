# Figuras 3 (tamanho original, 10,2 cm) e 4 (legenda única maior, rho dentro dos painéis). Uso (em esann_materiais/): Rscript make_figuras_v10.R
Sys.setenv(SO_DEFS = "1"); source("make_figuras_v8.R")
W <- 12.17 / 2.54; OUT10 <- "entrega_v6"; dir.create(OUT10, showWarnings = FALSE)
sg2 <- function(g, nome, h) { ggsave(file.path(OUT10, paste0(nome, ".pdf")), g, width = 12.17, height = h, units = "cm", device = cairo_pdf)
  ggsave(file.path(OUT10, paste0(nome, ".png")), g, width = 12.17, height = h, units = "cm", dpi = 300, type = "cairo") }
fig4_obj <- function(unica = TRUE, reta = FALSE, lw = 1.6, lt = list(a = rep("solid", 4), b = rep("solid", 4)), alfa = 0.35, tam = 1.4, xmin = 0.45, casing = 0, escuro = 1, xmax = 0.95, xbreaks = c(0.5, 0.7, 0.9)) {
  pl <- rd("pipelines_long.csv"); lad <- rd("correlations_ladder.csv"); pl$rede <- factor(NOME[match(pl$arch, ARCH)], NOME)
  pm <- aggregate(cbind(AUC, A_points) ~ chain + rede, pl, mean)
  pl$mAUC <- ave(pl$AUC, pl$chain, pl$arch); pl$mA <- ave(pl$A_points, pl$chain, pl$arch); pl$dAUC <- pl$AUC - pl$mAUC; pl$dA100 <- pl$A_points - pl$mA
  bet <- lad[lad$tipo == "between pipelines", ]$rho; wit <- lad[lad$tipo == "between runs of one pipeline", ]$rho
  cols <- c("#1f4e8c", "#b03a2e", "#1e7a4c", "#6a3d9a"); glifos <- c("\u25a0", "\u25cf", "\u25b2", "\u2605"); curto <- c("EffNetV2-S", "EffNetV2-B2", "InceptionV3", "ResNet-50")
  mk <- function(d, x, y, rho, tag, xl, yl, suave, lt_p, rx = 0, ry = 0, dx = 0, dy = 0) {
    lab <- if (unica) curto else sprintf("%s \u03c1=%.2f", curto, rho); d$lab <- factor(lab[as.integer(d$rede)], lab)
    ggplot(d, aes(.data[[x]], .data[[y]], colour = lab, shape = lab)) +
      geom_point(size = tam, alpha = alfa, stroke = 0) +
      (if (casing > 0 && x == "AUC") geom_smooth(aes(group = lab), colour = "white", data = function(z) if (x == "dAUC") z[abs(z$dAUC) <= 0.05, ] else z, method = suave$m, formula = suave$f, se = FALSE, linewidth = lw + casing, show.legend = FALSE, span = suave$span) else NULL) +
      geom_smooth(aes(group = lab, linetype = lab, colour = stage(lab, after_scale = rgb(t(col2rgb(colour)) * escuro, maxColorValue = 255))), data = function(z) if (x == "dAUC") z[abs(z$dAUC) <= 0.05, ] else z, method = suave$m, formula = suave$f, se = FALSE, linewidth = lw, show.legend = FALSE, span = suave$span) +
      scale_linetype_manual(values = setNames(lt_p, lab), guide = "none") +
      scale_colour_manual(values = setNames(cols, lab)) + scale_shape_manual(values = setNames(glifos, lab)) +
      (if (unica) annotate("text", x = rx[1] + c(0, dx, 0, dx), y = ry[1] - c(0, 0, dy, dy), label = sprintf("%s \u03c1=%.2f", glifos, rho), colour = cols, hjust = 0, size = (TX - 0.3) * PT, family = FONTE) else NULL) +
      labs(x = xl, y = yl, title = tag) + tema8() +
      guides(colour = guide_legend(nrow = if (unica) 1 else 2, byrow = TRUE, override.aes = list(size = if (unica) 3.6 else 3.0, alpha = 1)), shape = guide_legend(nrow = if (unica) 1 else 2, byrow = TRUE)) +
      theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(if (unica) 0.5 else 0.4, "cm"), legend.margin = margin(t = 0), legend.spacing.x = unit(0.03, "cm"), legend.text = element_text(size = TX - LEGD, margin = margin(r = 4)),
            panel.grid.major = element_line(colour = "grey92", linewidth = 0.25), plot.title.position = "panel", plot.title = element_text(size = TX + 0.8, face = "bold", hjust = 0, margin = margin(b = 3)), plot.margin = margin(3, 6, 2, 3))
  }
  sa <- if (reta) list(m = "lm", f = y ~ x, span = NULL) else list(m = "loess", f = y ~ x, span = 0.9)
  sb <- if (reta) list(m = "lm", f = y ~ x, span = NULL) else list(m = "gam", f = y ~ s(x, k = 4), span = NULL)
  a <- mk(pm, "AUC", "A_points", bet, "(a)", "AUC", "Lesion reliance A (points)", sa, lt$a, rx = 0.47, ry = 20.2, dx = 0.27, dy = 2.6) + scale_x_continuous(breaks = xbreaks, labels = function(v) sprintf("%.2f", v), limits = c(xmin, xmax), expand = c(0, 0)) + scale_y_continuous(limits = c(-2, 21), breaks = c(0, 10, 20), expand = c(0, 0))
  b <- mk(pl, "dAUC", "dA100", wit, "(b)", "AUC \u2212 pipeline mean", "A \u2212 pipeline mean (points)", sb, lt$b, rx = -0.0475, ry = 11.6, dx = 0.052, dy = 1.7) + geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey55") + geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey55") +
    scale_x_continuous(breaks = c(-0.04, 0, 0.04)) + coord_cartesian(xlim = c(-0.05, 0.05), ylim = c(-8, 12.5), expand = FALSE)
  suppressMessages(a + b + plot_layout(widths = c(1.05, 1), guides = if (unica) "collect" else "keep") & theme(legend.position = "bottom"))
}

fig3P <- function() {
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
  sg2(g, "fig3_filters", 10.2)
}

# ------------------------------------------------------------------------------ Figura 5 (N): curvas suaves, paleta sóbria, painel (c) com o rho restrito

fig4P <- function() { TX <<- 9.5; LEGD <<- 0.5; sg2(fig4_obj(TRUE, TRUE, 0.6, list(a = rep("solid", 4), b = rep("solid", 4)), 0.5, 2.1, casing = 0.4, xmax = 1.0, xbreaks = c(0.5, 0.75, 1.0)), "fig4_auc_reliance", 8.0) }
for (f in list(fig3P, fig4P)) { r <- tryCatch({ suppressMessages(f()); "ok" }, error = function(e) paste("ERRO:", conditionMessage(e))); cat(r, "\n") }
