#!/usr/bin/env python

import json
import queue as queue
import subprocess
import tarfile
from threading import Thread

import click
import pandas as pd
import torch


def create_file(input_file, output_file, logger_file, include_models):
    with open(input_file, "r") as fp:
        data = json.load(fp)
    for idx, value in enumerate(data):
        if value["id"] == "advi":
            advi_idx = idx
        elif value["id"] == "sampler":
            for idx2, v in enumerate(value["loggers"]):
                if "tree" in value["loggers"][idx2]["id"]:
                    del value["loggers"][idx2]
                else:
                    value["loggers"][idx2]["file_name"] = logger_file
                    # do not evaluate models to speed things up
                    if not include_models:
                        for m in (
                            "joint.jacobian",
                            "joint",
                            "like",
                            "prior",
                            "variational",
                            "coalescent",
                            "skygrid",
                            "skyglide",
                            "gmrf",
                        ):
                            if m in value["loggers"][idx2]["parameters"]:
                                value["loggers"][idx2]["parameters"].remove(m)

    del data[advi_idx]
    with open(output_file, "w") as fp:
        json.dump(data, fp, indent=2)


def parse_log(input_file):
    tensors = []
    with open(input_file, "r") as fp:
        for line in fp:
            line = line.strip()
            if not line.startswith("sample"):
                tensors.append(list(map(float, line.split("\t")[1:])))
    tensors = torch.tensor(tensors)
    means = ["{:.15f}".format(x) for x in torch.mean(tensors, dim=0).tolist()]
    variances = ["{:.15f}".format(x) for x in torch.var(tensors, dim=0).tolist()]
    return means, variances


class Worker(Thread):
    def __init__(
        self,
        original_json,
        work_dir,
        jsons,
        qq,
        idx,
        means,
        variances,
        include_models,
        tar_file=None,
    ):
        Thread.__init__(self)
        self.original_json = original_json
        self.work_dir = work_dir
        self.jsons = jsons
        self.queue = qq
        self.idx = idx
        self.means = means
        self.variances = variances
        self.tar_file = tar_file
        self.json_file = f"{self.work_dir}/temp-torchtree-{self.idx}.json"
        self.sample_file = f"{self.work_dir}/temp-samples-{self.idx}.csv"
        create_file(
            self.original_json,
            self.json_file,
            self.sample_file,
            include_models,
        )

    def run(self):
        while not self.queue.empty():
            index = self.queue.get()
            iteration = self.jsons[index].split(".json")[0].split("-")[-1]

            if self.tar_file:
                with tarfile.open(self.tar_file, "r:gz") as tar:
                    fp = tar.extractfile(tar.getmember(self.jsons[index]))
                    data = json.load(fp)
                    checkpoint_file = f"{self.work_dir}/temp-checkpoint-{self.idx}.json"
                    with open(checkpoint_file, "w") as fp:
                        json.dump(data, fp, indent=2)
            else:
                checkpoint_file = self.jsons[index]

            subprocess.run(["torchtree", "-c", checkpoint_file, self.json_file])

            means, variances = parse_log(self.sample_file)
            self.means[index] = [iteration] + means
            self.variances[index] = [iteration] + variances
            self.queue.task_done()


@click.command(
    help="Sample from variational distribution and calculate means and variances"
)
@click.option("--threads", default=2, show_default=True, help="number of threads")
@click.argument("src", nargs=-1)
@click.option(
    "--input",
    "input_",
    default="torchtree.json",
    show_default=True,
    help="original JSON file",
)
@click.option("--work-dir", default=".", show_default=True, help="work directory")
@click.option("--include-models", is_flag=True)
def sampling(threads, src, input_, work_dir, include_models):
    if ".tar.gz" in src[0]:
        with tarfile.open(src[0], "r:gz") as tar:
            jsons = [member.name for member in tar.getmembers()]
    else:
        jsons = src
        input

    jsons = sorted(
        jsons, key=lambda x: int(x.split(".json")[0].split("-")[-1]), reverse=False
    )
    # jsons = jsons[:4]

    means = [None] * len(jsons)
    variances = [None] * len(jsons)

    threads = min(threads, len(jsons))

    qq = queue.Queue()
    for j in range(len(jsons)):
        qq.put(j)

    for idx in range(threads):
        worker = Worker(
            input_,
            work_dir,
            jsons,
            qq,
            idx,
            means,
            variances,
            include_models,
            src[0] if ".tar.gz" in src[0] else None,
        )
        worker.daemon = True
        worker.start()

    qq.join()

    with open(f"{work_dir}/temp-samples-0.csv", "r") as fp:
        for line in fp:
            line = line.strip()
            if line.startswith("sample"):
                columns = line.split("\t")
                break

    df = pd.DataFrame(means, columns=columns)
    df.to_csv(f"{work_dir}/means.csv", index=False)
    df = pd.DataFrame(variances, columns=columns)
    df.to_csv(f"{work_dir}/variances.csv", index=False)


if __name__ == "__main__":
    sampling()
