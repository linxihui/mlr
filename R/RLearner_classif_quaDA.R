#' @export
makeRLearner.classif.quaDA = function() {
  makeRLearnerClassif(
    cl = "classif.quaDA",
    package = "DiscriMiner",
    par.set = makeParamSet(
      #makeNumericVectorLearnerParam(id = "prior", lower = 0, upper = 1, default = NULL),
      makeDiscreteLearnerParam(id = "validation", values = c("crossval", "learntest"))
      ),
    properties = c("twoclass", "multiclass", "numerics"),
    name = "Quadratic Discriminant Analysis",
    short.name = "quada",
    note = ""
  )
}

#' @export
trainLearner.classif.quaDA = function(.learner, .task, .subset, .weights = NULL,  ...) {
  d = getTaskData(.task, .subset, target.extra = TRUE, recode.target = "drop.levels")
  DiscriMiner::quaDA(variables = d$data, group = d$target, ...)
}

#' @export
predictLearner.classif.quaDA = function(.learner, .model, .newdata, ...) {
  m = .model$learner.model
  p = DiscriMiner::classify(m, newdata = .newdata)
  #p$scores #we loose this information
  p$pred_class
}
