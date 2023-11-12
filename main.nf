#!/usr/bin/env nextflow

params.results_dir= "$projectDir/results"

include { HCV } from "./modules/HCV.nf"
include { SC2 } from "./modules/SC2.nf"

workflow {
  HCV()
  SC2()
}
