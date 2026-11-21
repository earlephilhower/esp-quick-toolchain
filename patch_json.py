#!/usr/bin/env python3

import argparse
import textwrap
import collections
import glob
import json
import os
import pathlib

parser = argparse.ArgumentParser(
    description="Patch in a section of the Arduino tools JSON"
)
parser.add_argument(
    "--pkgfile", help="Arduino JSON file to update", type=pathlib.Path, required=True
)
parser.add_argument("--tool", help="Name of tool to update", type=str, required=True)
parser.add_argument(
    "--version", help="Version of tool to update", type=str, required=True
)
parser.add_argument(
    "--glob",
    help="Glob to match for tool .json fragment",
    type=str,
    action="append",
    required=True,
)
args = parser.parse_args()

# Load the JSON and overwrite first found platform tool plus all dependencies referencing this tool
pkgfile: pathlib.Path = args.pkgfile
with pkgfile.open("r") as f:
    data = json.load(f, object_pairs_hook=collections.OrderedDict)

for dep in data["packages"][0]["platforms"][0]["toolsDependencies"]:
    if dep["name"] == args.tool:
        dep["version"] = args.version

# TODO: spec is vague on duplicate 'host' per version, expect arduino-cli picking
#       the last 'compatible' fragment that matches current host architecture
fragments = {}

for tool in data["packages"][0]["tools"]:
    if tool["name"] == args.tool:
        print(f"Patching tool from {tool['version']} to {args.version}")
        tool["version"] = args.version
        tool["systems"] = []
        for g in args.glob:
            for p in sorted(glob.glob(g)):
                with open(p, "r") as f:
                    fragment = json.load(f, object_pairs_hook=collections.OrderedDict)
                    host = fragment["host"]
                    if host in fragments:
                        raise ValueError(
                            f"Duplicate fragments for {host}!\n"
                            f" {p}\n"
                            f" {fragments[host]}\n"
                        )
                    else:
                        fragments[host] = p
                    print(f"Found {host}")
                    tool["systems"].append(fragment)

if fragments:
    print(f'Updating "{args.tool}" in {pkgfile}')
    with pkgfile.open("w") as f:
        f.write(json.dumps(data, indent=3, separators=(",", ": ")))
else:
    print(f'No tools matching "{args.tool}" found in {pkgfile}')
