#' Bin and summarise in 2d (rectangle & hexagons)
#'
#' \code{stat_summary_2d} is a 2d variation of \code{\link{stat_summary}}.
#' \code{stat_summary_hex} is a hexagonal variation of
#' \code{\link{stat_summary_2d}}. The data are divided into bins defined
#' by \code{x} and \code{y}, and then the values of \code{z} in each cell is
#' are summarised with \code{fun}.
#'
#' @section Aesthetics:
#' \itemize{
#'  \item \code{x}: horizontal position
#'  \item \code{y}: vertical position
#'  \item \code{z}: value passed to the summary function
#' }
#'
#' @seealso \code{\link{stat_summary_hex}} for hexagonal summarization.
#'   \code{\link{stat_bin2d}} for the binning options.
#' @inheritParams stat_identity
#' @inheritParams stat_bin2d
#' @param drop drop if the output of \code{fun} is \code{NA}.
#' @param fun function for summary.
#' @param fun.args A list of extra arguments to pass to \code{fun}
#' @export
#' @examples
#' d <- ggplot(diamonds, aes(carat, depth, z = price))
#' d + stat_summary_2d()
#'
#' # Specifying function
#' d + stat_summary_2d(fun = function(x) sum(x^2))
#' d + stat_summary_2d(fun = var)
#' d + stat_summary_2d(fun = "quantile", fun.args = list(probs = 0.1))
#'
#' if (requireNamespace("hexbin")) {
#' d + stat_summary_hex()
#' }
stat_summary_2d <- function(mapping = NULL, data = NULL, geom = "rect",
                           position = "identity", bins = 30, drop = TRUE,
                           fun = "mean", fun.args = list(), show.legend = NA,
                           inherit.aes = TRUE, ...) {
  layer(
    data = data,
    mapping = mapping,
    stat = StatSummary2d,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    stat_params = list(
      bins = bins,
      drop = drop,
      fun = fun,
      fun.args = fun.args
    ),
    params = list(...)
  )
}

#' @export
#' @rdname stat_summary_2d
#' @usage NULL
stat_summary2d <- function(...) {
  message("Please use stat_summary_2d() instead")
  stat_summary_2d(...)
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
StatSummary2d <- ggproto("StatSummary2d", Stat,
  default_aes = aes(fill = ..value..),

  required_aes = c("x", "y", "z"),

  compute_group = function(data, scales, binwidth = NULL, bins = 30,
                           breaks = NULL, origin = NULL, drop = TRUE,
                           fun = "mean", fun.args = list(), ...) {
    data <- remove_missing(data, FALSE, c("x", "y", "z"),
      name = "stat_summary2d")

    range <- list(
      x = scale_dimension(scales$x, c(0, 0)),
      y = scale_dimension(scales$y, c(0, 0))
    )

    # Determine origin, if omitted
    if (is.null(origin)) {
      origin <- c(NA, NA)
    } else {
      stopifnot(is.numeric(origin))
      stopifnot(length(origin) == 2)
    }
    originf <- function(x) if (is.integer(x)) -0.5 else min(x)
    if (is.na(origin[1])) origin[1] <- originf(data$x)
    if (is.na(origin[2])) origin[2] <- originf(data$y)

    # Determine binwidth, if omitted
    if (is.null(binwidth)) {
      binwidth <- c(NA, NA)
      if (is.integer(data$x)) {
        binwidth[1] <- 1
      } else {
        binwidth[1] <- diff(range$x) / bins
      }
      if (is.integer(data$y)) {
        binwidth[2] <- 1
      } else {
        binwidth[2] <- diff(range$y) / bins
      }
    }
    stopifnot(is.numeric(binwidth))
    stopifnot(length(binwidth) == 2)

    # Determine breaks, if omitted
    if (is.null(breaks)) {
      breaks <- list(
        seq(origin[1], max(range$x) + binwidth[1], binwidth[1]),
        seq(origin[2], max(range$y) + binwidth[2], binwidth[2])
      )
    } else {
      stopifnot(is.list(breaks))
      stopifnot(length(breaks) == 2)
      stopifnot(all(sapply(breaks, is.numeric)))
    }
    names(breaks) <- c("x", "y")

    xbin <- cut(data$x, sort(breaks$x), include.lowest = TRUE)
    ybin <- cut(data$y, sort(breaks$y), include.lowest = TRUE)

    if (is.null(data$weight)) data$weight <- 1

    ans <- plyr::ddply(data.frame(data, xbin, ybin), c("xbin", "ybin"), function(d) {
      val <- do.call(fun, c(list(quote(d$z)), fun.args))
      data.frame(value = val)
    })
    if (drop) ans <- stats::na.omit(ans)

    ans$xint <- as.numeric(ans$xbin)
    ans$xmin <- breaks$x[ans$xint]
    ans$xmax <- breaks$x[ans$xint + 1]

    ans$yint <- as.numeric(ans$ybin)
    ans$ymin <- breaks$y[ans$yint]
    ans$ymax <- breaks$y[ans$yint + 1]
    ans
  }
)
