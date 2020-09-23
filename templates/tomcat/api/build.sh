#!/bin/bash

src_dir="$(pwd)/../../war_project"

# do replace latest with a proper docker4gis/maven tag
"$BASE" maven latest "$src_dir"
