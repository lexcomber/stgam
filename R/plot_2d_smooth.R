#' Plots a 2-Dimensional GAM smooth
#'
#' @param mod a GAM model with smooths created using the `mgcv` package
#' @param filled `logical` value to indicate whether a filled plot should be created (`TRUE`) or not (`FALSE`)
#' @param outline the name of an `sf` object to be plotted (NULL is the default)
#' @param ncol the number of columns for the compound plot
#' @param nrow the number of rows for the compound plot
#'
#' @return A compound plot of the 2-dimensional smooths (rendered using `cowplot::plot_grid`).
#' @importFrom grDevices pdf
#' @importFrom grDevices dev.off
#' @importFrom ggplot2 geom_contour
#' @importFrom ggplot2 coord_sf
#' @importFrom ggplot2 geom_sf
#' @importFrom ggplot2 geom_contour_filled
#'
#' @examples
#' library(mgcv)
#' library(ggplot2)
#' library(dplyr)
#' library(metR)
#' library(cowplot)
#' set.seed(2) ## simulate some data...
#' dat <- gamSim(1,n=400,dist="normal",scale=2)
#' # use x1 and x2 as the coordinates
#' b <- gam(y~s(x0, x1, bs = 'gp', by = x2),data=dat)
#' plot_2d_smooth(b, filled = TRUE)
#' @export
plot_2d_smooth = function(mod, filled = FALSE, outline =  NULL, ncol = NULL, nrow = NULL) {
  Var1 = NULL
  Var2 = NULL
  pdf(file = NULL)        # dummy PDF
  smooths <- plot(mod, page = 1)  # call the plot
  dev.off()               # close the dummy plot
  # create the plots, rescaling to have same y-axis
  # objects for outputs and axis scaling
  for (i in 1:length(smooths)){
    y = smooths[[i]]$fit
    u = y + smooths[[i]]$se
    l = y - smooths[[i]]$se
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
