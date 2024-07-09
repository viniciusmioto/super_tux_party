#!/usr/bin/env python3
import re
import os
import sys
import glob
import shlex
import shutil
import subprocess
from tqdm import tqdm

DIR_MARKDOWN = "## "
FILE_MARKDOWN = "### "

BLACKLIST = []

LICENSE_FILE = [
    "licenses/LICENSE-ART.md",
    "licenses/LICENSE-MUSIC.md",
    "licenses/LICENSE-SHADER.md",
    "licenses/LICENSE-FONTS.md",
]
FILE_EXTENSIONS = [
    "*.png",
    "*.jpg",
    "*.jpeg",
    "*.escn",
    "*.dae",
    "*.obj",
    "*.hdr",
    "*.ttf",
    "*.blend",
    "*.wav",
    "*.mp3",
    "*.ogg",
    "*.shader",
    "*.otf",
    "*.glb",
    "*.svg",
]


def make_expand_shell_filter(shellpath):
    def expand_shell_filter(x):
        i_shellpath = 0
        for i_x in range(len(x)):
            if i_shellpath == len(shellpath):
                return False

            if (
                shellpath[i_shellpath] == "\\"
                and i_shellpath + 1 < len(shellpath)
                and shellpath[i_shellpath + 1] == "*"
            ):
                i_shellpath += 1

            if shellpath[i_shellpath] == "*":
                if (
                    i_shellpath + 1 < len(shellpath)
                    and shellpath[i_shellpath + 1] == x[i_x]
                ):
                    i_shellpath += 2
            else:
                if shellpath[i_shellpath] != x[i_x]:
                    return False
                i_shellpath += 1

        if i_shellpath < len(shellpath) and shellpath[i_shellpath] == "*":
            i_shellpath += 1
        return i_shellpath == len(shellpath)

    return expand_shell_filter


files = set()
for extension in FILE_EXTENSIONS:
    files |= set(glob.glob("**/%s" % extension, recursive=True))
num_files = len(files)

print("Checking %d files" % num_files)
LICENSE_FILESIZE = sum([os.stat(x).st_size for x in LICENSE_FILE])

with tqdm(total=LICENSE_FILESIZE, unit="B") as pbar:
    for x in LICENSE_FILE:
        with open(x, "r") as f:
            current_dir = ""
            for line in f:
                if line.startswith(DIR_MARKDOWN):
                    current_dir = line[len(DIR_MARKDOWN) :].strip()
                    expand_shell_filter = make_expand_shell_filter(current_dir)
                    files = [s for s in files if not expand_shell_filter(s)]
                elif line.startswith(FILE_MARKDOWN):
                    current_files = map(
                        str.strip, line[len(FILE_MARKDOWN) :].split("|")
                    )

                    for name in current_files:
                        expand_shell_filter = make_expand_shell_filter(
                            os.path.normpath(("%s/%s" % (current_dir, name)))
                        )
                        files = [s for s in files if not expand_shell_filter(s)]
                pbar.update(len(line))

blacklist_regex = re.compile("|".join(BLACKLIST))
print("\x1B[32mLicense found for %d files\x1B[0m" % (num_files - len(files)))
for f in files:
    if not (BLACKLIST and p.match(f)):
        print("\x1B[31mNo license found for: %s\x1B[0m" % f)

# Return an exit code of 0, if there are no missing licenses
sys.exit(len(files) > 0)
