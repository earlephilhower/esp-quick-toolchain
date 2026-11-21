import argparse
import shutil
import os
import pathlib
import sys
import zipfile


class PythonNotSupported(Exception):
    pass


# manually construct zinfo object for pyc .zip for older python versions
# also ref. Makefile invocation and env SOURCE_DATE_EPOCH=...
if sys.version_info >= (3, 15):
    from zipfile import PyZipFile
elif sys.version_info >= (3, 14):

    class PyZipFile(zipfile.PyZipFile):
        def write(
            self, filename, arcname=None, compress_type=None, compresslevel=None
        ):  # ZipFile::write
            zinfo = zipfile.ZipInfo.from_file(
                filename, arcname, strict_timestamps=self._strict_timestamps
            )
            zinfo._for_archive(
                self
            )  # SOURCE_DATE_EPOCH timestamp plus filemode adjustments

            with open(filename, "rb") as f:
                self.writestr(zinfo, f.read(), compresslevel=compresslevel)

else:
    raise PythonNotSupported(sys.version_info)

# ref. emscripten/wasm_assets.py
# note that site data vars are already portable
PYZIPFILE_IGNORE_NAMES = (
    "lib-dynload",  # platform specific libraries
    "site-packages",  # standalone builds ship w/ pip
    "ensurepip",  # strip builtin getter as well
    "turtledemo",
)

PTH_TAIL = (
    "",
    "# Uncomment to run site.main() automatically",
    "#import site",
    "",
)

STDLIB_DIR = f"python{sys.version_info.major}.{sys.version_info.minor}"
STDLIB_ZIP = f"python{sys.version_info.major}{sys.version_info.minor}.zip"


def is_windows_dist(p: pathlib.Path) -> bool:
    return (p / "python.exe").exists() or (p / "Lib").exists()


class Windows:
    def __init__(self, root: pathlib.Path):
        self.root = root

    def __repr__(self):
        return f"Windows<{self.root}>"

    @property
    def bindir(self) -> pathlib.Path:  # Scripts/ unused in current distribution
        return self.root

    @property
    def entrypoint(self) -> pathlib.Path:
        return self.root / "python.exe"

    @property
    def bindir_entrypoint(
        self,
    ) -> pathlib.Path:  # backwards-compatible path missing from current distribution
        return self.root / "python3.exe"

    @property
    def stdlib_dir(self) -> pathlib.Path:
        return self.root / "Lib"

    @property
    def stdlib_zip(self) -> pathlib.Path:
        return self.root / STDLIB_ZIP

    # windows named either w/o version OR w/ dot-less version (same as .zip)
    @property
    def pth_file(self) -> pathlib.Path:
        return (
            self.root / f"python{sys.version_info.major}{sys.version_info.minor}._pth"
        )

    @property
    def pth_contents(self) -> str:
        out = []
        out.append(f"./{self.stdlib_zip.name}")
        out.append("./DLLs")
        out.append(".")
        out.extend(PTH_TAIL)
        return "\n".join(out)


class Generic:
    def __init__(self, root: pathlib.Path):
        self.root = root

    def __repr__(self):
        return f"Generic<{self.root}>"

    @property
    def entrypoint(self) -> pathlib.Path:
        return self.root / "python3"

    @property
    def bindir(self) -> pathlib.Path:
        return self.root / "bin"

    @property
    def bindir_entrypoint(self) -> pathlib.Path:
        return self.bindir / "python3"

    @property
    def libdir(self) -> pathlib.Path:
        return self.root / "lib"

    @property
    def stdlib_dir(self) -> pathlib.Path:
        return self.libdir / STDLIB_DIR

    @property
    def stdlib_zip(self) -> pathlib.Path:
        return self.libdir / STDLIB_ZIP

    # ref. getpath.py, and make sure its name matches python MAJOR DOT MINOR
    # "adjacent to the main DLL/dylib/so (if set) OR adjacent to the original executable"
    @property
    def pth_file(self) -> pathlib.Path:
        return (
            self.bindir
            / f"python{sys.version_info.major}.{sys.version_info.minor}._pth"
        )

    @property
    def pth_contents(self) -> str:
        out = []
        out.append(f"../lib/{self.stdlib_zip.name}")
        out.append(f"../lib/python{sys.version_info.major}.{sys.version_info.minor}")
        out.append(
            f"../lib/python{sys.version_info.major}.{sys.version_info.minor}/lib-dynload"
        )
        out.extend(PTH_TAIL)
        return "\n".join(out)


def remove_path(p: pathlib.Path):
    if p.is_dir(follow_symlinks=False):
        shutil.rmtree(p, ignore_errors=True)
    else:
        p.unlink(missing_ok=True)


def maybe_remove_empty(p: pathlib.Path):
    if len(list(p.iterdir())) == 0:
        print(f"Removing empty directory {p}")
        remove_path(p)


if __name__ == "__main__":
    parser = argparse.ArgumentParser("Repackaging standard library into .zip")
    parser.add_argument("--bootstrap", action="store_true")
    parser.add_argument("root", type=pathlib.Path)
    args = parser.parse_args()

    root: pathlib.Path = args.root.resolve()
    if not root.exists():
        raise ValueError(f"{root} does not exist")

    if not root.is_dir():
        raise ValueError(f"{root} not a dir")

    handler: Windows | Generic = (
        Windows(root) if is_windows_dist(root) else Generic(root)
    )
    print(f"Starting {handler}")

    stdlib_zip = handler.stdlib_zip
    if handler.stdlib_dir.exists():
        if stdlib_zip.exists():
            print(f"Remove existing {stdlib_zip}")
            stdlib_zip.unlink()

        ignore_paths = {
            (handler.stdlib_dir / name).resolve() for name in PYZIPFILE_IGNORE_NAMES
        }

        def filterfunc(s: str) -> bool:
            p = pathlib.Path(s).resolve()
            return p not in ignore_paths

        pending_removal: list[pathlib.Path] = [
            handler.stdlib_dir
            / "__pycache__",  # purge zipfile artifacts, in case stdlib_dir remains
        ]

        with PyZipFile(
            stdlib_zip, mode="w", compression=zipfile.ZIP_DEFLATED
        ) as zip_archive:
            zip_archive.compresslevel = 9
            for p in sorted(handler.stdlib_dir.iterdir()):
                p = p.resolve()

                # keep in the search path for Generic
                if p.name == "lib-dynload":
                    continue

                # .zip already contains .pyc, ignore existing ones / overwrites
                if p.name == "__pycache__":
                    pending_removal.append(p)
                    continue

                # process everything else and prune afterwards
                if p.is_dir() or p.suffix == ".py":
                    zip_archive.writepy(p, filterfunc=filterfunc)
                    pending_removal.append(p)

        print(f"Prepared {stdlib_zip}")

        for p in pending_removal:
            remove_path(p)

        maybe_remove_empty(handler.stdlib_dir)

    remove_path(root / "include")  # not intended for build environment

    for p in handler.bindir.glob(
        "pip*"
    ):  # modules are not to be modified after packaging
        remove_path(p)

    print(f"Site override {handler.pth_file}")
    handler.pth_file.write_text(handler.pth_contents)

    bindir_entrypoint: pathlib.Path | None = getattr(handler, "bindir_entrypoint", None)
    if bindir_entrypoint:
        print(f"Entrypoint {bindir_entrypoint}")
        if is_windows_dist(root):
            handler.entrypoint.copy(bindir_entrypoint)
        else:
            handler.entrypoint.symlink_to(bindir_entrypoint.relative_to(root))
