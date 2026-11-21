#!/usr/bin/env python3
# /// script
# dependencies = [
#   "PyYAML==6.*",
#   "ast-grep-py==0.45.*",
# ]
# requires-python = ">=3.8"
# ///

from typing import Tuple, List, Dict, Optional, Any, IO

import os
import warnings
import argparse
import concurrent.futures
import sys
import pathlib
import subprocess
import signal
import string
import re

# get string literals from the c++ source files
# ref.
# - https://neovim.io/doc/user/treesitter.html#%3AInspectTree
# - https://tree-sitter.github.io/tree-sitter/7-playground.html
# - https://ast-grep.github.io/playground.html
import ast_grep_py
from ast_grep_py import SgRoot

# ast-grep rules with nice syntax vs. nested dict()s
import yaml

# yaml rulesets for substitutions generation
DEFAULT_RULEDIR_PATH = pathlib.Path(__file__).parent / "ast-grep" / "rules"

# libstdc++-v3 is the main target of the script
DEFAULT_LIBSTDCXX_PATH = (
    pathlib.Path(__file__).parent / "repo" / "gcc-gnu" / "libstdc++-v3"
)

# utility header for local excstring declarations
DEFAULT_EXCSTRING_HEADER = (
    pathlib.Path(__file__).parent / "ast-grep" / "__eqt" / "excstring.hpp"
)

EXCSTRING_HEADER_RELPATH = pathlib.PosixPath("__eqt") / "excstring.hpp"
EXCSTRING_HEADER_INCLUDE = f"#include <{EXCSTRING_HEADER_RELPATH.as_posix()}>"

# where to look for the sources
DEFAULT_SEARCH = (
    DEFAULT_LIBSTDCXX_PATH / "include",
    DEFAULT_LIBSTDCXX_PATH / "libsupc++",
    DEFAULT_LIBSTDCXX_PATH / "src" / "c++11",
    DEFAULT_LIBSTDCXX_PATH / "src" / "c++17",
)


def excstring_header_install(
    libstdcxx_root: pathlib.Path, p: pathlib.Path
) -> pathlib.Path:
    return libstdcxx_root / "include" / p


# declarations placed at the earliest namespace entrypoint
NS_INSERT_ANCHORS = (
    # found in headers
    "namespace __gnu_cxx _GLIBCXX_VISIBILITY(default)",
    "namespace __gnu_pbds",
    "namespace std _GLIBCXX_VISIBILITY(default)",
    # found in libsupc++ .cc
    "namespace std",
    # libsupc++/bad_alloc.cc
    r"std::bad_alloc::~bad_alloc() _GLIBCXX_USE_NOEXCEPT { }",
    # libsupc++/eh_exception.cc
    r"std::exception::~exception() _GLIBCXX_TXN_SAFE_DYN _GLIBCXX_USE_NOEXCEPT { }",
)


# tree-sitter parsing workarounds, applied to the file before passing it to ast-grep
TS_WORKAROUND_REPLACEMENTS = (
    # misinterpreted as `function_definition`, breaking tree structure afterwards
    # causes `{ return "..."; }` to become initializer list & its list of entries
    ("_GLIBCXX_BEGIN_NAMESPACE_VERSION", "//LIBCXX_BEGIN_NAMESPACE_VERSION"),
    ("_GLIBCXX_END_NAMESPACE_VERSION", "//LIBCXX_END_NAMESPACE_VERSION"),
    # causes `{ return "..."; }` to be misattibuted to these as function identifiers
    ("_GLIBCXX_TXN_SAFE_DYN", "/* _GLIBCXX_TXN_SAFE_DYN */"),
    ("_GLIBCXX_USE_NOEXCEPT", "/* _GLIBCXX_USE_NOEXCEPT */"),
)


SRC_SUFFIXES = (
    # libstdc++ headers usually lack any suffix
    "",
    # implementation bits
    ".cc",
    ".h",
    ".hpp",
    # templated bits
    ".tcc",
    ".tpp",
)


def tree_sitter_before_parsing(text: str) -> str:
    for lhs, rhs in TS_WORKAROUND_REPLACEMENTS:
        text = text.replace(lhs, rhs)

    return text


