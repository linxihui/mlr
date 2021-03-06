#' @export
makeRLearner.regr.gbm = function() {
  makeRLearnerRegr(
    cl = "regr.gbm",
    package = "gbm",
    par.set = makeParamSet(
      makeDiscreteLearnerParam(id = "distribution", default = "gaussian", values = c("gaussian", "laplace", "poisson")),
      makeIntegerLearnerParam(id = "n.trees", default = 100L, lower = 1L),
      makeIntegerLearnerParam(id = "cv.folds", default = 0L),
      makeIntegerLearnerParam(id = "interaction.depth", default = 1L, lower = 1L),
      makeIntegerLearnerParam(id = "n.minobsinnode", default = 10L, lower = 1L),
      makeNumericLearnerParam(id = "shrinkage", default = 0.001, lower = 0),
      makeNumericLearnerParam(id = "bag.fraction", default = 0.5, lower = 0, upper = 1),
      makeNumericLearnerParam(id = "train.fraction", default = 1, lower = 0, upper = 1),
      makeLogicalLearnerParam(id = "keep.data", default = TRUE, tunable = FALSE),
      makeLogicalLearnerParam(id = "verbose", default = FALSE, tunable = FALSE)
    ),
    par.vals = list(distribution = "gaussian"),
    properties = c("missings", "numerics", "factors", "weights"),
    name = "Gradient Boosting Machine",
    short.name = "gbm",
    note = "`distribution` has been set to *gaussian* by default."
  )
}

#' @export
trainLearner.regr.gbm = function(.learner, .task, .subset, .weights = NULL,  ...) {
  f = getTaskFormula(.task)
  if (is.null(.weights)) {
    f = getTaskFormula(.task)
    gbm::gbm(f, data = getTaskData(.task, .subset), keep.data = FALSE, ...)
  } else  {
    f = getTaskFormula(.task)
    gbm::gbm(f, data = getTaskData(.task, .subset), keep.data = FALSE, weights = .weights, ...)
  }
}

#' @export
predictLearner.regr.gbm = function(.learner, .model, .newdata, ...) {
  m = .model$learner.model
  gbm::predict.gbm(m, newdata = .newdata, n.trees = length(m$trees), ...)
}
