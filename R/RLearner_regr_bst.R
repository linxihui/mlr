#' @export
makeRLearner.regr.bst = function() {
  makeRLearnerRegr(
    cl = "regr.bst",
    package = "bst",
    par.set = makeParamSet(
      makeNumericLearnerParam(id = "cost", default = 0.5, lower = 0, upper = 1),
      makeIntegerLearnerParam(id = "mstop", default = 50L, lower = 1L, when = "both"),
      makeNumericLearnerParam(id = "nu", default = 0.1),
      makeLogicalLearnerParam(id = "twinboost", default = FALSE),
      makeUntypedLearnerParam(id = "f.init", default = NULL),
      makeUntypedLearnerParam(id = "xselect.init", default = NULL),
      makeLogicalLearnerParam(id = "center", default = FALSE),
      makeLogicalLearnerParam(id = "trace", default = FALSE, tunable = FALSE),
      makeIntegerLearnerParam(id = "numsample", default = 50L, lower = 1L),
      makeIntegerLearnerParam(id = "df", default = 4L, lower = 1L),
      makeIntegerLearnerParam(id = "minsplit", default = 20L, lower = 1L),
      makeIntegerLearnerParam(id = "minbucket", lower = 1L),
      makeNumericLearnerParam(id = "cp", default = 0.01, lower = 0, upper = 1),
      makeIntegerLearnerParam(id = "maxcompete", default = 4L, lower = 0L),
      makeIntegerLearnerParam(id = "maxsurrogate", default = 5L, lower = 0L),
      makeDiscreteLearnerParam(id = "usesurrogate", default = 2L, values = 0:2),
      makeIntegerLearnerParam(id = "xval", default = 10L, lower = 0L),
      makeDiscreteLearnerParam(id = "surrogatestyle", default = 0L, values = 0:1),
      makeIntegerLearnerParam(id = "maxdepth", default = 1L, lower = 1L, upper = 30L),
      makeDiscreteLearnerParam(id = "Learner", default = "ls", values = c("ls", "sm", "tree"))
    ),
    par.vals = list(maxdepth = 1L, Learner = "ls"),
    properties = c("numerics"),
    name = "Gradient Boosting",
    short.name = "bst",
    note = "The argument `learner` has been renamed to `Learner` due to a name conflict with `setHyerPars`"
  )
}

#' @export
trainLearner.regr.bst = function(.learner, .task, .subset, .weights = NULL, mstop, nu, twinboost,
  f.init, xselect.init, center, trace, numsample, df, minsplit, minbucket, cp, maxsurrogate,
  usesurrogate, surrogatestyle, maxdepth, xval, Learner, ...) {
  d = getTaskData(.task, .subset, target.extra = TRUE)
  ctrl = learnerArgsToControl(bst::bst_control, mstop, nu, twinboost, f.init,
    xselect.init, center, trace, numsample, df)
  control.tree = learnerArgsToControl(list,  minsplit, minbucket, cp, maxsurrogate,
    usesurrogate, surrogatestyle, maxdepth, xval)
  bst::bst(x = d$data, y = d$target, family = "gaussian", ctrl = ctrl,
    control.tree = control.tree, learner = Learner, ...)
}

#' @export
predictLearner.regr.bst = function(.learner, .model, .newdata, ...) {
  predict(.model$learner.model, .newdata, ...)
}
