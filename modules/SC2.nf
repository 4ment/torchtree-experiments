#!/usr/bin/env nextflow


results="${params.results_dir}/SC2"
input_vb = "$projectDir/data/SC2/torchtree/"
input_beast = "$projectDir/data/SC2/beast/"
alignment = file(params.sc2)


process RUN_TORCHTREE_SC2 {
  publishDir "${results}/torchtree/${model}/${sky}/${method}/${engine}", mode: 'copy'

  input:
    tuple path(torchtree_json), val(model), val(sky), val(engine), val(method)
  output:
    path("torchtree.json")
    path("checkpoints.tar.gz")
    path("samples.csv")
    path("samples.trees")
    path("torchtree.log")
    path("torchtree.txt")
  """
  SC2.py torchtree --file ${torchtree_json} --output torchtree.json --alignment ${alignment} --engine ${engine}
  { time \
    torchtree -s 1 torchtree.json  > torchtree.txt ; } 2> torchtree.log
  tar -czf checkpoints.tar.gz checkpoint-*
  """
}

process RUN_BEAST_SC2 {
  publishDir "${results}/beast/${model}/${sky}", mode: 'copy'

  input:
    tuple path(beast_xml), val(model), val(sky)
  output:
    path("*.log")
    path("*.trees")
    path("beast.xml")
    path("beast.txt")
  """
  SC2.py beast --file ${beast_xml} --output beast.xml --alignment ${alignment}
  { time \
    beast beast.xml  > beast.txt ; } 2> beast.log
  """
}

workflow SC2 {
  models = Channel.from("GTR", "HKY-RE")
  divergence = Channel.from("ELBO", "KLpq-10")
  coalescent = Channel.from("skyglide")
  engines = Channel.from("torchtree", "physher")

  ch_elbo = models.map{
    it ->
    [file("${input_vb}/ELBO/SC2_${it}.json"), it, "ELBO", "torchtree"]
  }
  ch_klpq = models.map{
    it ->
    [file("${input_vb}/KLpq-10/SC2_${it}.json"), it, "KLpq-10"]
  }.combine(engines)
  ch_vb = ch_elbo.mix(ch_klpq).combine(coalescent)

  RUN_TORCHTREE_SC2(ch_vb)

  ch_beast_skygrid = models.map{
    it ->
    [file("${input_beast}/SC2_${it}.xml"), it, "skygrid"]
  }
  ch_beast_skyglide = models.map{
    it ->
    [file("${input_beast}/SC2_${it}_skyglide.xml"), it, "skyglide"]
  }
  ch_beast = ch_beast_skygrid.mix(ch_beast_skyglide)
  RUN_BEAST_SC2(ch_beast_skyglide)
}