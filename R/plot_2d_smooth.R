#' Plots a 1-Dimensional GAM smooth
#'
#' @param mod a GAM model with smooths created using the mgcv package
#' @param ncol the number of columns for the compound plot
#' @param nrow the number of rows for the compound plot
#' @param fills the fill colours (single or vector)
#'
#' @return a compound plot of the 1D smooths (rendered using cowplot::plot_grid )
#' @export
#'
#' @examples
#' library(mgcv)
#' library(tidyverse)
#' library(cowplot)
#' set.seed(2) ## simulate some data...
#' dat <- gamSim(1,n=400,dist="normal",scale=2)
#' b <- gam(y~s(x0, x1, bs = 'gp', by = x2),data=dat)
#' b <- gam(y~s(x0)+s(x1)+s(x2)+s(x3),data=dat)
#' plot_2d_smooth(b, filled = T)

plot_2d_smooth = function(mod = b, filled = F, outline =  NULL, ncol = NULL, nrow = NULL) {
  pdf(file = NULL)        # dummy PDF
  smooths <- plot(mod, page = 1)  # call the plot
  dev.off()               # close the dummy plot
  # create the plots, rescaling to have same y-axis
  # objects for outputs and axis scaling
  scale = NULL
  for (i in 1:length(smooths)){
    scale <- c(scale, c(min(u, l), max(u,l)))
  }
  plot.list <- NULL
  for (i in 1:length(smooths)){
    x = smooths[[i]]$x
    y = smooths[[i]]$y
    fit = smooths[[i]]$fit
    u = fit + smooths[[i]]$se
    l = fit - smooths[[i]]$se
    m <- expand.grid( x , y)
    m <- cbind(m, fit, u, l)
    if(!filled) {
      if(is.null(outline)) {
        plot.list[[i]] <-
          ggplot(data = m, aes(x = Var1, y = Var2, z = fit)) +
          geom_contour(col = "black") +
          metR::geom_text_contour(aes(z = fit)) +
          geom_contour(aes(z = u), lty = 2, col = "red") +
          geom_contour(aes(z = l), lty = 3, col = "darkgreen") +
          coord_sf() +
          theme_bw() + xlab(smooths[[i]]$xlab) + ylab(smooths[[i]]$ylab)
      } else {
        plot.list[[i]] <-
          ggplot(data = m) +
          geom_contour(aes(x = Var1, y = Var2, z = fit), col = "black") +
          metR::geom_text_contour(aes(x = Var1, y = Var2, z = fit)) +
          geom_contour(aes(x = Var1, y = Var2, z = u), lty = 2, col = "red") +
          geom_contour(aes(x = Var1, y = Var2, z = l), lty = 3, col = "darkgreen") +
          coord_sf() +
          theme_bw() + xlab("") + ylab("") +
          geom_sf(data = outline, fill = NA)
      }
    }
    if(filled) {
      if(is.null(outline)) {
        plot.list[[i]] <-
          ggplot(data = m, aes(x = Var1, y = Var2, z = fit)) +
          geom_contour_filled(na.rm = T, bins = 5) +
          coord_sf() +
          theme_bw() + xlab(smooths[[i]]$xlab) + ylab(smooths[[i]]$ylab)
      } else {
        plot.list[[i]] <-
          ggplot() +
          geom_contour_filled(data = m, aes(x = Var1, y = Var2, z = fit), bins = 5, na.rm = T) +
          coord_sf() +
          theme_bw() + xlab("") + ylab("") +
          geom_sf(data = outline, fill = NA)
      }
    }
  }
  plot_grid_args <- c(plot.list[1:length(smooths)],
                      list(ncol = ncol),
                      list(nrow = nrow))
  do.call(plot_grid, plot_grid_args)
}