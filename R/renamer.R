df.rename = data.frame(
  from=c('rep', 'like', 'var',
         'tree.root_height.0', 'tree.heights.61', 'treeMode.rootHeight',
         'substmodel.frequencies.0','substmodel.frequencies.1', 'substmodel.frequencies.2', 'substmodel.frequencies.3',
         'substmodel.rates.0', 'substmodel.rates.1', 'substmodel.rates.2', 'substmodel.rates.3', 'substmodel.rates.4', 'substmodel.rates.5',
         'substmodel.kappa.0',
         'sitemodel.shape.0',
         # it changes the first param in skygrid
         #'coalescent.theta.0','coalescent.theta2.0',
         'coalescent.growth.0',
         'gmrf.precision.0'),
  to=c('rep', 'likelihood', 'variational',
       'rootHeight', 'rootHeight', 'treeModel.rootHeight',
       'freqA', 'freqC', 'freqG', 'freqT',
       'AC', 'AG', 'AT', 'CG', 'CT','GT',
       'kappa',
       'shape',
       #'popSize', 'popSize',
       'growthRate',
       'precision'))

df.rename.beast = data.frame(
  from=c('treeModel.rootHeight',
         'frequencies1', 'frequencies2', 'frequencies3', 'frequencies4',
         'gtr.rates.rateAC', 'gtr.rates.rateAG', 'gtr.rates.rateAT', 'gtr.rates.rateCG', 'gtr.rates.rateCT','gtr.rates.rateGT',
         'gammaShape', 'alpha',
         'constant.popSize', 'exponential.popSize',
         'exponential.growthRate',
         'skygrid.precision','skyride.precision',
         'skyGlideLikelihood', 'skygrid',
         'posterior'),
  to=c('rootHeight',
       'freqA', 'freqC', 'freqG', 'freqT',
       'AC', 'AG', 'AT', 'CG', 'CT','GT',
       'shape','shape',
       'popSize', 'popSize',
       'growthRate',
       'precision', 'precision',
       'coalescent', 'coalescent',
       'joint'))

myrename <- function(df, df.rename) {
  m = match(colnames(df), df.rename$from)
  colnames(df)[!is.na(m)] = df.rename$to[m[!is.na(m)]]
  if ("coalescent.theta.0" %in% colnames(df) &
      !("coalescent.theta.1" %in% colnames(df))) {
    df = rename(df, popSize = coalescent.theta.0)
  }
  df
}
