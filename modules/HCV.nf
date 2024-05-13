#!/usr/bin/env nextflow

include { TORCHTREE_SAMPLING; TORCHTREE_PARSE } from './common.nf'

results="${params.results_dir}/HCV"
input_seq="$projectDir/data/HCV/HCV.fasta"
input_tree="$projectDir/data/HCV/HCV.tree"


def create_arguments(model, coalescent, divergence, engine){
  def args = " -i ${input_seq} -t ${input_tree}"
  args += " -m ${model} -C 4"
  args += " --use_tip_states"
  args += " --clock strict --dates 0 --rate 0.00079"
  args += " --heights_init tree"
  args += " --coalescent_init constant"
  args += " --coalescent ${coalescent} --grid 75 --cutoff 400"

  if(engine == "torchtree")
    args += " --scipy_gamma_site"
  else if(engine == "physher")
    args = args + " --physher_site gamma"

  if (engine == "physher" | engine == "bito")
    args += " --${engine}"
  
  if (engine == "physher" & coalescent == "skyglide"){
    args += " --physher_disable_coalescent"
  }
  
  if(divergence.contains("-")){
    def (div, K) = divergence.tokenize('-')
    args += " --divergence ${div}"
    if(div == "KLpq"){
      args += " --grad_samples ${K}"
    }
    else{
      args += " --K_grad_samples ${K}"
    }
  }
  else if(divergence != ""){
    args += " --divergence ${divergence}"
  }

  return args
}

process RUN_TORCHTREE_HCV {
  publishDir "${results}/torchtree/${model}/${coalescent}/${divergence}/${engine}/", mode: 'copy'

  input:
    tuple val(model), val(coalescent), val(divergence), val(engine)
  output:
    tuple val(model), val(coalescent), val(divergence), val(engine)
    tuple path("torchtree.json"), path("checkpoints.tar.gz")
    tuple path("torchtree.log"), path("torchtree.txt")
    path("samples.csv")
    path("samples.trees")
  script:
    args = create_arguments(model, coalescent, divergence, engine)

  """
  torchtree-cli advi --iter 10000000 \
                     --lr 0.1 \
                     --tol_rel_obj 0.00001 \
                     --checkpoint_all \
                     ${args} \
  					 > torchtree.json
  { time \
    torchtree -s 1 torchtree.json  > torchtree.txt ; } 2> torchtree.log
  tar -czf checkpoints.tar.gz checkpoint-* 
  """
}

process RUN_TORCHTREE_HMC {
  publishDir "${results}/torchtree/${model}/${coalescent}/hmc/${engine}/", mode: 'copy'
  errorStrategy 'ignore'

  input:
    tuple val(model), val(coalescent), val(engine)
  output:
    path("torchtree.json")
    path("checkpoint.json")
    path("samples.csv")
    path("samples.trees")
    path("torchtree.log")
    path("torchtree.txt")
  script:
    args = create_arguments(model, coalescent, "", engine)

  """
  torchtree-cli hmc --iter 10000000 \
                     --stem samples \
                     --join tree.ratios.unres,tree.root_height.unres \
                     --steps 5 --step_size 0.01 \
                     --adapt_step_size adaptive \
                     --adapt_mass_matrix \
                     ${args} \
  					 > torchtree.json
  { time \
    torchtree -s 1 torchtree.json  > torchtree.txt ; } 2> torchtree.log
  """
}

process RUN_TORCHTREE_MCMC {
  publishDir "${results}/torchtree/${model}/${coalescent}/mcmc/${engine}/", mode: 'copy'

  input:
    tuple val(model), val(coalescent), val(engine)
  output:
    path("torchtree.json")
    path("checkpoint.json")
    path("samples.csv")
    path("samples.trees")
    path("torchtree.log")
    path("torchtree.txt")
  script:
    args = create_arguments(model, coalescent, "", engine)

  """
  torchtree-cli mcmc  --iter 10000000 \
                     --stem samples \
                     ${args} \
  					 > torchtree.json
  { time \
    torchtree -s 1 torchtree.json  > torchtree.txt ; } 2> torchtree.log
  """
}

process RUN_BEAST_HCV {
  publishDir "${results}/beast/${coalescent}/", mode: 'copy'

  input:
    val(coalescent)
  output:
    path("*.log")
    path("*.trees")
    path("*.ops")
    path("beast.txt")
  """
  { time \
    beast ${projectDir}/data/HCV/beast/HCV_${coalescent}.xml  > beast.txt ; } 2> beast.log
  """
}

workflow HCV {
  models = Channel.from("GTR")
  coalescent = Channel.from("skygrid", "skyglide")
  divergence = Channel.from("ELBO", "KLpq-10")
  engines = Channel.from("physher")

  ch_vb = models.combine(coalescent).combine(divergence).combine(engines)
  RUN_TORCHTREE_HCV(ch_vb)

  TORCHTREE_SAMPLING(Channel.value("HCV"), RUN_TORCHTREE_HCV.out[0], RUN_TORCHTREE_HCV.out[1])

  TORCHTREE_PARSE(Channel.value("HCV"), RUN_TORCHTREE_HCV.out[0], RUN_TORCHTREE_HCV.out[2])

  ch_hmc = models.combine(coalescent).combine(engines)
  RUN_TORCHTREE_HMC(ch_hmc)

  ch_mcmc = ch_hmc.filter{it[1] != "skyglide"}
  RUN_TORCHTREE_MCMC(ch_mcmc)

  coalescent | RUN_BEAST_HCV
}