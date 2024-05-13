#!/usr/bin/env python

import re

import click
import pandas as pd

pattern_elbo = re.compile(r"\s+(\d+)\s+(-\d+\.\d+).+")


def parse_iters_elbo(fp, start=0):
    iters = []
    elbos = []
    for line in fp:
        line = line.rstrip("\\n").rstrip("\\r")
        mt = pattern_elbo.match(line)
        if mt:
            iter_, elbo = mt.groups()
            iters.append(int(iter_))
            elbos.append(float(elbo))
    return iters[start:], elbos[start:]


@click.command(help="Generate json file with alignment file")
@click.option(
    "--log", "log_file", type=click.File("r"), required=True, help="torchtree.log"
)
@click.option(
    "--txt", "txt_file", type=click.File("r"), required=True, help="torchtree.txt"
)
@click.option("--dataset", required=True, help="dataset name")
@click.option("--model", required=True, help="subsitution model")
@click.option("--coalescent", required=True, help="coalescent model")
@click.option("--method", required=True, help="objective (e.g. ELBO, KLpq)")
@click.option(
    "--engine", required=True, help="torchtree engine (e.g. torchtree, physher)"
)
def parse(log_file, txt_file, dataset, model, coalescent, method, engine):
    iters, elbos = parse_iters_elbo(txt_file)

    elbos_dict = {"iters": iters, "elbos": elbos}
    pd.DataFrame(elbos_dict).to_csv("elbo.csv", index=False)

    info_dict = {
        "dataset": [dataset],
        "model": [model],
        "engine": [engine],
        "divergence": [method],
        "coalescent": [coalescent],
        "iters": iters[-1],
        "elbo": elbos[-1],
    }

    lines = log_file.readlines()
    info_dict["time"] = re.split(r"\s", lines[-3].replace("\n", ""))[-1].split("m")[0]

    info = pd.DataFrame(info_dict)
    info.to_csv("info.csv", index=False)


if __name__ == "__main__":
    parse()
