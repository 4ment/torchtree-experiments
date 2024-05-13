
process TORCHTREE_SAMPLING {
  publishDir "${params.results_dir}/${dataset}/torchtree/${model}/${coalescent}/${divergence}/${engine}/", mode: 'copy'

  input:
    val(dataset)
    tuple val(model), val(coalescent), val(divergence), val(engine)
    tuple path(torchtree_json), path(checkpoints)
  output:
    path("means.csv")
    path("variances.csv")
  """
  sampling.py --input ${torchtree_json} ${checkpoints}
  """
}

process TORCHTREE_PARSE {
  label 'ultrafast'

  publishDir "${params.results_dir}/${dataset}/torchtree/${model}/${coalescent}/${divergence}/${engine}/", mode: 'copy'

  input:
    val(dataset)
    tuple val(model), val(coalescent), val(divergence), val(engine)
    tuple path(torchtree_log), path(torchtree_txt)
  output:
    path("info.csv")
    path("elbo.csv")
  """
  time-parser.py --log ${torchtree_log} --txt ${torchtree_txt} --dataset ${dataset} --model ${model} --coalescent ${coalescent} --method ${divergence} --engine ${engine}
  """
}