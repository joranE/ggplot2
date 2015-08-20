#' Convert angle and radius to xend and yend.
#'
#' @section Aesthetics:
#' \Sexpr[results=rd,stage=build]{ggplot2:::rd_aesthetics("stat", "spoke")}
#'
#' @inheritParams stat_identity
#' @section Computed variables:
#' \describe{
#'   \item{xend}{x position of end of line segment}
#'   \item{yend}{x position of end of line segment}
#' }
#' @export
#' @examples
#' df <- expand.grid(x = 1:10, y=1:10)
#' df$angle <- runif(100, 0, 2*pi)
#' df$speed <- runif(100, 0, 0.5)
#'
#' ggplot(df, aes(x, y)) +
#'   geom_point() +
#'   stat_spoke(aes(angle = angle), radius = 0.5)
#'
#' last_plot() + scale_y_reverse()
#'
#' ggplot(df, aes(x, y)) +
#'   geom_point() +
#'   stat_spoke(aes(angle = angle, radius = speed))
stat_spoke <- function(mapping = NULL, data = NULL, geom = "segment",
                       position = "identity", show.legend = NA,
                       inherit.aes = TRUE, ...) {
  layer(
    data = data,
    mapping = mapping,
    stat = StatSpoke,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(...)
  )
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
StatSpoke <- ggproto("StatSpoke", Stat,
  retransform = FALSE,

  compute_panel = function(data, panel_info, radius = 1, ...) {
    transform(data,
      xend = x + cos(angle) * radius,
      yend = y + sin(angle) * radius
    )
  },

  default_aes = aes(xend = ..xend.., yend = ..yend..),

  required_aes = c("x", "y", "angle", "radius")
)
