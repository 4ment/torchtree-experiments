# torchtree-experiments

[![Docker Image CI](https://github.com/4ment/torchtree-experiments/actions/workflows/docker-image.yml/badge.svg)](https://github.com/4ment/torchtree-experiments/actions/workflows/docker-image.yml)

This repository contains the pipeline and data supporting the results of the following article:

Mathieu Fourment, Matthew Macaulay, Christiaan J Swanepoel, Xiang Ji, Marc A Suchard, Frederick A Matsen IV. torchtree: flexible phylogenetic model development and inference using PyTorch. [arXiv:2406.18044](https://arxiv.org/abs/2406.18044)

## Data

### SARS-CoV-2
We reproduce the SARS-CoV-2 analysis perfomed by [Magee _et al._, 2023](https://arxiv.org/abs/2303.13642). Detailed information on installing the appropriate versions of BEAST and BEAGLE is available on their GitHub [repository](https://github.com/suchard-group/approximate_substitution_gradient_supplement).
Due to data sharing limitations, sequences need to be downloaded from GISAID and the alignment (FASTA format) needs to be provided to the pipeline. The GISAID accession IDs are available in [acknowledgements_table.xlsx](https://github.com/suchard-group/approximate_substitution_gradient_supplement/blob/main/acknowledgements_table.xlsx).

## Dependencies
To execute this pipeline, it is necessary to install [nextflow](https://www.nextflow.io). [Docker](https://www.docker.com) is not required but it is highly recommended to use it due to the numerous dependencies.

## Installation

    git clone 4ment/torchtree-experiments.git
    cd torchtree-experiments/
    chmod +x bin/*.py

## Pipeline without docker/singularity

### Installing dependencies with conda
    conda env create -f environment.yml
    conda activate torchtree-experiments
    
    RUN wget https://github.com/4ment/physher/archive/refs/tags/v2.0.1.tar.gz
    tar -xzvf v2.0.1.tar.gz
    cmake -S physher-2.0.1 -B physher-2.0.1/build -DBUILD_CPP_WRAPPER=on -DBUILD_TESTING=on -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX/envs/torchtree-experiments
    cmake --build physher-2.0.1/build/ --target install
    export LIBRARY_PATH=$LIBRARY_PATH:$CONDA_PREFIX/envs/torchtree-experiments/lib

    pip install torch==1.12.1 numpy==1.22 torchtree==1.0.2
    pip install torchtree-physher==1.0.0 torchtree-scipy==1.0.0

### Running the pipeline

    nextflow run main.nf -profile conda --sc2 sc2.fa

`sc2.fa` is the sequence alignment file containing the SARS-CoV-2 sequences (see [SARS-CoV-2](#sars-cov-2) section for more details)

## Pipeline with docker or singularity
There is no need to install dependencies with docker or singularity.

### Running the pipeline with docker

    nextflow run main.nf -profile docker --sc2 sc2.fa

### Running the pipeline with singularity and PBS

    nextflow -C configs/uts.config run main.nf -profile singularity --sc2 sc2.fa

Since the pipeline will take weeks to run to completion one should use a high performance computer. An example of configuration file for PBS Pro can be found in the [configs](configs/) folder.

## Summarizing results

All R packages used for plotting the results can be installed using renv. This command needs to be run only once.

    Rscript -e 'renv::restore()'

Generate figures in a single pdf:

    Rscript -e 'rmarkdown::render("index.Rmd")'

Note:

rmarkdown requires pandoc to be installed. The conda environment provided in this repo includes pandoc.
It is also possible to use RStudio to run the `index.Rmd` script.


## Program and library versions

For reproducibility, we provide below the version of each library/program used in the benchmark.

| Program/Library | Version |
| --------------- | ------- |
| [physher]           | 2.0.1 |
| [torchtree]         | 1.0.2 |
| [torchtree-physher] | 1.0.0 |
| [torchtree-scipy]   | 1.0.0 |
| [pytorch]           | 1.12.1 |


The R scripts use the [skyplotr] package, and it is downloadable using [devtools](https://github.com/hadley/devtools):

    Rscript -e 'devtools::install_github("4ment/skyplotr", ref="8abc10a")'


[physher]: https://github.com/4ment/physher
[torchtree]: https://github.com/4ment/torchtree
[torchtree-physher]: https://github.com/4ment/torchtree-physher
[torchtree-scipy]: https://github.com/4ment/torchtree-scipy
[skyplotr]: https://github.com/4ment/skyplotr

[PyTorch]: https://pytorch.org