def tree_sitter_after_edit(text: str) -> str:
    for lhs, rhs in TS_WORKAROUND_REPLACEMENTS:
        text = text.replace(rhs, lhs)

    return text


def is_ignored_suffix(p: pathlib.Path) -> bool:
    return not p.suffix in SRC_SUFFIXES


def format_decl(name: str, text: str) -> str:
    return f"__EQT_EXCSTR_DECL({name}, {text});"


class IgnoreSwap(Exception):
    pass


# for the sake of coherency, preserve __N(...) msgids
def maybe_swap_localizable_node(
    node: ast_grep_py.SgNode, text: str
) -> Tuple[ast_grep_py.SgNode, str]:
    try:
        parent = node.parent()
        if not parent or parent.kind() != "argument_list":
            raise IgnoreSwap()

        parent = parent.parent()
        if not parent or parent.kind() != "call_expression":
            raise IgnoreSwap()

        if parent.text().startswith("__N("):
            node = parent
            text = f"__N({text})"

    except IgnoreSwap:
        pass

    return (node, text)


# processes given string literal / concatenated string node and prepares the required file edits
class Worker:
    decls: List[str]
    edits: List[ast_grep_py.Edit]

    _known: Dict[str, Dict[str, str]]

    def __init__(self, tag: str):
        self.decls = []
        self.edits = []

        self._tag = tag
        self._known = {}

    def pending(self):
        return (len(self.edits) > 0) and (len(self.decls) > 0)

    def process(self, tag: str, node: ast_grep_py.SgNode):
        kind = node.kind()

        # result.text() includes \n and spacing
        if kind == "concatenated_string":
            text = ""
            for child in node.children():
                text += child.text().replace('"', "")
            text = f'"{text}"'

        # literal usable as-is
        elif kind == "string_literal":
            text = node.text()

        # do not duplicate var->text declarations
        if not tag in self._known:
            self._known[tag] = {}
        ref = self._known[tag]

        exists = ref.get(text)
        if exists:
            name = exists
        else:
            name = f"__eqt_excstr_{tag}_{self._tag}{len(ref)}"
            ref[text] = name

        node, text = maybe_swap_localizable_node(node, text)
        if not exists:
            self.decls.append(format_decl(name, text))

        self.edits.append(node.replace(name))


def worker(
    root: pathlib.Path, p: pathlib.Path, tagged_rules: Dict[str, ast_grep_py.Config]
):
    with p.open("r") as f:
        data = f.read()

    if EXCSTRING_HEADER_INCLUDE in data:
        return (p, None)

    file_tag = re.sub(r"\W+", "_", p.relative_to(root).as_posix())

    inst = Worker(file_tag)

    data = tree_sitter_before_parsing(data)
    sg_root = SgRoot(data, "c++")

    node = sg_root.root()
    for tag, rule in tagged_rules.items():
        for result in node.find_all(rule):
            inst.process(tag, result)

    def find_insert_anchor(data) -> Optional[str]:
        found = {}

        for m in NS_INSERT_ANCHORS:
            try:
                found[m] = (
                    data.index(m),
                    data.count(m),
                )
            except ValueError:
                pass

        items = found.items()
        if not items:
            return None

        indexed = sorted(items, key=lambda x: x[1][0])
        anchor, (index, count) = indexed[0]

        # XXX known headers, known to work
        if count > 2 and not p.name in ["basic_string.h"]:
            warnings.warn(f'{p} has more than one anchor "{anchor}"')

        return anchor

    def prepare_decls(decls: List[str], anchor: str) -> str:
        return "\n".join(
            [
                EXCSTRING_HEADER_INCLUDE,
                "",
                "namespace {",
                "",
                "\n".join(decls),
                "",
                "} // namespace",
                "",
                anchor,
            ]
        )

    if inst.pending():
        out = node.commit_edits(inst.edits)
        out = tree_sitter_after_edit(out)

        anchor = find_insert_anchor(out)
        if not anchor:
            raise ValueError(f"{p} found no suitable anchor")

        sub = prepare_decls(inst.decls, anchor)
        return (p, out.replace(anchor, sub, 1))


