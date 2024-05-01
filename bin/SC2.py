#!/usr/bin/env python
import json
import xml.etree.ElementTree as ET

import click

# Template was generated using torchtree-cli:
# torchtree-cli advi -i sc2.fa -t sc2.tree --clock strict --coalescent skyglide \
# --scipy_gamma_site -C 4 --cutoff 0.3 --grid 5  --heights_init tree -m SYM \
# --frequencies 0.2988387179135696,0.18371883310279738,0.1958960436176954,0.32154640536593765 \
# --rate 0.0008 --date_regex "(\d+)-(\d+)-(\d+)$" --date_format "yyyy-MM-dd" \
# --coalescent_init constant --tol_rel_obj 0 --iter 1000000 \
# --checkpoint_all

def read_fasta(alignment):
    sequence = None
    name = None
    sequences = {}
    for line in alignment:
        line = line.strip()
        if line.startswith(">"):
            if sequence is not None:
                sequences[name] = sequence
            name = line[1:]
            sequence = ""
        else:
            sequence += line
    sequences[name] = sequence
    return sequences


@click.command(help="Generate json file with alignment file")
@click.option("--file", type=click.File("r"), required=True, help="input json file")
@click.option("--output", type=click.File("w"), required=True, help="output json file")
@click.option("--alignment", type=click.File("r"), required=True, help="fasta file")
@click.option(
    "--engine",
    type=click.Choice(["torchtree", "physher"]),
    default="torchtree",
    help="engine",
)
def torchtree(file, output, alignment, engine):
    sequences = read_fasta(alignment)
    data = json.load(file)
    for sequence in data[1]["sequences"]:
        sequence["sequence"] = sequences[sequence["taxon"]]

    if engine == "physher":
        like = findInDictByID(data, "like")
        like["type"] = "torchtree_physher." + like["type"]
        like["tree_model"]["type"] = "torchtree_physher." + like["tree_model"]["type"]
        like["branch_model"]["type"] = (
            "torchtree_physher." + like["branch_model"]["type"]
        )
        like["site_model"]["type"] = (
            "torchtree_physher." + like["site_model"]["type"].split(".")[-1]
        )
        like["substitution_model"]["type"] = (
            "torchtree_physher." + like["substitution_model"]["type"]
        )
        # GTR does specify data_type
        if "data_type" in like["substitution_model"]:
            like["substitution_model"]["data_type"]["type"] = (
                "torchtree_physher." + like["substitution_model"]["data_type"]["type"]
            )

        coalescent = findInDictByID(data, "coalescent")
        coalescent["type"] = "torchtree_physher." + coalescent["type"]

    json.dump(data, output, indent=2)


def findInDictByID(obj, id_, res=None):
    if res is not None:
        return res
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, (dict, list)):
                res = findInDictByID(v, id_, res)
            elif k == "id" and v == id_:
                res = obj
    elif isinstance(obj, list):
        for item in obj:
            res = findInDictByID(item, id_, res)
    return res


@click.command(help="Generate XML file with alignment file")
@click.option("--file", type=click.File("r"), required=True, help="input XML file")
@click.option("--output", type=click.UNPROCESSED, required=True, help="output XML file")
@click.option("--alignment", type=click.File("r"), required=True, help="fasta file")
def beast(file, output, alignment):
    sequences = read_fasta(alignment)
    tree = ET.parse(file)
    alignment_ele = tree.getroot().find("alignment")
    for sequence in alignment_ele.findall("sequence"):
        taxon = sequence.find("taxon")
        taxon_id = taxon.get("idref")
        taxon.tail = sequences[taxon_id]

    tree.write(output)


@click.group(help="CLI tool to create JSON and XML files")
def cli():
    pass


cli.add_command(beast)
cli.add_command(torchtree)

if __name__ == "__main__":
    cli()
