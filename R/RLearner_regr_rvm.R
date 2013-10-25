#' @S3method makeRLearner regr.rvm
makeRLearner.regr.rvm = function() {
  makeRLearnerRegr(
    cl = "regr.rvm",
    package = "kernlab",
    # to do: stringdot pars and check order, scale and offset limits
    par.set = makeParamSet(
      makeDiscreteLearnerParam(id="kernel", default="rbfdot",
        values=c("vanilladot", "polydot", "rbfdot", "tanhdot", "laplacedot", "besseldot", "anovadot", "splinedot", "stringdot")),
      makeNumericLearnerParam(id="tau", lower=0, default=0.01),
      makeNumericLearnerParam(id="sigma",
        lower=0, requires=expression(kernel %in% c("rbfdot", "anovadot", "besseldot", "laplacedot"))),
      makeIntegerLearnerParam(id="degree", default=3L, lower=1L,
        requires=expression(kernel %in% c("polydot", "anovadot", "besseldot"))),
      makeNumericLearnerParam(id="scale", default=1, lower=0,
        requires=expression(kernel %in% c("polydot", "tanhdot"))),
      makeNumericLearnerParam(id="offset", default=1,
        requires=expression(kernel %in% c("polydot", "tanhdot"))),
      makeNumericLearnerParam(id="order", default=1L,
        requires=expression(kernel == "besseldot")),
      makeNumericLearnerParam(id="alpha", default=5L, lower=0L),
      makeNumericLearnerParam(id="var", default=0.1, lower=0),
      makeLogicalLearnerParam(id="var.fix", default=FALSE),
      makeNumericLearnerParam(id="iterations", default=100L, lower=0L),
      makeNumericLearnerParam(id="tol", default=.Machine$double.eps, lower=0),
      makeNumericLearnerParam(id="minmaxdiff", default=0.001, lower=0),
      makeLogicalLearnerParam(id="fit", default=TRUE)
    ),
    par.vals = list(fit=FALSE),
    missings = FALSE,
    numerics = TRUE,
    factors = TRUE,
    se = FALSE,
    weights = FALSE
  )
}

#' @S3method trainLearner regr.rvm
trainLearner.regr.rvm = function(.learner, .task, .subset, .weights, degree, offset, scale, sigma, order, length, lambda, normalized, ...) {
  kpar = learnerArgsToControl(list, degree, offset, scale, sigma, order, length, lambda, normalized)
  f = getTaskFormula(.task)
  if (base::length(kpar))
    rvm(f, data=getTaskData(.task, .subset), kpar=kpar, ...)
  else
    rvm(f, data=getTaskData(.task, .subset), ...)
}

#' @S3method predictLearner regr.rvm
predictLearner.regr.rvm = function(.learner, .model, .newdata, ...) {
  kernlab::predict(.model$learner.model, newdata=.newdata, ...)[,1]
}