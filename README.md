# torchtree-experiments

[![Docker Image CI](https://github.com/4ment/torchtree-experiments/actions/workflows/docker-image.yml/badge.svg)](https://github.com/4ment/torchtree-experiments/actions/workflows/docker-image.yml)

This repository contains the pipeline and data supporting the results of the following article:

Fourment M _et al._ ... coming soon...

## Data

### SARS-CoV-2
We reproduce the SARS-CoV-2 analysis perfomed by [Magee _et al._, 2023](https://arxiv.org/abs/2303.13642). Detailed information on installing the appropriate versions of BEAST and BEAGLE is available on their GitHub [repository](https://github.com/suchard-group/approximate_substitution_gradient_supplement).
Due to data sharing limitations, sequences need to be downloaded from GISAID and the alignment (FASTA format) needs to be provided to the pipeline. The GISAID accession IDs are available in [acknowledgements_table.xlsx](https://github.com/suchard-group/approximate_substitution_gradient_supplement/blob/main/acknowledgements_table.xlsx).

## Dependencies
To execute this pipeline, it is necessary to install [nextflow](https://www.nextflow.io). [Docker](https://www.docker.com) is not required but it is highly recommended to use it due to the numerous dependencies.

## Installation

    git clone 4ment/torchtree-experiments.git

## Running the pipeline with docker

    nextflow run main.nf -profile docker --sc2 sc2.fa

`sc2.fa` is the sequence alignment file containing the SARS-CoV-2 sequences (see [SARS-CoV-2](#sars-cov-2) section for more details)

Since the pipeline will take weeks to run to completion one should use a high performance computer. An examples of configuration file for PBS Pro can be found in the [configs](configs/) folder.

## Summarizing results

Generate figures in a single pdf:

    Rscript -e 'rmarkdown::render("plot.Rmd")'

## Program and library versions

For reproducbility, we provide below the version of each library/program used in the benchmark.

| Program/Library | Version |
| --------------- | ------- |
| [physher]           | 1.0.3 |
| [torchtree]         | 1.0.1 |
| [torchtree-physher] | 1.0.1 |
| [pytorch]           | 1.12.1 |


[physher]: https://github.com/4ment/physher
[torchtree]: https://github.com/4ment/torchtree
[torchtree-physher]: https://github.com/4ment/torchtree-physher

[PyTorch]: https://pytorch.org