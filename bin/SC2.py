#!/usr/bin/env python
import json
import xml.etree.ElementTree as ET

import click


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
def torchtree(file, output, alignment):
    sequences = read_fasta(alignment)
    data = json.load(file)
    for sequence in data[1]["sequences"]:
        sequence["sequence"] = sequences[sequence["taxon"]]
    json.dump(data, output, indent=2)


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
