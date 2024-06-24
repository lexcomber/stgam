#' Plots a 1-Dimensional GAM smooth
#'
#' @param mod a GAM model with smooths created using the mgcv package
#' @param ncol the number of columns for the compound plot
#' @param nrow the number of rows for the compound plot
#' @param fills the fill colours (single or vector)
#'
#' @return A compound plot of the GAM 1-dimensioanl smooths (rendered using `cowplot::plot_grid`).
#' @importFrom grDevices pdf
#' @importFrom grDevices dev.off
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 geom_ribbon
#' @importFrom ggplot2 geom_line
#' @importFrom ggplot2 theme_bw
#' @importFrom ggplot2 xlab
#' @importFrom ggplot2 ylab
#' @importFrom ggplot2 ylim
#' @importFrom cowplot plot_grid
#'
#' @examples
#' library(mgcv)
#' library(ggplot2)
#' library(dplyr)
#' library(cowplot)
#' # 1. from the `mgcv` `gam` function help
#' set.seed(2) ## simulate some data...
#' dat <- gamSim(1,n=400,dist="normal",scale=2)
#' b <- gam(y~s(x0)+s(x1)+s(x2)+s(x3),data=dat)
#' plot_1d_smooth(b, ncol = 2, fills = c("lightblue", "lightblue3"))
#' dev.off()
#' # 2. using a TVC
#' data(productivity)
#' data = productivity |> mutate(Intercept = 1)
#' gam.tvc.mod = gam(privC ~ 0 + Intercept +
#'                   s(year, bs = 'gp', by = Intercept) +
#'                   unemp + s(year, bs = "gp", by = unemp) +
#'                   pubC + s(year, bs = "gp", by = pubC),
#'                   data = data)
#' plot_1d_smooth(gam.tvc.mod, fills = "lightblue")
#' @export
plot_1d_smooth = function(mod, ncol = NULL, nrow = NULL, fills = "lightblue") {
  pdf(file = NULL)        # dummy PDF
  smooths <- plot(mod, page = 1)  # call the plot
  dev.off()               # close the dummy plot
  # create the plots, rescaling to have same y-axis
  # objects for outputs and axis scaling
  scale = NULL
  for (i in 1:length(smooths)){
    y = smooths[[i]]$fit
    u = y + smooths[[i]]$se
    l = y - smooths[[i]]$se
    scale <- c(scale, c(min(u, l), max(u,l)))
  }
  fills = rep(fills, length(smooths))
  plot.list <- NULL
  for (i in 1:length(smooths)){
    x = smooths[[i]]$x
    y = smooths[[i]]$fit
    u = y + smooths[[i]]$se
    l = y - smooths[[i]]$se
    scale <- c(scale, c(min(u, l), max(u,l)))
    df = data.frame(x, y, u, l)
    plot.list[[i]] <-
      ggplot(df, aes(x, y, ymin = l, ymax = u)) +
      geom_ribbon(fill = fills[i]) +
      geom_line() +
      theme_bw() +
      xlab(smooths[[i]]$xlab) +
      ylab(smooths[[i]]$ylab) +
      ylim(min(scale), max(scale))
  }
  plot_grid_args <- c(plot.list[1:length(smooths)],
                      list(ncol = ncol),
                      list(nrow = nrow))
  do.call(plot_grid, plot_grid_args)
}
