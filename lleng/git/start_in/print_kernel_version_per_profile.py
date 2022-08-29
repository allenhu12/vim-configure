#!/bin/python
# Extracts model lists and kernel per ruckus AP profile
# Usage: Run from buildroot directory

import os
import os.path
import sys

print "profile,", "kernel,", "model lists"
for dirpath, dirnames, filenames in os.walk("profiles"): #walk profiles/ directory
    for filename in [f for f in filenames if f.startswith("models_list.txt")]:
        filename = os.path.join(dirpath, filename)
        br2config = os.path.join(dirpath, "br2.config")
        fd=open(filename)

        profile=dirpath.lstrip('profiles/')
        if "-wsg" in profile:
                continue
        if "-ref" in profile:
                continue
        if "-vap" in profile:
                continue
		sys.stdout.write(profile) # print profile without a new line
        sys.stdout.write(", ")

        with open(br2config) as search:
            for line in search:
                line = line.rstrip()  # remove '\n' at end of line
                if line.startswith("BR2_DEFAULT_KERNEL_HEADERS="):
                    kernel=line.lstrip('BR2_DEFAULT_KERNEL_HEADERS=')
                    kernel=kernel.replace('"', '')
                    sys.stdout.write(kernel)
                    sys.stdout.write(", ")

        for line in fd:
                line = line.strip()
                if "#" not in line: # avoid printing comments
                        print(line)
        fd.close