def os_walk(path_root: pathlib.Path):
    for path_str, dirnames, filenames in os.walk(path_root.as_posix()):
        if path_root == ".":
            path_str = path_str[2:]
        yield pathlib.Path(path_str), dirnames, filenames


def pathlib_walk(path_root: pathlib.Path):
    return path_root.walk()


def walk(path_root: pathlib.Path):
    if sys.version_info >= (3, 12):
        return pathlib_walk(path_root)

    return os_walk(path_root)


# usually we want everything in the directoy
# note that the path root is later used for name generation based on relative path
def find_files(path_root):
    for root, dir, files in walk(path_root):
        for file in files:
            p = root / file
            if is_ignored_suffix(p):
                continue

            yield p


# gets injected here, not through patches/
def write_or_replace(dst: pathlib.Path, src: pathlib.Path) -> bool:
    with src.open("r") as f:
        src_data = f.read()

    try:
        with dst.open("r") as f:
            data = f.read()

        if data == src_data:
            return False
    except:
        pass

    try:
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(src_data)
    except:
        pass

    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--libstdcxx-path",
        type=pathlib.Path,
        default=DEFAULT_LIBSTDCXX_PATH,
    )
    parser.add_argument(
        "--excstring-header",
        type=pathlib.Path,
        default=DEFAULT_EXCSTRING_HEADER,
    )
    parser.add_argument(
        "--rule-dir",
        type=pathlib.Path,
        default=DEFAULT_RULEDIR_PATH,
        help="ast-grep yaml rule directory",
    )

    parser.add_argument(
        "--diff-output",
        type=str,
        default="-",
        help="git-diff output",
    )

    parser.add_argument(
        "--log-output",
        type=str,
        default="-",
        help="logging output",
    )

    parser.add_argument("search", type=pathlib.Path, nargs="*", default=DEFAULT_SEARCH)
    args = parser.parse_args()

    x = pathlib.Path()
    x.name

    RE_W = re.compile(r"[^\w]")

    rules: Dict[str, ast_grep_py.Config] = {}
    for p in args.rule_dir.glob("**/*.yaml"):
        with p.open("r") as f:
            rule: ast_grep_py.Rule = yaml.load(f, Loader=yaml.CLoader)
        rules[RE_W.sub("_", p.stem)] = rule

    def maybe_stdout(s: str) -> IO:
        if s == "-":
            return sys.stdout

        return pathlib.Path(s).open("wt")

    args.log_output = maybe_stdout(args.log_output)

    def log_file(tag: str, p: pathlib.Path):
        print(f"{tag} {p}", file=args.log_output)

    args.diff_output = maybe_stdout(args.diff_output)

    excstring_target = args.libstdcxx_path / "include" / EXCSTRING_HEADER_RELPATH
    excstring_tag = (
        "+" if write_or_replace(excstring_target, args.excstring_header) else " "
    )
    log_file(excstring_tag, excstring_target)

    git_cmd_base = [
        "git",
        "-C",
        args.libstdcxx_path.as_posix(),
    ]

    def add_targets(targets: List[pathlib.Path], git_cmd_base=git_cmd_base):
        proc = subprocess.run([*git_cmd_base, "add", *(t.as_posix() for t in targets)])
        proc.check_returncode()

    def diff_output(stdout: IO, git_cmd_base=git_cmd_base):
        proc = subprocess.run([*git_cmd_base, "diff", "--cached"], stdout=stdout)
        if -proc.returncode != signal.SIGPIPE:
            proc.check_returncode()

    executor = concurrent.futures.ProcessPoolExecutor()
    with executor as e:
        futures = [
            e.submit(worker, root, p, rules)
            for root in args.search
            for p in find_files(root)
            if p != excstring_target
        ]

        targets = []

        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            if not result:
                continue

            p, data = result
            targets.append(p.relative_to(args.libstdcxx_path))
            tag = " "
            if data:
                tag = "+"
                with p.open("w") as f:
                    f.write(data)

            log_file(" ", p)

        if targets:
            targets.insert(0, excstring_target.relative_to(args.libstdcxx_path))

        add_targets(targets)
        diff_output(args.diff_output)
