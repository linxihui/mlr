#' @title Generate data for a benchmark-summary plot.
#'
#' @description
#' A benchmark-summary plot allows comparison of performance of different
#' learners within a task.
#'
#' @template arg_bmr
#' @template arg_measure
#' @param fill [\code{character(0)}] \cr
#'   Bars are filled proportional to \dQuote{best} or \dQuote{worst} performing
#'   algorithm. \cr
#'   \dQuote{best} compares all performances to the best performance accross all
#'   classifiers. Bars are filled proportional to the best performance. \cr
#'   \dQuote{worst} compares all performances to the worst performance accross
#'   all classifiers. Bars are filled proportional to the worst performance. \cr
#' @template arg_order_lrns
#' @template arg_order_tsks
#' @return \code{BenchmarkSummaryData}. List containing:
#' \item{data}{[\code{data.frame}]}
#' \item{fill}{selected \code{fill} option}
#' \item{measure}{selected \code{measure}}
#'
#' @family generate_plot_data
#' @family benchmark
#' @export
generateBenchmarkSummaryData = function(bmr, measure = NULL, fill = "best", order.lrns = NULL, order.tsks = NULL) {
  assertClass(bmr, "BenchmarkResult")
  assertChoice(fill, c("worst", "best"))
  if (is.null(measure))
    measure = getBMRMeasures(bmr)[[1L]]
  assertClass(measure, "Measure")
  assertChoice(measure$id, getBMRMeasureIds(bmr))

  # avoid error in R CMD CHECK
  x = NULL

  # aggregate data over iterations
  aggrMeas = measureAggrName(measure)
  df = getBMRAggrPerformances(bmr, as.df = TRUE)
  df = df[, c("task.id", "learner.id", aggrMeas)]
  names(df)[names(df) == aggrMeas] = "x"

  if (!is.null(order.lrns))
    df = orderBMRLrns( bmr, df, order.lrns)
  if (!is.null(order.tsks))
    df = orderBMRTasks(bmr, df, order.tsks)

  row.names(df) = NULL
  if (fill == "worst") {
    if (!measure$minimize)
      df = ddply(df, c("task.id"), mutate, x = min(x) / x)
    else
      df = ddply(df, c("task.id"), mutate, x = x / max(x))
  } else {
    if (!measure$minimize)
      df = ddply(df, c("task.id"), mutate, x = x / max(x))
    else
      df = ddply(df, c("task.id"), mutate, x = min(x) / x)
  }
  # compute ranks
  df = ddply(df, c("task.id"), mutate, rk = rank(x, ties.method = "first"))
  df2 = df
  df2$x = 1 - df$x

  # rbind data.frames with different alphas
  df2$alpha = 0.4
  df$alpha  = 1
  df = rbind(df, df2)
  df = sortByCol(df, c("task.id", "learner.id"))

  makeS3Obj("BenchmarkSummaryData",
            "data" = df,
            "fill" = fill,
            "measure" = measure)
}
#' @title Plot a benchmark-summary.
#'
#' @description
#' Plots a BenchmarkSummaryPlot for a selected \link{Measure}.
#' Full tiles correspond
#' to the worst performance accross all \code{tasks}
#' and \code{learner}. The actuall fill
#' corresponds to the proportional performance of the \dQuote{best}
#' or \dQuote{worst} within the task. Sorting along the x-axis is done
#' accoriding to the algorithms rank.
#'
#' @param obj [\code{BenchmarkSummaryData}]\cr
#'   Output of a \link{generateBenchmarkSummaryData} function.
#' @template ret_gg2
#'
#' @references This plot is analogous to the one described in: \cr
#' Manuel J. A. Eugster, Torsten Hothorn and Friedrich Leisch;
#' Domain-Based Benchmark Experiments:Exploratory and Inferential Analysis,
#' AUSTRIAN JOURNAL OF STATISTICS Volume 41 (2012), Number 1
#' but does not include any clustering or sorting.
#'
#' @examples
#' lrns = list(makeLearner("classif.nnet"), makeLearner("classif.rpart"))
#' tasks = list(iris.task, sonar.task)
#' rdesc = makeResampleDesc("CV", iters = 2L)
#' meas = list(acc, mmce, ber, timeboth)
#' res = benchmark(lrns, tasks, rdesc, meas)
#' g = generateBenchmarkSummaryData(res, ber, fill = "best")
#' plotBenchmarkSummary(g)
#'
#' @family plot
#' @family benchmark
#' @export
plotBenchmarkSummary = function(obj) {
  assertClass(obj, "BenchmarkSummaryData")

  obj$data$rk = factor(obj$data$rk, levels = sort(unique(obj$data$rk), decreasing = TRUE))

  p = ggplot(obj$data, aes_string("task.id", "x", fill = "learner.id", alpha = "alpha"))
  p = p + geom_bar(stat = "identity")
  p = p + scale_alpha_identity()
  p = p + coord_flip()
  p = p + ylab(paste(obj$measure$name, "proportional to", obj$fill, "performance"))
  p = p + theme(axis.text.x = element_blank(),
                axis.ticks.x = element_blank(),
                axis.title.y = element_blank())
  return(p)
}
