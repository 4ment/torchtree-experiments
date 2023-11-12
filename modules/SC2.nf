#!/usr/bin/env nextflow


results="${params.results_dir}/SC2"
input_elbo = "$projectDir/data/SC2/torchtree/ELBO/"
input_beast = "$projectDir/data/SC2/beast/"
alignment = file(params.sc2)


process RUN_TORCHTREE_SC2 {
  publishDir "${results}/torchtree/${model}/${method}", mode: 'copy'

  input:
    tuple path(torchtree_json), val(model), val(method)
  output:
    path("torchtree.json")
    path("checkpoint*")
    path("samples.csv")
    path("samples.trees")
    path("torchtree.log")
    path("torchtree.txt")
  """
  SC2.py torchtree --file ${torchtree_json} --output torchtree.json --alignment ${alignment}
  { time \
    torchtree -s 1 torchtree.json  > torchtree.txt ; } 2> torchtree.log
  """
}

process RUN_BEAST_SC2 {
  publishDir "${results}/torchtree/${model}/", mode: 'copy'

  input:
    tuple path(beast_xml), val(model)
  output:
    path("*.log")
    path("*.trees")
    path("beast.xml")
  """
  SC2.py beast --file ${beast_xml} --output beast.xml --alignment ${alignment}
  { time \
    beast beast.xml  > beast.txt ; } 2> beast.log
  """
}

workflow {
  models = Channel.from("GTR", "HKY-RE")
  ch_vb = models.map{
    it ->
    [file("${input_elbo}/SC2_${it}.json"), it, "ELBO"]
  }
  RUN_TORCHTREE_SC2(ch_vb)

  ch_beast = models.map{
    it ->
    [file("${input_beast}/SC2_${it}.xml"), it]
  }
  RUN_BEAST_SC2(ch_beast)
}