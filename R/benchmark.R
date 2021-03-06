#' @title Benchmark experiment for multiple learners and tasks.
#'
#' @description
#' Complete benchmark experiment to compare different learning algorithms across one or more tasks
#' w.r.t. a given resampling strategy. Experiments are paired, meaning always the same
#' training / test sets are used for the different learners.
#' Furthermore, you can of course pass \dQuote{enhanced} learners via wrappers, e.g., a
#' learner can be automatically tuned using \code{\link{makeTuneWrapper}}.
#'
#' @param learners [(list of) \code{\link{Learner}}]\cr
#'   Learning algorithms which should be compared.
#' @param tasks [(list of) \code{\link{Task}}]\cr
#'   Tasks that learners should be run on.
#' @param resamplings [(list of) \code{\link{ResampleDesc}} | \code{\link{ResampleInstance}}]\cr
#'   Resampling strategy for each tasks.
#'   If only one is provided, it will be replicated to match the number of tasks.
#'   If missing, a 10-fold cross validation is used.
#' @param measures [(list of) \code{\link{Measure}}]\cr
#'   Performance measures for all tasks.
#'   If missing, the default measure of the first task is used.
#' @template arg_keep_pred
#' @template arg_extract
#' @template arg_showinfo
#' @return [\code{\link{BenchmarkResult}}].
#' @family benchmark
#' @export
benchmark = function(learners, tasks, resamplings, measures, keep.pred = TRUE, extract = NULL, show.info = getMlrOption("show.info")) {
  learners = ensureVector(learners, 1L, "Learner")
  assertList(learners, min.len = 1L)
  checkListElementClass(learners, "Learner")
  learner.ids = extractSubList(learners, "id")
  if (anyDuplicated(learner.ids))
    stop("Learners need unique ids!")
  names(learners) = learner.ids

  # check tasks
  tasks = ensureVector(tasks, 1L, "Task")
  assertList(tasks, min.len = 1L)
  checkListElementClass(tasks, "Task")
  task.ids = extractSubList(tasks, c("task.desc", "id"))
  if (anyDuplicated(task.ids))
    stop("Tasks need unique ids!")
  names(tasks) = task.ids

  # check resamplings
  if (missing(resamplings)) {
     resamplings = replicate(length(tasks), makeResampleDesc("CV", iters = 10L), simplify = FALSE)
  } else if (inherits(resamplings, "ResampleInstance") || inherits(resamplings, "ResampleDesc")) {
    resamplings = replicate(length(tasks), resamplings, simplify = FALSE)
  } else {
    assertList(resamplings)
    if (length(resamplings) != length(tasks))
      stop("Number of resampling strategies and number of tasks differ!")
  }
  resamplings = Map(function(res, tt) {
    if (inherits(res, "ResampleInstance"))
      return(res)
    if (inherits(res, "ResampleDesc"))
      return(makeResampleInstance(res, task = tt))
    stop("All objects in 'resamplings' must be of class 'ResampleDesc' or 'ResampleInstance'")
  }, resamplings, tasks)
  names(resamplings) = task.ids

  # check measures
  if (missing(measures)) {
    measures = list(getDefaultMeasure(tasks[[1L]]))
  } else {
    measures = ensureVector(measures, 1L, "Measure")
    assertList(measures)
    checkListElementClass(measures, "Measure")
  }

  inds = expand.grid(task = task.ids, learner = learner.ids, stringsAsFactors = FALSE)

  plevel = "mlr.benchmark"
  parallelLibrary("mlr", master = FALSE, level = plevel, show.info = FALSE)
  exportMlrOptions(level = "mlr.benchmark")
  results = parallelMap(
    benchmarkParallel,
    split(as.matrix(inds), f = seq_row(inds)),
    more.args = list(learners = learners, tasks = tasks, resamplings = resamplings,
      measures = measures, extract = extract, show.info = show.info),
    level = plevel
  )
  results.by.task = split(results, unlist(inds$task))
  for (taskname in names(results.by.task)) {
    names(results.by.task[[taskname]]) = inds$learner[inds$task == taskname]
  }
  addClasses(results.by.task, "BenchmarkResult")
  makeS3Obj("BenchmarkResult",
    results = results.by.task,
    measures = measures,
    learners = learners
  )
}

#' Result of a benchmark run.
#'
#' Container for results of benchmarked experiments using \code{\link{benchmark}}.
#' The structure of the object itself is rather complicated, it is recommended to
#' retrive required information via the \code{getBMR*} getter functions.
#' You can also convert the object using \code{\link[base]{as.data.frame}}.
#'
#' @name BenchmarkResult
#' @rdname BenchmarkResult
#' @family benchmark
NULL

benchmarkParallel = function(index, learners, tasks, resamplings, measures, keep.pred = TRUE, extract = NULL, show.info) {
  setSlaveOptions()
  ind.task = index[[1L]]
  ind.learner = index[[2L]]
  if (show.info)
    messagef("Task: %s, Learner: %s", ind.task, ind.learner)
  cl = class(learners[[ind.learner]])
  lrn = learners[[ind.learner]]
  r = resample(learners[[ind.learner]], tasks[[ind.task]], resamplings[[ind.task]],
    measures = measures, models = TRUE, extract = extract, keep.pred = keep.pred, show.info = show.info)
  # store used learner in result
  r$learner = lrn
  return(r)
}


#' @export
print.BenchmarkResult = function(x, ...) {
  print(getBMRAggrPerformances(x, as.df = TRUE))
}

#' @export
as.data.frame.BenchmarkResult = function(x, ...) {
  getBMRPerformances(x, as.df = TRUE)
}

