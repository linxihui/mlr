# evaluates either a hyperpar setting or a feature set by resampling
# must be already in correct format, either a named list of values or a named integer vector for features
# logs point and results
# return y-value(s), exectime, and potential erorr msg
evalOptimizationState = function(learner, task, resampling, measures, par.set, bits.to.features, control,
  opt.path, show.info, dob, state, remove.nas) {

  setSlaveOptions()
  y = setNames(rep(NA_real_, length(measures)), vcapply(measures, measureAggrName))
  errmsg = NA_character_
  exec.time = NA_real_
  set.pars.ok = TRUE
  learner2 = learner
  threshold = NULL
  log.fun = control$log.fun

  if (inherits(control, "TuneControl") || inherits(control, "TuneMultiCritControl")) {
    if (inherits(control, "TuneControlMBO") && control$mbo.control$multifid) {
      #transform multifid lvl to param setting
      multifid.param = control$mbo.control$multifid.param #string
      multifid.values = control$mbo.control$multifid.lvls #factor over discrete values
      state[[multifid.param]] = multifid.values[state$.multifid.lvl]
      state = dropNamed(state, ".multifid.lvl")
      par.set = c(par.set, makeParamSet(
        makeDiscreteParam(multifid.param, values = multifid.values)))
    }
    # set names before trafo
    state = setValueCNames(par.set, state)
    # transform parameters
    state = trafoValue(par.set, state)
    # remove NAs for dependencies
    state2 = if (remove.nas) removeMissingValues(state) else state
    learner2 = try(setHyperPars(learner, par.vals = state2), silent = TRUE)
    # if somebody above (eg tuner) prodcued bad settings, we catch this here and dont eval
    if (is.error(learner2)) {
      set.pars.ok = FALSE
      errmsg = as.character(learner2)
      if (show.info)
        messagef("[Tune-x] Setting hyperpars failed: %s", errmsg)
    }
  } else if (inherits(control, "FeatSelControl")) {
    task = subsetTask(task, features = bits.to.features(state, task))
  }

  # if no problems: resample + measure time
  if (show.info)
    prev.stage = log.fun(learner, task, resampling, measures, par.set, control, opt.path, dob,
      state, NA_real_, remove.nas, stage = 1L)
  if (set.pars.ok) {
    exec.time = system.time({
      r = resample(learner2, task, resampling, measures = measures, show.info = FALSE)
    })

    if (control$tune.threshold) {
      th.args = control$tune.threshold.args
      th.args$pred = r$pred
      th.args$measure = measures[[1L]]
      tune.th.res = do.call(tuneThreshold, th.args)
      threshold = tune.th.res$th
      # we need to eval 1 final time here, as tuneThreshold only works with 1 measure,
      # but we need yvec for all measures
      y = performance(setThreshold(r$pred, threshold = threshold), measures = measures)
      # names from resample are slightly different, set them correctly here
      names(y) = names(r$aggr)
    } else {
      y = r$aggr
    }
    # sort msgs by iters, so iter1, iter2, ...
    errmsgs = as.character(t(r$err.msgs[, -1L]))
    notna = !is.na(errmsgs)
    if (any(notna))
      errmsg = errmsgs[notna][1L]
    exec.time = exec.time[3L]
  } else {
    # we still need to define a non-NULL threshold, if tuning it was requested
    if (control$tune.threshold)
      threshold = NA_real_
  }
  # if eval was not ok, everything should have been initailized to NAs

  if (show.info)
    log.fun(learner, task, resampling, measures, par.set, control, opt.path, dob, state, y,
      remove.nas, stage = 2L, prev.stage = prev.stage)
  list(y = y, exec.time = exec.time, errmsg = errmsg, threshold = threshold)
}

# evaluates a list of states by calling evalOptimizationState
# must be already in correct format, either a named list of values or a named integer vector for features
# might be done in parallel
# logs point and results
# adds points to path
# returns list of lists, the single eval results
evalOptimizationStates = function(learner, task, resampling, measures, par.set, bits.to.features, control,
  opt.path, show.info, states, dobs, eols, remove.nas, level) {

  n = length(states)
  if (length(dobs) == 1L)
    dobs = rep(dobs, n)
  if (length(eols) == 1L)
    eols = rep(eols, n)
  parallelLibrary("mlr", master = FALSE, level = level, show.info = FALSE)
  exportMlrOptions(level = level)
  res.list = parallelMap(evalOptimizationState, dobs, states, level = level,
    more.args = list(learner = learner, task = task, resampling = resampling,
      measures = measures, par.set = par.set, bits.to.features = bits.to.features,
      control = control, opt.path = opt.path, show.info = show.info, remove.nas = remove.nas))
  # add stuff to opt.path
  for (i in seq_len(n)) {
    res = res.list[[i]]
    if (control$tune.threshold) {
      # add class names to threshold, if longer than 1
      extra = as.list(res$threshold)
      names(extra) = paste0("threshold", ifelse(length(extra) > 1L, ".", ""), names(extra))
    } else {
      extra = NULL
    }
    addOptPathEl(opt.path, x = as.list(states[[i]]), y = res$y, exec.time = res$exec.time,
      error.message = res$errmsg, dob = dobs[i], eol = eols[i], check.feasible = FALSE,
      extra = extra)
  }
  return(res.list)
}

evalOptimizationStatesTune = function(learner, task, resampling, measures, par.set, control,
  opt.path, show.info, states, dobs, eols, remove.nas) {

  evalOptimizationStates(learner, task, resampling, measures, par.set, NULL, control,
    opt.path, show.info, states, dobs, eols, remove.nas, "mlr.tuneParams")
}

evalOptimizationStatesFeatSel = function(learner, task, resampling, measures, bits.to.features, control,
  opt.path, show.info, states, dobs, eols) {

  evalOptimizationStates(learner, task, resampling, measures, NULL, bits.to.features, control,
    opt.path, show.info, states, dobs, eols, FALSE, "mlr.selectFeatures")
}
